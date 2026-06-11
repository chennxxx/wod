import Foundation
import Observation
import SwiftUI
import UIKit

@Observable
final class RecordFlowViewModel {
    enum EntryMode {
        case photoOCR
        case manual
    }

    enum RecordStep: Hashable {
        case checkinPhotos
        case ocrResult
        case scoreInput
        case cardEditor
        case cardPreview
        case saveSuccess
    }

    enum OCRState: Equatable {
        case idle
        case processing
        case timeout
        case success(OCRResult)
        case failure(String)
    }

    var step: RecordStep = .ocrResult
    var selectedWhiteboardImage: UIImage?
    var selectedCheckinImages: [UIImage] = []
    var wodContentText = ""
    var wodDate: Date = .now
    var difficultyLevel: DifficultyLevel = .moderate
    var completionMinutes: Int? = nil
    var note = ""
    // 成绩录入：类型 + 随类型变样的输入 + RX/SC 标记
    var scoreType: WODType = .forTime
    var scoreMinutes = ""           // For Time：分
    var scoreSeconds = ""           // For Time：秒
    var amrapReps = ""              // AMRAP：总完成次数
    var emomRounds = ""             // EMOM：轮次
    var emomRepsDelta = ""          // EMOM：加/减 reps 数量
    var emomSign = true             // EMOM：true=加，false=减
    var maxLoadText = ""            // Max Load：重量
    var maxLoadIsKg = true          // Max Load：true=kg，false=lb
    var scoreScaling: ScoreScaling? = .rx
    var selectedStyleId = "style_mono_overlay"
    var textLayout = TextLayout()
    /// 卡片上已开启的内容模块（CardModule.rawValue）。固定顺序由 CardModule.allCases 决定。
    var enabledModules: [String] = CardModule.defaultEnabledRawValues
    // 进入即停留在内容表单（manual 默认），点击「自动识别」才进入 OCR loading
    var ocrState: OCRState = .success(OCRResult(wodContent: [], confidence: 1))
    var previewRecord = WODRecord()
    var renderedCardImage: UIImage?
    var isRendering = false
    var entryMode: EntryMode = .manual

    private let ocrService: OCRServicing
    private var hasUserAdjustedFontSize = false
    private var networkRetryCount = 0
    private let maxNetworkRetries = 3
    private var ocrTask: Task<Void, Never>?
    private let ocrTimeoutSeconds: Double = 10

    init(ocrService: OCRServicing = PreviewOCRService()) {
        self.ocrService = ocrService
    }

    /// 在「记录 WOD」页内自动识别 WOD 内容：弹出 loading，完成后仅回填内容，
    /// 保留已填的日期 / 成绩 / 强度 / 备注等结构化字段。
    func recognizeWODContent(from image: UIImage) {
        entryMode = .photoOCR
        selectedWhiteboardImage = image
        networkRetryCount = 0
        wodContentText = ""          // 清空上次识别残留内容
        ocrState = .processing
        step = .ocrResult
        performOCR(image: image)
    }

    /// 内置默认训练打卡照资源名（横屏 + 竖屏各一张，未选照片时随机轮换）。
    static let defaultCheckinAssetNames = ["DefaultCheckinPhoto", "DefaultCheckinPhotoPortrait"]

    /// 全部可用的内置默认照（缺失的资源自动跳过，至少返回已存在的那张）。
    static func defaultCheckinImages() -> [UIImage] {
        defaultCheckinAssetNames.compactMap { UIImage(named: $0) }
    }

    /// 随机取一张内置默认照（用户未选照片时用）。
    static func randomDefaultCheckinImage() -> UIImage? {
        defaultCheckinImages().randomElement()
    }

    /// 取消正在进行的识别，回到内容表单（保留已输入内容）。
    func cancelRecognition() {
        ocrTask?.cancel()
        ocrTask = nil
        ocrState = .success(OCRResult(wodContent: wodLines, confidence: 1))
    }

    /// 按当前类型组装格式化成绩串；信息不足时返回 nil
    var formattedScore: String? {
        func clean(_ s: String) -> String? {
            let t = s.trimmingCharacters(in: .whitespaces)
            return t.isEmpty ? nil : t
        }
        switch scoreType {
        case .forTime, .other:
            let m = clean(scoreMinutes)
            let s = clean(scoreSeconds)
            guard m != nil || s != nil else { return nil }
            let mm = String(format: "%02d", max(0, Int(m ?? "0") ?? 0))
            let ss = String(format: "%02d", max(0, Int(s ?? "0") ?? 0))
            return "\(mm):\(ss)"
        case .amrap:
            guard let reps = clean(amrapReps) else { return nil }
            return "\(reps) reps"
        case .emom:
            guard let rounds = clean(emomRounds) else { return nil }
            if let delta = clean(emomRepsDelta) {
                return "\(rounds) 轮 \(emomSign ? "+" : "-")\(delta) reps"
            }
            return "\(rounds) 轮"
        case .maxLoad:
            guard let load = clean(maxLoadText) else { return nil }
            return "\(load) \(maxLoadIsKg ? "kg" : "lb")"
        }
    }

