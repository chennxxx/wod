import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WODRecord.createdAt, order: .reverse) private var records: [WODRecord]
    @State private var selectedTab = 1
    @State private var isShowingRecordFlow = false
    @State private var appState = AppState()

    var body: some View {
        TabView(selection: $selectedTab) {
            SkillTreeView()
                .tabItem { Label("技能树", systemImage: "sparkles.rectangle.stack") }
                .tag(0)

            NavigationStack {
                RecordHomeView(
                    records: records,
                    openRecordFlow: { isShowingRecordFlow = true }
                )
                .navigationDestination(isPresented: $isShowingRecordFlow) {
                    RecordFlowCoordinator(
                        appState: appState,
                        onSaved: { record in
                            modelContext.insert(record)
                            try? modelContext.save()
                        }
                    )
                    .preferredColorScheme(.dark)
                }
            }
            .tabItem { Label("记录", systemImage: "plus.app.fill") }
            .tag(1)

            NavigationStack {
                ProfileView(appState: appState)
            }
            .tabItem { Label("我的", systemImage: "person.crop.circle") }
            .tag(2)
        }
        .tint(.wtPrimary)
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
                        HistoryPreviewSection(records: Array(records.prefix(7)))
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
            .padding(.bottom, WTSpacing.lg)
        }
        .navigationTitle("记录")
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
            Text("训练概览")
                .font(WTFont.title)

            HStack(spacing: WTSpacing.md) {
                RecordStatBlock(icon: "flame.fill", value: "\(streakDays)", label: "连续打卡天数")
                RecordStatBlock(icon: "calendar", value: "\(checkinDaysCount)", label: "累计打卡天数")
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
        HStack(spacing: WTSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.wtPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.wtPrimary)
                Text(label)
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(WTSpacing.sm)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
        .frame(maxWidth: .infinity)
    }
}

private struct HistoryPreviewSection: View {
    let records: [WODRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {
            NavigationLink(destination: HistoryListView()) {
                HStack {
                    Text("历史记录")
                        .font(WTFont.title)
                        .foregroundStyle(Color.wtTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.wtTextSecondary)
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: WTSpacing.md) {
                ForEach(records) { record in
                    NavigationLink {
                        HistoryDetailView(record: record)
                    } label: {
                        HistoryRecordCard(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
        if let cardImagePath = record.cardImagePath,
           let cardImage = ImagePathResolver.loadImage(from: cardImagePath) {
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
