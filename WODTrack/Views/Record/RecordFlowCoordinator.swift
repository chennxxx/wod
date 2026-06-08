import PhotosUI
import Photos
import Observation
import SwiftUI
import UIKit
import AVFoundation

struct RecordFlowCoordinator: View {
    @Environment(\.dismiss) private var dismiss
    let appState: AppState
    @State private var viewModel = RecordFlowViewModel()
    let onSaved: (WODRecord) -> Void

    init(appState: AppState, onSaved: @escaping (WODRecord) -> Void) {
        self.appState = appState
        self.onSaved = onSaved
        let service: OCRServicing = AppConfig.useMockOCR ? PreviewOCRService() : DoubaoLLMService.shared
        _viewModel = State(initialValue: RecordFlowViewModel(ocrService: service))
    }

    var body: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()

            switch viewModel.step {
            case .whiteboard:
                WhiteboardStep(viewModel: viewModel, dismiss: dismiss.callAsFunction)
            case .checkinPhotos:
                CheckinPhotosStep(viewModel: viewModel)
            case .ocrResult:
                OCRResultStep(viewModel: viewModel)
            case .scoreInput:
                CheckinPhotosStep(viewModel: viewModel)
            case .cardEditor:
                CardPreviewStep(viewModel: viewModel, appState: appState, onSaved: {
                    viewModel.goToSaveSuccess()
                })
            case .cardPreview:
                CardPreviewStep(viewModel: viewModel, appState: appState, onSaved: {
                    viewModel.goToSaveSuccess()
                })
            case .saveSuccess:
                SaveSuccessStep(viewModel: viewModel, onDone: {
                    onSaved(viewModel.finalizeRecord())
                    appState.triggerLoginPromptAfterSave()
                    dismiss()
                })
            }
        }
        .navigationBarBackButtonHidden()
    }
}

private struct WhiteboardStep: View {
    @Bindable var viewModel: RecordFlowViewModel
    let dismiss: () -> Void
    @State private var pickerItem: PhotosPickerItem?
    @State private var showSourceDialog = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showCameraUnavailable = false

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.lg) {
            HStack(spacing: WTSpacing.sm) {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.wtPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.wtSurface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("关闭")

                Text("记录今日 WOD")
                    .font(WTFont.title)

                Spacer()
            }

            Text("你可以拍摄白板、从相册导入，或者直接手动输入今日训练内容。")
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            VStack(spacing: WTSpacing.md) {
                Button {
                    showSourceDialog = true
                } label: {
                    WhiteboardActionCard(title: "拍摄或从相册选取", icon: "camera.on.rectangle.fill", subtitle: "识别白板上的 WOD 内容")
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.startManualEntry()
                } label: {
                    WhiteboardActionCard(title: "手动输入", icon: "keyboard.fill", subtitle: "直接录入今日 WOD 文本")
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(WTSpacing.lg)
        .confirmationDialog("导入方式", isPresented: $showSourceDialog, titleVisibility: .visible) {
            Button("立即拍摄") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCamera = true
                } else {
                    showCameraUnavailable = true
                }
            }
            Button("从相册选取") {
                showPhotoPicker = true
            }
            Button("取消", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickerItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                showCamera = false
                viewModel.startFlow(with: image)
            } onCancel: {
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .alert("相机不可用", isPresented: $showCameraUnavailable) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("当前设备不支持相机拍摄，请使用相册导入。")
        }
        .task(id: pickerItem) {
            guard let data = try? await pickerItem?.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            viewModel.startFlow(with: image)
        }
    }
}

