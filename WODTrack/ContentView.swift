import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \WODRecord.wodDate, order: .reverse) private var records: [WODRecord]
    @State private var isShowingRecordFlow = false
    @Bindable var appState: AppState
    @Bindable var syncManager: CloudSyncManager

    // MARK: - 彩蛋：记录 tab 连点 5 次（3 秒内）触发缩略图掉落堆叠
    @State private var recordTapTimestamps: [Date] = []
    @State private var showEasterEgg = false
    private static let easterEggWindow: TimeInterval = 3
    private static let easterEggTapCount = 5

    /// 代理绑定：重复点击已选中的 tab 时 setter 仍会被调用，用此检测记录 tab 连点。
    private var tabSelection: Binding<Int> {
        Binding(
            get: { appState.selectedTab },
            set: { newValue in
                if appState.selectedTab == 1, newValue == 1, !records.isEmpty {
                    registerRecordTap()
                }
                appState.selectedTab = newValue
            }
        )
    }

    private var legalConsentPresentation: Binding<Bool> {
        Binding(
            get: { !appState.hasAcceptedLegalTerms },
            set: { _ in }
        )
    }

    private func registerRecordTap() {
        let now = Date.now
        recordTapTimestamps = recordTapTimestamps.filter {
            now.timeIntervalSince($0) < Self.easterEggWindow
        }
        recordTapTimestamps.append(now)
        if recordTapTimestamps.count >= Self.easterEggTapCount {
            recordTapTimestamps.removeAll()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showEasterEgg = true
        }
    }

    var body: some View {
        TabView(selection: tabSelection) {
            SkillTreeView()
                .tabItem { Label("技能树", systemImage: "sparkles.rectangle.stack") }
                .tag(0)

            NavigationStack {
                RecordHomeView(
                    records: records,
                    openRecordFlow: { isShowingRecordFlow = true }
                )
            }
            .tabItem { Label("记录", systemImage: "plus.app.fill") }
            .tag(1)

            NavigationStack {
                ProfileView(appState: appState, syncManager: syncManager)
            }
            .tabItem { Label("我的", systemImage: "person.crop.circle") }
            .tag(2)
        }
        .tint(.wtPrimary)
        .wtToast(message: $appState.toastMessage)
        .fullScreenCover(isPresented: legalConsentPresentation) {
            LegalConsentView(appState: appState)
                .preferredColorScheme(.dark)
                .interactiveDismissDisabled(true)
        }
        .task {
            await appState.verifyCredentialOnLaunch()
            appState.reconcileProfile(context: modelContext)
            SkillStatusSeeder.seedIfNeeded(context: modelContext)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                syncManager.sceneBecameActive(syncActive: syncManager.isSyncEnabled && appState.profile.isLoggedIn)
                appState.reconcileProfile(context: modelContext)
            }
        }
        .fullScreenCover(isPresented: $appState.showLoginPage) {
            LoginView(appState: appState)
                .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $isShowingRecordFlow) {
            RecordFlowCoordinator(
                appState: appState,
                onSaved: { record in
                    modelContext.insert(record)
                    try? modelContext.save()
                }
            )
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $showEasterEgg) {
            PhotoDropEasterEggView(
                records: records,
                onFinished: { showEasterEgg = false }
            )
            .preferredColorScheme(.dark)
        }
    }
}