    private func performOCR(image: UIImage) {
        ocrTask?.cancel()

        let task = Task {
            // 超时竞争：ocrTimeoutSeconds 秒后取消请求
            let timeoutTask = Task {
                try? await Task.sleep(for: .seconds(ocrTimeoutSeconds))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    // 只有在仍处于 processing 时才触发超时
                    if case .processing = ocrState {
                        ocrState = .timeout
                    }
                }
            }

            do {
                let result = try await ocrService.recognize(image: image)
                timeoutTask.cancel()
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    ocrState = .success(result)
                    wodContentText = result.wodContent.joined(separator: "\n")
                }
            } catch {
                timeoutTask.cancel()
                guard !Task.isCancelled else { return }
                let isNetworkError = error is URLError || (error as NSError).domain == NSURLErrorDomain
                await MainActor.run {
                    if isNetworkError && networkRetryCount < maxNetworkRetries {
                        networkRetryCount += 1
                        Task {
                            try? await Task.sleep(for: .seconds(3))
                            performOCR(image: image)
                        }
                    } else {
                        ocrState = .failure(localizedOCRError(error, isNetworkError: isNetworkError))
                    }
                }
            }
        }
        ocrTask = task
    }

    func goToOCRReview() {
        step = .ocrResult
    }

    func goToCheckinPhotos() {
        step = .checkinPhotos
    }

    func goToScoreInput() {
        step = .scoreInput
    }

    func goToCardEditor() {
        step = .cardEditor
    }

    func goToCardPreview() {
        applySuggestedFontSizeIfNeeded()
        step = .cardPreview
    }

    func goToSaveSuccess() {
        step = .saveSuccess
    }

    func goBack() {
        switch step {
        case .ocrResult:
            // 内容页是第一步，返回由界面层 dismiss 处理；此处无上一步
            break
        case .checkinPhotos, .scoreInput:
            step = .ocrResult
        case .cardEditor, .cardPreview:
            step = .checkinPhotos
        case .saveSuccess:
            step = .cardPreview
        }
    }

    @MainActor
    func buildPreview(isPro: Bool) async {
        applySuggestedFontSizeIfNeeded()
        isRendering = true
        defer { isRendering = false }

        let record = WODRecord()
        record.wodDate = wodDate
        record.wodContent = wodLines
        record.difficultyRating = difficultyLevel.rawValue
        record.completionMinutes = completionMinutes
        record.scoreType = scoreType.rawValue
        record.scoreValue = formattedScore
        record.scoreScaling = scoreScaling?.rawValue
        record.note = note.isEmpty ? nil : note
        record.cardStyleId = selectedStyleId
        record.textLayout = textLayout
        record.enabledModules = enabledModules
        previewRecord = record

        do {
            renderedCardImage = try await CardRenderer.render(
                record: record,
                style: CardStyleConfig.style(for: selectedStyleId),
                isPro: isPro,
                checkinImages: selectedCheckinImages
            )
            step = .cardPreview
        } catch {
            ocrState = .failure("卡片生成失败，请重试")
        }
    }

    func finalizeRecord() -> WODRecord {
        previewRecord.wodDate = wodDate
        previewRecord.wodContent = wodLines
        previewRecord.difficultyRating = difficultyLevel.rawValue
        previewRecord.completionMinutes = completionMinutes
        previewRecord.scoreType = scoreType.rawValue
        previewRecord.scoreValue = formattedScore
        previewRecord.scoreScaling = scoreScaling?.rawValue
        previewRecord.note = note.isEmpty ? nil : note
        previewRecord.cardStyleId = selectedStyleId
        previewRecord.textLayout = textLayout
        previewRecord.enabledModules = enabledModules
        if let renderedCardImage, let jpegData = renderedCardImage.jpegData(compressionQuality: 0.9) {
            // 双写：文件供本地快速读取，cardImageData 随 iCloud 同步到其他设备
            previewRecord.cardImagePath = persistImageData(jpegData, prefix: "card")
            previewRecord.cardImageData = jpegData
        }
        return previewRecord
    }

    func retryOCR() {
        guard let selectedWhiteboardImage else { return }
        networkRetryCount = 0
        ocrState = .processing
        performOCR(image: selectedWhiteboardImage)
    }

    func selectStyle(_ style: CardStyle, isPro: Bool) -> Bool {
        guard !style.isPro || isPro else {
            return false
        }
        applyTemplate(style)
        return true
    }

    /// 模块是否当前已开启（仅看用户开关，不含模板支持判断）。
    func isModuleEnabled(_ module: CardModule) -> Bool {
        enabledModules.contains(module.rawValue)
    }

    /// 开关某模块；模板不支持的模块由 UI 禁用，此处仅兜底不允许开启不支持项。
    func toggleModule(_ module: CardModule) {
        if let index = enabledModules.firstIndex(of: module.rawValue) {
            enabledModules.remove(at: index)
        } else {
            guard CardStyleConfig.style(for: selectedStyleId).supportedModules.contains(module) else { return }
            enabledModules.append(module.rawValue)
        }
        // 模块增减改变了卡面内容高度，重新自适应字号（用户手动调过则尊重其选择）
        applySuggestedFontSizeIfNeeded()
    }

    func applyTemplate(_ style: CardStyle) {
        selectedStyleId = style.id
        hasUserAdjustedFontSize = false
        switch style.id {
        case "style_basic_dark":
            textLayout.verticalPosition = .bottom
            textLayout.horizontalPosition = .trailing
            textLayout.fontSize = 16
            textLayout.textColor = "#FFFFFF"
            textLayout.textOpacity = 1
            textLayout.fontPreset = .display
        case "style_mono_overlay":
            textLayout.verticalPosition = .top
            textLayout.horizontalPosition = .trailing
            textLayout.fontSize = 15
            textLayout.textColor = "#F8F8F4"
            textLayout.textOpacity = 1
            textLayout.fontPreset = .mono
        case "style_plain_pro":
            textLayout.verticalPosition = .top
            textLayout.horizontalPosition = .leading
            textLayout.fontSize = 20
            textLayout.textColor = "#FFF4C2"
            textLayout.textOpacity = 1
            textLayout.fontPreset = .serif
        case "style_minimal_white":
            textLayout.verticalPosition = .bottom
            textLayout.horizontalPosition = .leading
            textLayout.fontSize = 16
            textLayout.textColor = "#1A1A1A"
            textLayout.textOpacity = 1
            textLayout.fontPreset = .display
        case "style_hero_title":
            textLayout.verticalPosition = .center
            textLayout.horizontalPosition = .leading
            textLayout.fontSize = 18
            textLayout.textColor = "#FFFFFF"
            textLayout.textOpacity = 1
            textLayout.fontPreset = .display
        case "style_data_dashboard":
            textLayout.verticalPosition = .bottom
            textLayout.horizontalPosition = .leading
            textLayout.fontSize = 14
            textLayout.textColor = "#00FF88"
            textLayout.textOpacity = 1
            textLayout.fontPreset = .mono
        case "style_retro_film":
            textLayout.verticalPosition = .bottom
            textLayout.horizontalPosition = .leading
            textLayout.fontSize = 15
            textLayout.textColor = "#F0E6C8"
            textLayout.textOpacity = 1
            textLayout.fontPreset = .mono
        default:
            break
        }
        applySuggestedFontSizeIfNeeded()
    }

    func applyFontPreset(_ preset: TextLayout.FontPreset) {
        textLayout.fontPreset = preset
    }

    func updateFontSize(_ size: Double) {
        textLayout.fontSize = size
        hasUserAdjustedFontSize = true
    }

    var wodLines: [String] {
        wodContentText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func applySuggestedFontSizeIfNeeded() {
        guard !hasUserAdjustedFontSize else { return }
        textLayout.fontSize = CardRenderer.suggestedFontSize(
            for: wodLines,
            images: selectedCheckinImages,
            style: CardStyleConfig.style(for: selectedStyleId),
            preferredSize: textLayout.fontSize,
            extraLineEquivalents: moduleExtraLineEquivalents
        )
    }

    /// 已开启且有数据的「成绩 / 难度 / 完成时间」模块折算成的等效文本行数（日期已计入各布局 chrome）。
    private var moduleExtraLineEquivalents: Double {
        let supported = CardStyleConfig.style(for: selectedStyleId).supportedModules
        func on(_ m: CardModule, hasData: Bool) -> Bool {
            hasData && supported.contains(m) && enabledModules.contains(m.rawValue)
        }
        var total = 0.0
        if on(.score, hasData: formattedScore != nil) { total += 2.4 }
        if on(.difficulty, hasData: true) { total += 1.2 }
        if on(.note, hasData: !note.isEmpty) { total += 1.4 }
        return total
    }

    private func localizedOCRError(_ error: Error, isNetworkError: Bool) -> String {
        if isNetworkError {
            if let urlError = error as? URLError, urlError.code == .timedOut {
                return "请求超时，请检查网络后重试"
            }
            return "请检查网络后重试"
        }
        switch error {
        case OCRError.invalidImage:
            return "图片格式有误，请重新拍摄"
        case OCRError.serviceUnavailable:
            return "识别服务暂时不可用，请稍后重试"
        case OCRError.parseError:
            return "内容解析失败，请手动输入训练内容"
        default:
            return "识别失败，你可以手动输入今日训练内容"
        }
    }

    private func persistImageData(_ data: Data, prefix: String) -> String? {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("WODTrackRecords", isDirectory: true)
        guard let directory else { return nil }

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            let filename = "\(prefix)-\(UUID().uuidString).jpg"
            let url = directory.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }
}
