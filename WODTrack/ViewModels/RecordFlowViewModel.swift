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
        case whiteboard
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

    var step: RecordStep = .whiteboard
    var selectedWhiteboardImage: UIImage?
    var selectedCheckinImages: [UIImage] = []
    var wodType: WODType = .other
    var wodContentText = ""
    var completionStatus: CompletionStatus = .completed
    var difficultyRating = 3
    var completionMinutes: Int? = nil
    var selectedStyleId = "style_mono_overlay"
    var textLayout = TextLayout()
    var ocrState: OCRState = .idle
    var previewRecord = WODRecord()
    var renderedCardImage: UIImage?
    var isRendering = false
    var entryMode: EntryMode = .photoOCR

    private let ocrService: OCRServicing
    private var hasUserAdjustedFontSize = false
    private var networkRetryCount = 0
    private let maxNetworkRetries = 3
    private var ocrTask: Task<Void, Never>?
    private let ocrTimeoutSeconds: Double = 10

    init(ocrService: OCRServicing = PreviewOCRService()) {
        self.ocrService = ocrService
    }

    func startFlow(with image: UIImage) {
        entryMode = .photoOCR
        selectedWhiteboardImage = image
        networkRetryCount = 0
        ocrState = .processing
        step = .ocrResult
        performOCR(image: image)
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
                    wodType = result.wodType
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
                        ocrState = .failure(error.localizedDescription)
                    }
                }
            }
        }
        ocrTask = task
    }

    func startManualEntry() {
        entryMode = .manual
        selectedWhiteboardImage = nil
        wodType = .other
        wodContentText = ""
        ocrState = .success(OCRResult(wodType: .other, wodContent: [], confidence: 1))
        step = .ocrResult
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
        case .whiteboard:
            break
        case .ocrResult:
            ocrTask?.cancel()
            ocrTask = nil
            step = .whiteboard
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
        record.wodType = wodType
        record.wodContent = wodLines
        record.completionStatus = completionStatus
        record.difficultyRating = difficultyRating
        record.cardStyleId = selectedStyleId
        record.textLayout = textLayout
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
        previewRecord.wodType = wodType
        previewRecord.wodContent = wodLines
        previewRecord.completionStatus = completionStatus
        previewRecord.difficultyRating = difficultyRating
        previewRecord.completionMinutes = completionMinutes
        previewRecord.cardStyleId = selectedStyleId
        previewRecord.textLayout = textLayout
        if let renderedCardImage {
            previewRecord.cardImagePath = persistImage(renderedCardImage, prefix: "card")
        }
        if !selectedCheckinImages.isEmpty {
            previewRecord.checkinPhotoURLs = persistImages(selectedCheckinImages, prefix: "checkin")
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
            textLayout.fontSize = 15
            textLayout.textColor = "#F8F8F4"
            textLayout.textOpacity = 1
            textLayout.fontPreset = .mono
        case "style_plain_pro":
            textLayout.verticalPosition = .top
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

    private func persistImages(_ images: [UIImage], prefix: String) -> [String] {
        images.compactMap { persistImage($0, prefix: prefix) }
    }

    private func applySuggestedFontSizeIfNeeded() {
        guard !hasUserAdjustedFontSize else { return }
        textLayout.fontSize = CardRenderer.suggestedFontSize(
            for: wodLines,
            images: selectedCheckinImages,
            style: CardStyleConfig.style(for: selectedStyleId),
            preferredSize: textLayout.fontSize
        )
    }

    private func persistImage(_ image: UIImage, prefix: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
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