private struct CheckinPhotosStep: View {
    @Bindable var viewModel: RecordFlowViewModel
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        RecordFlowStepPage(title: "选择训练打卡照", backAction: viewModel.goBack) {
            VStack(alignment: .leading, spacing: WTSpacing.md) {
                Text("选 1 张今天的训练照片")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)

                PhotosPicker(selection: $pickerItems, maxSelectionCount: 1, matching: .images) {
                    RoundedRectangle(cornerRadius: WTRadius.lg)
                        .fill(Color.wtSurface)
                        .frame(maxWidth: .infinity, minHeight: 260)
                        .overlay {
                            VStack(spacing: WTSpacing.sm) {
                                Image(systemName: "photo.stack")
                                    .font(.system(size: 42))
                                    .foregroundStyle(Color.wtPrimary)
                                Text("导入训练照片")
                                    .font(WTFont.bodyBold)
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: WTRadius.lg))
                }

                if !viewModel.selectedCheckinImages.isEmpty {
                    VStack(alignment: .leading, spacing: WTSpacing.sm) {
                        Text("已选照片")
                            .font(WTFont.caption)
                            .foregroundStyle(Color.wtTextSecondary)

                        HStack(spacing: WTSpacing.sm) {
                            ForEach(Array(viewModel.selectedCheckinImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 104, height: 104)
                                        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))

                                    Text("\(index + 1)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.wtPrimary)
                                        .clipShape(Capsule())
                                        .padding(8)
                                }
                            }
                        }
                    }
                }
            }
            .padding(WTSpacing.lg)
        } bottomBar: {
            WTButton(title: "上一步", style: .secondary, action: viewModel.goBack)
            WTButton(title: "下一步", isEnabled: !viewModel.selectedCheckinImages.isEmpty) {
                viewModel.goToCardPreview()
            }
        }
        .task(id: pickerItems) {
            guard let item = pickerItems.first,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                viewModel.selectedCheckinImages = []
                return
            }
            viewModel.selectedCheckinImages = [image]
        }
    }
}

private struct OCRStatusBanner: View {
    @Bindable var viewModel: RecordFlowViewModel

    var body: some View {
        HStack {
            switch viewModel.ocrState {
            case .idle, .processing:
                ProgressView()
                    .tint(.wtPrimary)
                Text("正在识别白板内容…")
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.wtSuccess)
                Text("识别完成，请确认内容")
            case .failure(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.wtDanger)
                Text(message)
            }
            Spacer()
        }
        .font(WTFont.caption)
        .padding()
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
    }
}

private struct OCRLoadingView: View {
    private let messages = ["正在抓取白板内容", "正在处理白板内容", "正在将图片转化为文字"]
    @State private var messageIndex = 0

    var body: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()

            VStack(spacing: WTSpacing.lg) {
                ProgressView()
                    .tint(.wtPrimary)
                    .scaleEffect(1.4)

                VStack(spacing: WTSpacing.xs) {
                    Text(messages[messageIndex])
                        .font(WTFont.bodyBold)
                        .foregroundStyle(Color.wtTextPrimary)
                        .id(messageIndex)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.4), value: messageIndex)

                    Text("通常需要 5-15 秒")
                        .font(WTFont.caption)
                        .foregroundStyle(Color.wtTextSecondary)
                }
            }
        }
        .onAppear {
            startCycling()
        }
    }

    private func startCycling() {
        Timer.scheduledTimer(withTimeInterval: 2.2, repeats: true) { timer in
            withAnimation {
                messageIndex = (messageIndex + 1) % messages.count
            }
        }
    }
}

private struct OCRResultStep: View {
    @Bindable var viewModel: RecordFlowViewModel

    var body: some View {
        switch viewModel.ocrState {
        case .idle, .processing:
            OCRLoadingView()
        case .failure(let message):
            RecordFlowStepPage(title: "识别失败", backAction: viewModel.goBack) {
                VStack(alignment: .leading, spacing: WTSpacing.lg) {
                    Text(message).font(WTFont.body)
                    WTTextEditor(
                        title: "手动输入 WOD",
                        placeholder: """
直接输入今日训练内容

例如：
A 热身/完成以下3轮
10空杆早安式
20S原地高抬腿
""",
                        text: $viewModel.wodContentText,
                        minHeight: 280
                    )
                }
                .padding(WTSpacing.lg)
            } bottomBar: {
                WTButton(title: "重试", style: .secondary, action: viewModel.retryOCR)
                WTButton(title: "继续", isEnabled: !viewModel.wodLines.isEmpty, action: viewModel.goToCheckinPhotos)
            }
        case .success:
            RecordFlowStepPage(title: "今日 WOD 内容", backAction: viewModel.goBack) {
                VStack(alignment: .leading, spacing: WTSpacing.md) {
                    Text(viewModel.entryMode == .manual ? "直接输入今天的训练内容。" : "识别完成，请在这里确认和修改内容。")
                        .font(WTFont.caption)
                        .foregroundStyle(Color.wtTextSecondary)

                    WTTextEditor(
                        title: "WOD 内容",
                        placeholder: """
A 热身/完成以下3轮
10空杆早安式
20S原地高抬腿

B 12EMOM练习
25S面墙倒立
6波比引体

C WOD/任务计时/7轮
11自重硬拉
100M
""",
                        text: $viewModel.wodContentText,
                        minHeight: 320
                    )

                    CompletionTimeField(completionMinutes: $viewModel.completionMinutes)

                    DifficultyRatingField(rating: $viewModel.difficultyRating)
                }
                .padding(WTSpacing.lg)
            } bottomBar: {
                WTButton(title: "下一步：选择训练照", isEnabled: !viewModel.wodLines.isEmpty, action: viewModel.goToCheckinPhotos)
            }
        }
    }
}

