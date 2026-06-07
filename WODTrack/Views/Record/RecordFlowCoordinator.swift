import PhotosUI
import Observation
import SwiftUI
import UIKit

struct RecordFlowCoordinator: View {
    @Environment(\.dismiss) private var dismiss
    let appState: AppState
    @State private var viewModel = RecordFlowViewModel()
    let onSaved: (WODRecord) -> Void

    init(appState: AppState, onSaved: @escaping (WODRecord) -> Void) {
        self.appState = appState
        self.onSaved = onSaved
        let service: OCRServicing = AppConfig.useMockOCR ? PreviewOCRService() : OCRService.shared
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
                    onSaved(viewModel.finalizeRecord())
                    appState.triggerLoginPromptAfterSave()
                    dismiss()
                })
            case .cardPreview:
                CardPreviewStep(viewModel: viewModel, appState: appState, onSaved: {
                    onSaved(viewModel.finalizeRecord())
                    appState.triggerLoginPromptAfterSave()
                    dismiss()
                })
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden()
    }
}

private struct WhiteboardStep: View {
    @Bindable var viewModel: RecordFlowViewModel
    let dismiss: () -> Void
    @State private var pickerItem: PhotosPickerItem?
    @State private var showSourceDialog = false
    @State private var showPhotoPicker = false
    @State private var showCameraNotice = false

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.lg) {
            HStack {
                Text("记录今日 WOD")
                    .font(WTFont.title)
                Spacer()
                Button("关闭", action: dismiss)
                    .foregroundStyle(Color.wtTextSecondary)
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
                showCameraNotice = true
            }
            Button("从相册选取") {
                showPhotoPicker = true
            }
            Button("取消", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickerItem, matching: .images)
        .alert("拍摄入口待接入", isPresented: $showCameraNotice) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("当前版本先保留相册导入和手动输入，系统拍摄入口我下一步接入。")
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
                Text("选 1-2 张今天的训练照片")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)

                PhotosPicker(selection: $pickerItems, maxSelectionCount: 2, matching: .images) {
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
            var images: [UIImage] = []
            for item in pickerItems {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            viewModel.selectedCheckinImages = images
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

private struct OCRResultStep: View {
    @Bindable var viewModel: RecordFlowViewModel

    var body: some View {
        switch viewModel.ocrState {
        case .idle, .processing:
            LoadingOverlay(title: "正在识别白板内容…", subtitle: "通常需要 5-15 秒")
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
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(value <= clampedRating ? Color.wtPrimary : Color.wtTextDisabled)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
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

            RecordFlowStepPage(title: "最终预览", backAction: viewModel.goBack) {
                VStack(spacing: 0) {
                    // ── 画布区域 ──
                    canvasArea
                        .padding(.horizontal, WTSpacing.md)

                    // ── 编辑面板 ──
                    VStack(spacing: 0) {
                        // 图标标签栏
                        editorTabBar
                            .padding(.horizontal, WTSpacing.md)
                            .padding(.top, WTSpacing.md)
                            .padding(.bottom, WTSpacing.sm)

                        Divider()
                            .background(Color.wtSurface2)

                        // 标签内容
                        VStack(alignment: .leading, spacing: WTSpacing.md) {
                            switch selectedTab {
                            case .template: templatePanel
                            case .text:     textPanel
                            case .image:    imagePanel
                            case .position: positionPanel
                            }
                        }
                        .padding(WTSpacing.md)
                        .padding(.bottom, WTSpacing.sm)
                        .animation(.easeInOut(duration: 0.18), value: selectedTab)
                    }
                    .background(Color.wtSurface)
                    .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
                    .padding(.horizontal, WTSpacing.md)
                    .padding(.top, WTSpacing.sm)

                    Spacer(minLength: 120)
                }
            } bottomBar: {
                WTButton(title: "上一步", style: .secondary, action: viewModel.goBack)
                WTButton(title: isSaving ? "保存中…" : "保存记录", isEnabled: !isSaving) {
                    isSaving = true
                    Task {
                        await viewModel.buildPreview(isPro: appState.isPro)
                        isSaving = false
                        onSaved()
                    }
                }
            }
        }
        .alert("订阅后可用", isPresented: $showPaywall) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("免费用户不可移除水印，Pro 模板需要订阅后解锁。")
        }
    }

    // MARK: - 画布区域

    /// 画布：深色背景 + 卡片预览，视觉上与编辑面板区分
    private var canvasArea: some View {
        ZStack {
            // 画布背景
            RoundedRectangle(cornerRadius: WTRadius.lg)
                .fill(Color(white: 0.08))

            CardView(
                record: previewRecord,
                style: CardStyleConfig.style(for: viewModel.selectedStyleId),
                isPro: appState.isPro,
                checkinImages: viewModel.selectedCheckinImages
            )
            .aspectRatio(CardRenderer.exportAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
            .padding(WTSpacing.lg)
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
        HStack(spacing: 0) {
            ForEach(EditorTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 17, weight: .medium))
                        Text(tab.label)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.wtPrimary : Color.wtTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, WTSpacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 模板面板

    private var templatePanel: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: WTSpacing.sm) {
            ForEach(CardStyleConfig.all) { style in
                Button {
                    if !viewModel.selectStyle(style, isPro: appState.isPro) {
                        showPaywall = true
                    }
                } label: {
                    VStack(alignment: .leading, spacing: WTSpacing.xs) {
                        HStack {
                            Text(style.name)
                                .font(WTFont.bodyBold)
                            Spacer()
                            if style.isPro {
                                Text("PRO")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.wtPrimary)
                                    .foregroundStyle(.black)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(style.summary)
                            .font(WTFont.caption)
                            .foregroundStyle(Color.wtTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(WTSpacing.md)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .background(style.id == viewModel.selectedStyleId ? Color.wtSurface2 : Color.black.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: WTRadius.md)
                            .stroke(style.id == viewModel.selectedStyleId ? Color.wtPrimary : .clear, lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 文字面板

    private var textPanel: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {
            Text("字体风格")
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: WTSpacing.sm) {
                ForEach(TextLayout.FontPreset.allCases) { preset in
                    Button {
                        viewModel.applyFontPreset(preset)
                    } label: {
                        Text(preset.label)
                            .font(fontPreview(for: preset))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(viewModel.textLayout.fontPreset == preset ? Color.wtPrimary : Color.wtSurface2)
                            .foregroundStyle(viewModel.textLayout.fontPreset == preset ? Color.black : Color.wtTextPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Text("字号")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                Spacer()
                Text("\(Int(viewModel.textLayout.fontSize)) pt")
                    .font(WTFont.bodyBold)
            }
            Slider(value: $viewModel.textLayout.fontSize, in: 12 ... 30, step: 1)
                .tint(.wtPrimary)
        }
    }

    // MARK: - 图片面板

    private var imagePanel: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {
            Text("照片显示方式")
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            HStack(spacing: WTSpacing.sm) {
                ForEach(TextLayout.ImageDisplayMode.allCases) { mode in
                    Button {
                        viewModel.textLayout.imageDisplayMode = mode
                    } label: {
                        VStack(spacing: WTSpacing.xs) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 22))
                                .frame(height: 28)
                            Text(mode.label)
                                .font(WTFont.bodyBold)
                            Text(mode.description)
                                .font(WTFont.micro)
                                .foregroundStyle(
                                    viewModel.textLayout.imageDisplayMode == mode
                                        ? Color.black.opacity(0.6)
                                        : Color.wtTextSecondary
                                )
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, WTSpacing.md)
                        .padding(.horizontal, WTSpacing.sm)
                        .background(
                            viewModel.textLayout.imageDisplayMode == mode
                                ? Color.wtPrimary
                                : Color.wtSurface2
                        )
                        .foregroundStyle(
                            viewModel.textLayout.imageDisplayMode == mode
                                ? Color.black
                                : Color.wtTextPrimary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.selectedCheckinImages.isEmpty {
                Label("请先返回上一步添加训练照片", systemImage: "info.circle")
                    .font(WTFont.micro)
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
    }

    // MARK: - 位置面板

    private var positionPanel: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {
            Text("文字位置")
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            // 位置选择器（图标按钮组）
            HStack(spacing: WTSpacing.sm) {
                ForEach(TextLayout.VerticalPosition.allCases) { position in
                    Button {
                        viewModel.textLayout.verticalPosition = position
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: positionIcon(for: position))
                                .font(.system(size: 20))
                                .frame(height: 26)
                            Text(position.label)
                                .font(WTFont.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, WTSpacing.md)
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
                    }
                    .buttonStyle(.plain)
                }
            }

            // 透明度
            HStack {
                Text("文字透明度")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                Spacer()
                Text("\(Int(viewModel.textLayout.textOpacity * 100))%")
                    .font(WTFont.bodyBold)
            }
            Slider(value: $viewModel.textLayout.textOpacity, in: 0.3 ... 1.0, step: 0.05)
                .tint(.wtPrimary)
        }
    }

    // MARK: - 辅助

    private func fontPreview(for preset: TextLayout.FontPreset) -> Font {
        switch preset {
        case .display: .system(size: 16, weight: .semibold, design: .default)
        case .rounded: .system(size: 16, weight: .semibold, design: .rounded)
        case .serif:   .system(size: 16, weight: .semibold, design: .serif)
        case .mono:    .system(size: 16, weight: .semibold, design: .monospaced)
        }
    }

    private func positionIcon(for position: TextLayout.VerticalPosition) -> String {
        switch position {
        case .top:    "arrow.up.to.line"
        case .center: "arrow.up.and.down"
        case .bottom: "arrow.down.to.line"
        }
    }

    // MARK: - 标签枚举

    private enum EditorTab: String, CaseIterable, Identifiable {
        case template
        case text
        case image
        case position

        var id: String { rawValue }

        var label: String {
            switch self {
            case .template: "模板"
            case .text:     "文字"
            case .image:    "图片"
            case .position: "位置"
            }
        }

        var icon: String {
            switch self {
            case .template: "square.grid.2x2.fill"
            case .text:     "textformat.size"
            case .image:    "photo.fill"
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
        RoundedRectangle(cornerRadius: WTRadius.lg)
            .stroke(Color.wtSurface2, lineWidth: 1)
            .frame(maxWidth: .infinity, minHeight: 120)
            .overlay {
                VStack(spacing: WTSpacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundStyle(Color.wtPrimary)
                    Text(title).font(WTFont.bodyBold)
                    Text(subtitle).font(WTFont.micro).foregroundStyle(Color.wtTextSecondary)
                }
            }
    }
}