private struct LegalConsentView: View {
    @Bindable var appState: AppState
    @State private var localToast: String?
    @State private var legalDocument: LegalDocument?

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(alignment: .leading, spacing: WTSpacing.lg) {
                    header
                    message
                    agreementLinks
                    actions
                }
                .padding(.horizontal, WTSpacing.lg)
                .padding(.vertical, WTSpacing.xl)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .wtToast(message: $localToast)
        .sheet(item: $legalDocument) { document in
            LegalDocumentSheet(document: document)
                .preferredColorScheme(.dark)
        }
    }

    private var background: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()
            RadialGradient(
                colors: [Color.wtPrimary.opacity(0.16), .clear],
                center: .init(x: 0.5, y: 0.08),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 17))
                .shadow(color: Color.wtPrimary.opacity(0.3), radius: 16, y: 10)

            VStack(alignment: .leading, spacing: WTSpacing.sm) {
                Text("使用前请阅读并同意")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Color.wtTextPrimary)

                Text("欢迎使用迹录 WOD")
                    .font(WTFont.body)
                    .foregroundStyle(Color.wtPrimary)
            }
        }
    }

    private var message: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {
            Text("我们会按照《用户协议》和《隐私政策》为你提供训练记录、拍照识别、历史管理、卡片生成、Apple 登录与 iCloud 同步等服务。")
            Text("使用过程中，你主动拍摄或选择的白板照片可能会发送至识别服务用于提取 WOD 内容；训练记录和个人资料会根据你的操作保存在本机，开启 iCloud 同步后会同步到你的 iCloud。")
            Text("请你确认已阅读并同意《用户协议》和《隐私政策》，再继续使用本应用。")
        }
        .font(.system(size: 15))
        .foregroundStyle(Color.wtTextSecondary)
        .lineSpacing(5)
    }

    private var agreementLinks: some View {
        HStack(spacing: WTSpacing.sm) {
            legalButton(.userAgreement)
            legalButton(.privacyPolicy)
        }
    }

    private func legalButton(_ document: LegalDocument) -> some View {
        Button {
            legalDocument = document
        } label: {
            HStack(spacing: 6) {
                Image(systemName: document.icon)
                    .font(.system(size: 13, weight: .semibold))
                Text("《\(document.title)》")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Color.wtPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(Color.wtPrimary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: WTRadius.md)
                    .stroke(Color.wtPrimary.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var actions: some View {
        VStack(spacing: WTSpacing.sm) {
            WTButton(title: "同意并继续") {
                appState.acceptLegalTerms()
            }

            WTButton(title: "暂不同意", style: .ghost) {
                localToast = "不同意将无法继续使用迹录 WOD"
            }
        }
        .padding(.top, WTSpacing.sm)
    }
}

private struct RecordHomeView: View {
    let records: [WODRecord]
    let openRecordFlow: () -> Void
    @State private var historyScrollDate: Date?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.wtBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: WTSpacing.lg) {
                    OverviewCard(
                        records: records,
                        streakDays: streakDays,
                        checkinDaysCount: checkinDaysCount,
                        onDayTapped: { date in historyScrollDate = date }
                    )

                    if records.isEmpty {
                        EmptyRecordState()
                    } else {
                        HistoryPreviewSection(records: Array(records.prefix(12)))
                    }
                }
                .padding(WTSpacing.lg)
                .padding(.bottom, 80)
            }

            Button(action: openRecordFlow) {
                HStack(spacing: WTSpacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("记录 WOD")
                        .font(WTFont.bodyBold)
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, WTSpacing.lg)
                .padding(.vertical, WTSpacing.md)
                .background(Color.wtPrimary)
                .clipShape(Capsule())
                .shadow(color: Color.wtPrimary.opacity(0.4), radius: 12, x: 0, y: 4)
            }
            .padding(.trailing, WTSpacing.lg)
            .padding(.bottom, 36)
        }
        .navigationTitle("每一次进步，都有迹可循")
        .navigationDestination(item: $historyScrollDate) { date in
            HistoryListView(scrollToDate: date)
        }
    }

    private var streakDays: Int {
        let calendar = Calendar.current
        let uniqueDays = checkinDays
        var streak = 0
        var cursor = calendar.startOfDay(for: .now)

        while uniqueDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private var checkinDaysCount: Int {
        checkinDays.count
    }

    private var checkinDays: Set<Date> {
        let calendar = Calendar.current
        return Set(records.map { calendar.startOfDay(for: $0.wodDate) })
    }
}

private struct OverviewCard: View {
    let records: [WODRecord]
    let streakDays: Int
    let checkinDaysCount: Int
    var onDayTapped: ((Date) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {

            HStack(spacing: WTSpacing.md) {
                RecordStatBlock(icon: "flame.fill", value: "\(streakDays)", label: "连续打卡")
                StatDivider()
                RecordStatBlock(icon: "calendar", value: "\(checkinDaysCount)", label: "累计打卡")
                StatDivider()
                RecordStatBlock(icon: "dumbbell.fill", value: "\(records.count)", label: "训练次数")
            }

            HeatmapGrid(records: records, onDayTapped: onDayTapped)
        }
        .padding(WTSpacing.md)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
    }
}

