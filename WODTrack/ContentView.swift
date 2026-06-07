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
        ZStack {
            Color.wtBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: WTSpacing.lg) {
                    WTButton(title: records.isEmpty ? "开始记录" : "记录今天的 WOD", action: openRecordFlow)

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
            }
        }
        .navigationTitle("WODTrack")
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
            HStack {
                Text("训练概览")
                    .font(WTFont.title)
                Spacer()
                Text("近 12 周")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
            }

            HStack(spacing: WTSpacing.md) {
                RecordStatBlock(value: "\(streakDays)", label: "连续打卡")
                RecordStatBlock(value: "\(checkinDaysCount)", label: "累计打卡天数")
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

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            monthLabels

            GeometryReader { proxy in
                let columns = heatmapWeeks.count
                let cellSize = max(10, (proxy.size.width - CGFloat(max(columns - 1, 0)) * spacing) / CGFloat(max(columns, 1)))

                HStack(alignment: .top, spacing: spacing) {
                    ForEach(Array(heatmapWeeks.enumerated()), id: \.offset) { _, week in
                        VStack(spacing: spacing) {
                            ForEach(week) { day in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(day.didCheckIn ? Color.wtPrimary : Color.wtSurface2)
                                    .frame(width: cellSize, height: cellSize)
                                    .overlay {
                                        if Calendar.current.isDateInToday(day.date) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.white.opacity(0.75), lineWidth: 1)
                                        }
                                    }
                                    .onTapGesture {
                                        onDayTapped?(day.date)
                                    }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(height: gridHeight)
        }
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
        let uniqueDays = Set(records.map { calendar.startOfDay(for: $0.wodDate) })

        return (0 ..< 84).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return HeatmapDay(date: date, didCheckIn: uniqueDays.contains(date))
        }
    }

    private var monthLabels: some View {
        HStack(spacing: spacing) {
            ForEach(Array(heatmapWeeks.enumerated()), id: \.offset) { index, week in
                let label = monthLabel(for: week, weekIndex: index)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.wtTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var gridHeight: CGFloat {
        let rows = 7
        let weekCount = max(heatmapWeeks.count, 1)
        let availableWidth = UIScreen.main.bounds.width - (WTSpacing.lg * 2) - (WTSpacing.md * 2)
        let cellSize = max(10, (availableWidth - CGFloat(max(weekCount - 1, 0)) * spacing) / CGFloat(weekCount))
        return CGFloat(rows) * cellSize + CGFloat(rows - 1) * spacing
    }

    private func monthLabel(for week: [HeatmapDay], weekIndex: Int) -> String {
        guard let first = week.first else { return "" }
        let calendar = Calendar.current
        let month = calendar.component(.month, from: first.date)

        if weekIndex == 0 {
            return first.date.formatted(.dateTime.month(.abbreviated))
        }

        let previousMonth = heatmapWeeks[safe: weekIndex - 1].flatMap { $0.first }.map {
            calendar.component(.month, from: $0.date)
        }

        return previousMonth == month ? "" : first.date.formatted(.dateTime.month(.abbreviated))
    }
}

private struct RecordStatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.xs) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.wtPrimary)
            Text(label)
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WTSpacing.sm)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
    }
}

private struct HistoryPreviewSection: View {
    let records: [WODRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {
            HStack {
                Text("历史记录")
                    .font(WTFont.title)
                Spacer()
                NavigationLink("查看更多") {
                    HistoryListView()
                }
                .font(WTFont.caption)
                .foregroundStyle(Color.wtPrimary)
            }

            VStack(spacing: WTSpacing.sm) {
                ForEach(records) { record in
                    NavigationLink {
                        HistoryDetailView(record: record)
                    } label: {
                        HistoryPreviewRow(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct HistoryPreviewRow: View {
    let record: WODRecord

    var body: some View {
        HStack(alignment: .top, spacing: WTSpacing.md) {
            HistoryThumbnail(record: record)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))

            VStack(alignment: .leading, spacing: WTSpacing.xs) {
                Text(record.wodDate.formatted(.dateTime.month().day().weekday(.abbreviated)))
                    .font(WTFont.bodyBold)
                    .foregroundStyle(Color.wtTextPrimary)
                Text(record.wodContent.prefix(2).joined(separator: " · "))
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(record.completionStatus.label)
                .font(WTFont.micro)
                .foregroundStyle(record.completionStatus == .completed ? Color.black : Color.wtTextPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(record.completionStatus == .completed ? Color.wtPrimary : Color.wtSurface2)
                .clipShape(Capsule())
        }
        .padding(WTSpacing.md)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
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
           let cardImage = UIImage(contentsOfFile: cardImagePath) {
            return cardImage
        }

        if let firstPhotoPath = record.checkinPhotoURLs.first,
           let checkinImage = UIImage(contentsOfFile: firstPhotoPath) {
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
    let didCheckIn: Bool
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
