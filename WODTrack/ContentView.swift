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
                VStack(alignment: .leading, spacing: WTSpacing.xs) {
                    monthLabels(for: weeks)

                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
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
                            .id(index == lastWeekId ? "last-week" : nil)
                        }
                    }
                }
            }
            .onAppear {
                proxy.scrollTo("last-week", anchor: .trailing)
            }
        }
        .frame(height: CGFloat(7) * cellSize + CGFloat(6) * spacing + WTSpacing.xs + 14)
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

        let earliestDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let totalDays = calendar.dateComponents([.day], from: earliestDate, to: today).day ?? 0
        let dayCount = max(totalDays + 1, 84)

        return (0 ..< dayCount).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return HeatmapDay(date: date, didCheckIn: uniqueDays.contains(date))
        }
    }

    private func monthLabels(for weeks: [[HeatmapDay]]) -> some View {
        HStack(spacing: spacing) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                let label: String = {
                    guard let first = week.first else { return "" }
                    let calendar = Calendar.current
                    let month = calendar.component(.month, from: first.date)
                    if index == 0 { return first.date.formatted(.dateTime.month(.abbreviated)) }
                    let prevMonth = weeks[safe: index - 1].flatMap { $0.first }.map {
                        calendar.component(.month, from: $0.date)
                    }
                    return prevMonth == month ? "" : first.date.formatted(.dateTime.month(.abbreviated))
                }()
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.wtTextSecondary)
                    .lineLimit(1)
                    .frame(width: cellSize, alignment: .leading)
            }
        }
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
    let didCheckIn: Bool
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