private struct HeatmapGrid: View {
    let records: [WODRecord]
    var onDayTapped: ((Date) -> Void)? = nil
    private let spacing: CGFloat = 6
    private let cellSize: CGFloat = 14

    var body: some View {
        let weeks = heatmapWeeks
        let lastWeekId = weeks.count - 1

        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                        VStack(spacing: spacing) {
                            Text(monthLabel(for: week, index: index, in: weeks))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.wtTextSecondary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .frame(width: cellSize, height: 12, alignment: .leading)

                            ForEach(week) { day in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(cellColor(for: day))
                                    .frame(width: cellSize, height: cellSize)
                                    .overlay {
                                        if Calendar.current.isDateInToday(day.date) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.white.opacity(0.75), lineWidth: 1)
                                        }
                                    }
                                    .onTapGesture {
                                        guard day.didCheckIn else { return }
                                        onDayTapped?(day.date)
                                    }
                            }
                        }
                        .id(index == lastWeekId ? "last-week" : nil)
                    }
                }
            }
            .onAppear {
                proxy.scrollTo("last-week", anchor: .trailing)
            }
        }
        .frame(height: CGFloat(7) * cellSize + CGFloat(7) * spacing + 12)
    }

    private var heatmapWeeks: [[HeatmapDay]] {
        let days = heatmapDays
        return stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start ..< min(start + 7, days.count)])
        }
    }

    private var heatmapDays: [HeatmapDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var countByDay: [Date: Int] = [:]
        for record in records {
            let day = calendar.startOfDay(for: record.wodDate)
            countByDay[day, default: 0] += 1
        }

        let earliestDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let totalDays = calendar.dateComponents([.day], from: earliestDate, to: today).day ?? 0
        let dayCount = max(totalDays + 1, 84)

        return (0 ..< dayCount).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return HeatmapDay(date: date, count: countByDay[date] ?? 0)
        }
    }

    private func cellColor(for day: HeatmapDay) -> Color {
        switch day.count {
        case 0: return Color.wtSurface2
        case 1: return Color.wtPrimary.opacity(0.55)
        case 2: return Color.wtPrimary.opacity(0.78)
        default: return Color.wtPrimary
        }
    }

    private func monthLabel(for week: [HeatmapDay], index: Int, in weeks: [[HeatmapDay]]) -> String {
        guard let first = week.first else { return "" }
        let calendar = Calendar.current
        let month = calendar.component(.month, from: first.date)
        if index == 0 { return first.date.formatted(.dateTime.month(.abbreviated)) }
        let prevMonth = weeks[safe: index - 1].flatMap { $0.first }.map {
            calendar.component(.month, from: $0.date)
        }
        return prevMonth == month ? "" : first.date.formatted(.dateTime.month(.abbreviated))
    }
}

private struct RecordStatBlock: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.xs) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.wtTextPrimary)
            HStack(spacing: WTSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.wtTextSecondary)
                Text(label)
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StatDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 28)
    }
}

private struct HistoryPreviewSection: View {
    let records: [WODRecord]

    /// 一屏约露 3.5 张卡片，露边提示可横滑
    private var cardWidth: CGFloat {
        (UIScreen.main.bounds.width - WTSpacing.lg * 2) / 3.5
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {
            NavigationLink(destination: HistoryListView()) {
                HStack {
                    Text("训练时刻")
                        .font(WTFont.title)
                        .foregroundStyle(Color.wtTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.wtTextSecondary)
                }
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                // 单行横滑图片流，相邻卡片轻微倾斜/错位 → 灵动
                photoRow(records, indexOffset: 0)
                    .padding(.horizontal, WTSpacing.lg)
                    // 给倾斜 + 上下错位留出溢出空间，避免被裁切
                    .padding(.vertical, 14)
            }
            // 抵消父级 lg 边距，让图片流贴近屏幕两侧、滑动时露出下一张
            .padding(.horizontal, -WTSpacing.lg)
        }
    }