private struct RecordFlowStepPage<Content: View, BottomBar: View>: View {
    let title: String
    let backAction: () -> Void
    @ViewBuilder let content: Content
    @ViewBuilder let bottomBar: BottomBar

    var body: some View {
        VStack(spacing: 0) {
            RecordStepHeader(title: title, backAction: backAction)
                .padding(.horizontal, WTSpacing.lg)
                .padding(.top, WTSpacing.md)
                .padding(.bottom, WTSpacing.sm)
                .background(Color.wtBackground)

            ScrollView {
                content
            }
        }
        .safeAreaInset(edge: .bottom) {
            RecordFlowBottomBar {
                bottomBar
            }
        }
    }
}

private struct RecordStepHeader: View {
    let title: String
    let backAction: () -> Void

    var body: some View {
        HStack(spacing: WTSpacing.sm) {
            Button(action: backAction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.wtPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.wtSurface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回上一步")

            Text(title)
                .font(WTFont.title)

            Spacer()
        }
    }
}

private struct RecordFlowBottomBar<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: WTSpacing.sm) {
            content
        }
        .padding(.horizontal, WTSpacing.lg)
        .padding(.top, WTSpacing.sm)
        .padding(.bottom, WTSpacing.md)
        .background(.ultraThinMaterial)
    }
}

private struct CompletionTimeField: View {
    @Binding var completionMinutes: Int?
    @State private var customText = ""
    @State private var isCustom = false

    private let presets = [45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text("完成时间")
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            HStack(spacing: WTSpacing.sm) {
                ForEach(presets, id: \.self) { minutes in
                    Button {
                        isCustom = false
                        customText = ""
                        completionMinutes = completionMinutes == minutes ? nil : minutes
                    } label: {
                        Text("\(minutes) 分钟")
                            .font(WTFont.bodyBold)
                            .foregroundStyle((!isCustom && completionMinutes == minutes) ? Color.black : Color.wtTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background((!isCustom && completionMinutes == minutes) ? Color.wtPrimary : Color.wtSurface)
                            .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                            .contentShape(RoundedRectangle(cornerRadius: WTRadius.md))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    isCustom.toggle()
                    if !isCustom {
                        completionMinutes = Int(customText)
                    }
                } label: {
                    Text("自定义")
                        .font(WTFont.bodyBold)
                        .foregroundStyle(isCustom ? Color.black : Color.wtTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isCustom ? Color.wtPrimary : Color.wtSurface)
                        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                        .contentShape(RoundedRectangle(cornerRadius: WTRadius.md))
                }
                .buttonStyle(.plain)
            }

            if isCustom {
                HStack(spacing: WTSpacing.sm) {
                    TextField("输入分钟数", text: $customText)
                        .keyboardType(.numberPad)
                        .font(WTFont.body)
                        .foregroundStyle(Color.wtTextPrimary)
                        .padding(.horizontal, WTSpacing.md)
                        .frame(height: 40)
                        .background(Color.wtSurface)
                        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                        .onChange(of: customText) { _, new in
                            completionMinutes = Int(new)
                        }

                    Text("分钟")
                        .font(WTFont.caption)
                        .foregroundStyle(Color.wtTextSecondary)
                }
            }
        }
    }
}

private struct DifficultyRatingField: View {
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            HStack {
                Text("今日难度")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                Spacer()
                Text("\(clampedRating)/5")
                    .font(WTFont.bodyBold)
            }

            HStack(spacing: WTSpacing.sm) {
                ForEach(1 ... 5, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Image(systemName: value <= clampedRating ? "star.fill" : "star")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(value <= clampedRating ? Color.wtPrimary : Color.wtTextDisabled)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("难度 \(value) 星")
                    .accessibilityAddTraits(value == clampedRating ? .isSelected : [])
                }
            }
            .padding(.horizontal, WTSpacing.xs)
            .padding(.vertical, WTSpacing.sm)
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: WTRadius.md)
                    .stroke(Color.wtSurface2, lineWidth: 1)
            )
        }
    }

    private var clampedRating: Int {
        min(max(rating, 1), 5)
    }
}

private struct CardEditorStep: View {
    @Bindable var viewModel: RecordFlowViewModel
    let appState: AppState
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WTSpacing.lg) {
                Text("卡片样式与排版")
                    .font(WTFont.title)

                Text("样式")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)

                ForEach(CardStyleConfig.all) { style in
                    Button {
                        if !viewModel.selectStyle(style, isPro: appState.isPro) {
                            showPaywall = true
                        }
                    } label: {
                        HStack {
                            Text(style.name)
                            Spacer()
                            if style.isPro {
                                Text("PRO")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.wtPrimary)
                                    .foregroundStyle(.black)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding()
                        .background(Color.wtSurface)
                        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                        .contentShape(RoundedRectangle(cornerRadius: WTRadius.md))
                    }
                    .buttonStyle(.plain)
                }

                Picker("文字位置", selection: $viewModel.textLayout.verticalPosition) {
                    ForEach(TextLayout.VerticalPosition.allCases) { position in
                        Text(position.label).tag(position)
                    }
                }
                .pickerStyle(.segmented)

                WTButton(title: viewModel.isRendering ? "生成中…" : "生成卡片", isEnabled: !viewModel.isRendering) {
                    Task { await viewModel.buildPreview(isPro: appState.isPro) }
                }
            }
            .padding(WTSpacing.lg)
        }
        .alert("订阅后可用", isPresented: $showPaywall) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("免费用户不可移除水印，Pro 样式需要订阅后解锁。")
        }
    }
}

private struct CardPreviewStep: View {
    @Bindable var viewModel: RecordFlowViewModel
    let appState: AppState
    let onSaved: () -> Void
    @State private var selectedTab: EditorTab = .template
    @State private var showPaywall = false
    @State private var isSaving = false

    var body: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                previewTopBar

                canvasArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                editorPanel
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .alert("订阅后可用", isPresented: $showPaywall) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("免费用户不可移除水印，Pro 模板需要订阅后解锁。")
        }
    }

    // MARK: - 画布区域

    private var previewTopBar: some View {
        HStack(spacing: WTSpacing.sm) {
            Button(action: viewModel.goBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.wtPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.wtSurface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回上一步")

            Text("最终预览")
                .font(WTFont.title)

            Spacer()

            Button {
                saveRecord()
            } label: {
                Text(isSaving ? "保存中" : "保存")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 76, height: 44)
                    .background(Color.wtPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
            .opacity(isSaving ? 0.65 : 1)
        }
        .padding(.horizontal, WTSpacing.md)
        .padding(.top, WTSpacing.sm)
        .padding(.bottom, WTSpacing.xs)
        .background(Color.wtBackground)
    }

    /// 画布区域只负责等比展示最终导出卡片，不裁切、不套固定预览框。
    private var canvasArea: some View {
        GeometryReader { proxy in
            let canvasSize = fittedCardSize(in: proxy.size)

            ZStack {
                Color.wtBackground

                CardView(
                    record: previewRecord,
                    style: CardStyleConfig.style(for: viewModel.selectedStyleId),
                    isPro: appState.isPro,
                    checkinImages: viewModel.selectedCheckinImages
                )
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))
                .shadow(color: .black.opacity(0.42), radius: 18, x: 0, y: 8)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    // MARK: - 编辑面板

    private var editorPanel: some View {
        VStack(spacing: 0) {
            panelContent
                .frame(height: 116)

            Divider()
                .background(Color.wtSurface2)

            editorTabBar
                .frame(height: 64)
        }
        .background(Color.black)
    }

    @ViewBuilder private var panelContent: some View {
        switch selectedTab {
        case .template: templatePanel
        case .text:     textPanel
        case .position: positionPanel
        }
    }

    // MARK: - 数据

    private var previewRecord: WODRecord {
        let record = WODRecord()
        record.wodType = viewModel.wodType
        record.wodContent = viewModel.wodLines
        record.completionStatus = viewModel.completionStatus
        record.difficultyRating = viewModel.difficultyRating
        record.cardStyleId = viewModel.selectedStyleId
        record.textLayout = viewModel.textLayout
        return record
    }

    // MARK: - 标签栏

    private var editorTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: WTSpacing.xl) {
                ForEach(EditorTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 6) {
                            Text(tab.label)
                                .font(.system(size: 15, weight: .semibold))

                            Capsule()
                                .fill(selectedTab == tab ? Color.wtPrimary : Color.clear)
                                .frame(width: 28, height: 3)
                        }
                        .foregroundStyle(selectedTab == tab ? Color.wtPrimary : Color.wtTextSecondary)
                        .frame(minWidth: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, WTSpacing.lg)
        }
    }

    // MARK: - 模板面板

    private var templatePanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: WTSpacing.sm) {
                ForEach(CardStyleConfig.all) { style in
                    Button {
                        if !viewModel.selectStyle(style, isPro: appState.isPro) {
                            showPaywall = true
                        }
                    } label: {
                        VStack(alignment: .center, spacing: WTSpacing.xs) {
                            ZStack {
                                RoundedRectangle(cornerRadius: WTRadius.sm)
                                    .fill(style.id == viewModel.selectedStyleId ? Color.wtPrimary.opacity(0.9) : Color.wtSurface2)

                                Image(systemName: styleIcon(for: style.layout))
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(style.id == viewModel.selectedStyleId ? Color.black : Color.wtTextPrimary)
                            }
                            .frame(width: 62, height: 62)

                            Text(style.name)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)

                            if style.isPro {
                                Text("PRO")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.wtPrimary)
                            }
                        }
                        .foregroundStyle(style.id == viewModel.selectedStyleId ? Color.wtPrimary : Color.wtTextPrimary)
                        .frame(width: 78, height: 98, alignment: .top)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, WTSpacing.lg)
            .padding(.vertical, WTSpacing.sm)
        }
    }

    // MARK: - 文字面板

    private var textPanel: some View {
        VStack(spacing: WTSpacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: WTSpacing.sm) {
                    ForEach(TextLayout.FontPreset.allCases) { preset in
                        Button {
                            viewModel.applyFontPreset(preset)
                        } label: {
                            Text(preset.label)
                                .font(fontPreview(for: preset))
                                .frame(width: 76, height: 38)
                                .background(viewModel.textLayout.fontPreset == preset ? Color.wtPrimary : Color.wtSurface2)
                                .foregroundStyle(viewModel.textLayout.fontPreset == preset ? Color.black : Color.wtTextPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))
                                .contentShape(RoundedRectangle(cornerRadius: WTRadius.sm))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, WTSpacing.lg)
            }

            HStack(spacing: WTSpacing.sm) {
                Image(systemName: "textformat.size")
                    .foregroundStyle(Color.wtTextSecondary)
                Slider(value: fontSizeBinding, in: 5 ... 30, step: 1)
                    .tint(.wtPrimary)
                Text("\(Int(viewModel.textLayout.fontSize))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.wtTextPrimary)
                    .frame(width: 28, alignment: .trailing)
            }
            .padding(.horizontal, WTSpacing.lg)

            HStack(spacing: WTSpacing.sm) {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(Color.wtTextSecondary)
                Slider(value: $viewModel.textLayout.textOpacity, in: 0.3 ... 1.0, step: 0.05)
                    .tint(.wtPrimary)
                Text("\(Int(viewModel.textLayout.textOpacity * 100))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.wtTextPrimary)
                    .frame(width: 32, alignment: .trailing)
            }
            .padding(.horizontal, WTSpacing.lg)
        }
        .padding(.vertical, WTSpacing.sm)
    }

    // MARK: - 图片面板

    private var imagePanel: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            HStack(spacing: WTSpacing.sm) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.wtPrimary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("原图比例")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.wtTextPrimary)
                    Text("横图保存为横图，竖图保存为竖图")
                        .font(WTFont.micro)
                        .foregroundStyle(Color.wtTextSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, WTSpacing.md)
            .frame(height: 76)
            .background(Color.wtSurface2)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))
            .padding(.horizontal, WTSpacing.lg)

            if viewModel.selectedCheckinImages.isEmpty {
                Label("请先返回上一步添加训练照片", systemImage: "info.circle")
                    .font(WTFont.micro)
                    .foregroundStyle(Color.wtTextSecondary)
                    .padding(.horizontal, WTSpacing.lg)
            }
        }
        .padding(.vertical, WTSpacing.sm)
    }

    // MARK: - 位置面板

    private var positionPanel: some View {
        VStack(spacing: WTSpacing.sm) {
            HStack(spacing: WTSpacing.sm) {
                ForEach(TextLayout.VerticalPosition.allCases) { position in
                    VStack(spacing: 6) {
                        Button {
                            viewModel.textLayout.verticalPosition = position
                        } label: {
                            Image(systemName: positionIcon(for: position))
                                .font(.system(size: 20, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(
                                    viewModel.textLayout.verticalPosition == position
                                        ? Color.wtPrimary
                                        : Color.wtSurface2
                                )
                                .foregroundStyle(
                                    viewModel.textLayout.verticalPosition == position
                                        ? Color.black
                                        : Color.wtTextPrimary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                                .contentShape(RoundedRectangle(cornerRadius: WTRadius.md))
                        }
                        .buttonStyle(.plain)

                        Text(position.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.wtTextSecondary)
                    }
                }

                if supportsHorizontalAlignment {
                    Rectangle()
                        .fill(Color.wtSurface2)
                        .frame(width: 1, height: 48)

                    ForEach(TextLayout.HorizontalPosition.allCases) { position in
                        VStack(spacing: 6) {
                            Button {
                                viewModel.textLayout.horizontalPosition = position
                            } label: {
                                Image(systemName: position.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(
                                        viewModel.textLayout.horizontalPosition == position
                                            ? Color.wtPrimary
                                            : Color.wtSurface2
                                    )
                                    .foregroundStyle(
                                        viewModel.textLayout.horizontalPosition == position
                                            ? Color.black
                                            : Color.wtTextPrimary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                                    .contentShape(RoundedRectangle(cornerRadius: WTRadius.md))
                            }
                            .buttonStyle(.plain)

                            Text(position.label)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.wtTextSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, WTSpacing.lg)
        }
        .padding(.vertical, WTSpacing.sm)
    }

    private var supportsHorizontalAlignment: Bool {
        let layout = CardStyleConfig.style(for: viewModel.selectedStyleId).layout
        switch layout {
        case .bottomCard, .bottomCardLight, .dataDashboard: return true
        default: return false
        }
    }

    // MARK: - 辅助

    private func saveRecord() {
        guard !isSaving else { return }
        isSaving = true
        Task { @MainActor in
            await viewModel.buildPreview(isPro: appState.isPro)
            isSaving = false
            if let cardImage = viewModel.renderedCardImage {
                saveImageToPhotoLibrary(cardImage)
            }
            onSaved()
        }
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        }
    }

    private func fittedCardSize(in availableSize: CGSize) -> CGSize {
        let horizontalInset: CGFloat = 32
        let verticalInset: CGFloat = 24
        let maxWidth = max(availableSize.width - horizontalInset, 1)
        let maxHeight = max(availableSize.height - verticalInset, 1)
        let aspectRatio = CardRenderer.aspectRatio(for: viewModel.selectedCheckinImages)
        let widthFromHeight = maxHeight * aspectRatio

        if widthFromHeight <= maxWidth {
            return CGSize(width: widthFromHeight, height: maxHeight)
        }

        return CGSize(width: maxWidth, height: maxWidth / aspectRatio)
    }

    private func fontPreview(for preset: TextLayout.FontPreset) -> Font {
        switch preset {
        case .display: .system(size: 16, weight: .semibold, design: .default)
        case .rounded: .system(size: 16, weight: .semibold, design: .rounded)
        case .serif:   .system(size: 16, weight: .semibold, design: .serif)
        case .mono:    .system(size: 16, weight: .semibold, design: .monospaced)
        }
    }

    private var fontSizeBinding: Binding<Double> {
        Binding(
            get: { viewModel.textLayout.fontSize },
            set: { viewModel.updateFontSize($0) }
        )
    }

    private func positionIcon(for position: TextLayout.VerticalPosition) -> String {
        switch position {
        case .top:    "arrow.up.to.line"
        case .center: "arrow.up.and.down"
        case .bottom: "arrow.down.to.line"
        }
    }

    private func styleIcon(for layout: CardStyle.LayoutStyle) -> String {
        switch layout {
        case .bottomCard: "rectangle.bottomthird.inset.filled"
        case .bottomCardLight: "rectangle.bottomthird.inset.filled"
        case .editorialTop: "rectangle.topthird.inset.filled"
        case .rightOverlayMono: "text.alignright"
        case .heroTitle: "textformat.size.larger"
        case .dataDashboard: "chart.bar.fill"
        case .retroFilm: "film.fill"
        }
    }

    // MARK: - 标签枚举

    private enum EditorTab: String, CaseIterable, Identifiable {
        case template
        case text
        case position

        var id: String { rawValue }

        var label: String {
            switch self {
            case .template: "模板"
            case .text:     "文字"
            case .position: "位置"
            }
        }

        var icon: String {
            switch self {
            case .template: "square.grid.2x2.fill"
            case .text:     "textformat.size"
            case .position: "slider.horizontal.3"
            }
        }
    }
}

private struct WhiteboardActionCard: View {
    let title: String
    let icon: String
    let subtitle: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: WTRadius.lg)
                .fill(Color.wtSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: WTRadius.lg)
                        .stroke(Color.wtSurface2, lineWidth: 1)
                )

            // 右下角装饰图标
            Image(systemName: icon)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Color.wtPrimary.opacity(0.06))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(WTSpacing.sm)
                .clipped()

            VStack(spacing: WTSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Color.wtPrimary)
                Text(title).font(WTFont.bodyBold)
                Text(subtitle).font(WTFont.micro).foregroundStyle(Color.wtTextSecondary)
            }
            .padding(WTSpacing.md)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .contentShape(RoundedRectangle(cornerRadius: WTRadius.lg))
    }
}

// MARK: - Save Success

private struct SaveSuccessStep: View {
    let viewModel: RecordFlowViewModel
    let onDone: () -> Void
    @State private var showShareSheet = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部标题栏
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.wtSuccess)
                            Text("保存成功")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color.wtTextPrimary)
                        }
                        Text("已保存到相册")
                            .font(WTFont.caption)
                            .foregroundStyle(Color.wtTextSecondary)
                    }
                    Spacer()
                }
                .frame(height: 68)
                .padding(.horizontal, WTSpacing.lg)
                .background(Color.wtBackground)

                Divider().background(Color.wtSurface2)

                // 卡片预览
                Spacer()

                if let cardImage = viewModel.renderedCardImage {
                    Image(uiImage: cardImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 8)
                        .padding(.horizontal, WTSpacing.xl)
                } else {
                    RoundedRectangle(cornerRadius: WTRadius.md)
                        .fill(Color.wtSurface)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .padding(.horizontal, WTSpacing.xl)
                }

                Spacer()

                // 底部按钮
                VStack(spacing: WTSpacing.sm) {
                    WTButton(title: "分享到社交媒体") {
                        showShareSheet = true
                    }
                    WTButton(title: "完成", style: .secondary, action: onDone)
                }
                .padding(.horizontal, WTSpacing.lg)
                .padding(.bottom, WTSpacing.lg)
            }

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            showConfetti = true
        }
        .sheet(isPresented: $showShareSheet) {
            if let cardImage = viewModel.renderedCardImage {
                ShareSheet(items: [cardImage])
                    .ignoresSafeArea()
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
}

private struct ConfettiView: View {
    private let particles: [ConfettiParticle] = (0..<60).map { i in
        let colors: [Color] = [.yellow, .green, .blue, .red, .orange, .purple, .pink, .cyan]
        return ConfettiParticle(
            x: CGFloat.random(in: 0...1),
            color: colors[i % colors.count],
            size: CGFloat.random(in: 6...12),
            rotation: Double.random(in: 0...360),
            delay: Double.random(in: 0...0.8),
            duration: Double.random(in: 1.8...3.0)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                ConfettiPiece(particle: p, screenSize: geo.size)
            }
        }
    }
}

private struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let screenSize: CGSize
    @State private var fallen = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.5)
            .rotationEffect(.degrees(fallen ? particle.rotation + 360 : particle.rotation))
            .position(
                x: particle.x * screenSize.width,
                y: fallen ? screenSize.height + 20 : -20
            )
            .opacity(fallen ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeIn(duration: particle.duration)
                    .delay(particle.delay)
                ) {
                    fallen = true
                }
            }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Camera Picker

private struct CameraPickerView: UIViewControllerRepresentable {
    let onPhoto: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPhoto: onPhoto, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPhoto: (UIImage) -> Void
        let onCancel: () -> Void

        init(onPhoto: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onPhoto = onPhoto
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            if let image {
                onPhoto(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