    private func photoRow(_ rowRecords: [WODRecord], indexOffset: Int) -> some View {
        LazyHStack(spacing: WTSpacing.md) {
            ForEach(Array(rowRecords.enumerated()), id: \.element.id) { i, record in
                let globalIndex = indexOffset + i
                NavigationLink {
                    HistoryDetailView(record: record)
                } label: {
                    HistoryPhotoCard(record: record, width: cardWidth)
                        .rotationEffect(.degrees(HistoryPhotoCard.tilt(at: globalIndex)))
                        .offset(
                            x: HistoryPhotoCard.xOffset(at: globalIndex),
                            y: HistoryPhotoCard.yOffset(at: globalIndex)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 首页历史记录图片流卡片：统一竖图比例 + 底部信息条，灵动倾斜/错位由外层应用。
private struct HistoryPhotoCard: View {
    let record: WODRecord
    let width: CGFloat

    /// 灵动感参数（先做轻微，后续可整体调大）。
    /// 表长取 7（与每行 6 张错开），避免上下两行同列出现镜像/对齐的呆板感。
    private static let tilts: [Double] = [-2.5, 1.8, 2.4, -1.5, 2.2, -2.0, 1.2]
    private static let xOffsets: [CGFloat] = [0, 5, -4, 3, -5, 4, -2]
    private static let yOffsets: [CGFloat] = [5, -4, 6, -3, 4, -6, 3]

    static func tilt(at index: Int) -> Double { tilts[index % tilts.count] }
    static func xOffset(at index: Int) -> CGFloat { xOffsets[index % xOffsets.count] }
    static func yOffset(at index: Int) -> CGFloat { yOffsets[index % yOffsets.count] }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM.dd"
        return f
    }()

    private var difficultyEmoji: String? {
        guard let rating = record.difficultyRating else { return nil }
        return DifficultyLevel.from(stored: rating).emoji
    }

    private var height: CGFloat { width * 4 / 3 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HistoryThumbnail(record: record)
                .frame(width: width, height: height)
                .clipped()
                // 轻微去饱和，收敛色彩、避免与记录 WOD 按钮抢眼（仍保留质感）
                .saturation(0.8)

            infoBar
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        .overlay {
            // 绿色细边框，配合外发光勾出边界
            RoundedRectangle(cornerRadius: WTRadius.lg)
                .stroke(Color.wtPrimary.opacity(0.25), lineWidth: 1)
        }
        // 绿色外发光（y=0 均匀环绕勾边）+ 黑色投影做层次
        .shadow(color: Color.wtPrimary.opacity(0.3), radius: 6, x: 0, y: 0)
        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
    }

    private var infoBar: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let score = record.scoreValue, !score.isEmpty {
                Text(score)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            HStack(spacing: 4) {
                Text(Self.dateFormatter.string(from: record.wodDate))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                if let difficultyEmoji {
                    Text(difficultyEmoji)
                        .font(.system(size: 12))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, WTSpacing.sm)
        .padding(.bottom, WTSpacing.sm)
        .padding(.top, WTSpacing.lg)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct HistoryThumbnail: View {
    let record: WODRecord

    var body: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(colors: [Color.wtSurface2, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(alignment: .bottomLeading) {
                    Text(record.wodDate.formatted(.dateTime.day()))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.wtPrimary)
                        .padding(10)
                }
        }
    }

    private var image: UIImage? {
        if let cardImage = ImagePathResolver.loadCardImage(for: record) {
            return cardImage
        }

        if let firstPhotoPath = record.checkinPhotoURLs.first,
           let checkinImage = ImagePathResolver.loadImage(from: firstPhotoPath) {
            return checkinImage
        }

        return nil
    }
}

private struct EmptyRecordState: View {
    var body: some View {
        VStack(spacing: WTSpacing.sm) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(Color.wtPrimary)
            Text("今天练了什么？")
                .font(WTFont.title)
            Text("开始记录后，这里会出现你的训练概览和历史记录。")
                .font(WTFont.body)
                .foregroundStyle(Color.wtTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(WTSpacing.xl)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
    }
}

private struct HeatmapDay: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    var didCheckIn: Bool { count > 0 }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
