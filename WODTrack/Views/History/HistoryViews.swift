import SwiftData
import SwiftUI
import UIKit

struct HistoryListView: View {
    @Query(sort: \WODRecord.createdAt, order: .reverse) private var records: [WODRecord]
    var scrollToDate: Date? = nil
    @State private var scrollPosition: UUID?
    @State private var selectedMonth: String? = nil

    private var allMonthKeys: [String] {
        let calendar = Calendar.current
        let keys = Set(records.map { record -> String in
            let comps = calendar.dateComponents([.year, .month], from: record.wodDate)
            return "\(comps.year ?? 0)-\(String(format: "%02d", comps.month ?? 0))"
        })
        return keys.sorted(by: >)
    }

    private var groupedByMonth: [(key: String, records: [WODRecord])] {
        let calendar = Calendar.current
        let filtered = selectedMonth == nil ? records : records.filter { record in
            let comps = calendar.dateComponents([.year, .month], from: record.wodDate)
            let key = "\(comps.year ?? 0)-\(String(format: "%02d", comps.month ?? 0))"
            return key == selectedMonth
        }
        let grouped = Dictionary(grouping: filtered) { record -> String in
            let comps = calendar.dateComponents([.year, .month], from: record.wodDate)
            return "\(comps.year ?? 0)-\(String(format: "%02d", comps.month ?? 0))"
        }
        return grouped.keys.sorted(by: >).map { key in
            (key: key, records: grouped[key]!.sorted { $0.wodDate > $1.wodDate })
        }
    }

    private func monthLabel(from key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let date = Calendar.current.date(from: DateComponents(year: year, month: month))
        else { return key }
        return date.formatted(.dateTime.year(.twoDigits).month(.abbreviated))
    }

    private func sectionTitle(from key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let date = Calendar.current.date(from: DateComponents(year: year, month: month))
        else { return key }
        return date.formatted(.dateTime.year().month(.wide))
    }

    private var visibleCount: Int {
        groupedByMonth.reduce(0) { $0 + $1.records.count }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: WTSpacing.md) {
                ForEach(groupedByMonth, id: \.key) { group in
                    ForEach(group.records) { record in
                        NavigationLink {
                            HistoryDetailView(record: record)
                        } label: {
                            HistoryRecordCard(record: record)
                        }
                        .buttonStyle(.plain)
                        .id(record.id)
                    }
                }
            }
            .padding(WTSpacing.lg)
        }
        .scrollPosition(id: $scrollPosition)
        .background(Color.wtBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: WTSpacing.xs) {
                    Text("历史记录")
                        .font(WTFont.bodyBold)
                        .foregroundStyle(Color.wtTextPrimary)
                    Text("\(visibleCount)")
                        .font(WTFont.caption)
                        .foregroundStyle(Color.wtTextSecondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        selectedMonth = nil
                    } label: {
                        if selectedMonth == nil {
                            Label("全部", systemImage: "checkmark")
                        } else {
                            Text("全部")
                        }
                    }
                    Divider()
                    ForEach(allMonthKeys, id: \.self) { key in
                        Button {
                            selectedMonth = selectedMonth == key ? nil : key
                        } label: {
                            if selectedMonth == key {
                                Label(sectionTitle(from: key), systemImage: "checkmark")
                            } else {
                                Text(sectionTitle(from: key))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedMonth == nil ? "全部月份" : monthLabel(from: selectedMonth!))
                            .font(WTFont.caption)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selectedMonth == nil ? Color.wtTextSecondary : Color.wtPrimary)
                }
            }
        }
        .onAppear {
            guard let targetDate = scrollToDate else { return }
            let calendar = Calendar.current
            let target = calendar.startOfDay(for: targetDate)
            let match = records.first { calendar.startOfDay(for: $0.wodDate) <= target }
            scrollPosition = match?.id
        }
    }
}

struct HistoryDetailView: View {
    let record: WODRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WTSpacing.md) {
                HistoryCardPreview(record: record)

                VStack(alignment: .leading, spacing: WTSpacing.sm) {
                    Text(record.wodDate.formatted(.dateTime.year().month().day().weekday(.wide)))
                        .font(WTFont.title)

                    HStack(spacing: WTSpacing.sm) {
                        HistoryMetaBadge(title: record.completionStatus.label, isPrimary: record.completionStatus == .completed)
                        if let difficultyRating = record.difficultyRating {
                            HistoryMetaBadge(title: "难度 \(difficultyRating)/5")
                        }
                    }
                }

                if !record.checkinPhotoURLs.isEmpty {
                    VStack(alignment: .leading, spacing: WTSpacing.sm) {
                        Text("训练照片")
                            .font(WTFont.caption)
                            .foregroundStyle(Color.wtTextSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: WTSpacing.sm) {
                                ForEach(record.checkinPhotoURLs, id: \.self) { path in
                                    if let image = ImagePathResolver.loadImage(from: path) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                                    }
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: WTSpacing.sm) {
                    Text("WOD 内容")
                        .font(WTFont.caption)
                        .foregroundStyle(Color.wtTextSecondary)

                    VStack(alignment: .leading, spacing: WTSpacing.xs) {
                        ForEach(record.wodContent, id: \.self) { line in
                            Text(line)
                                .font(WTFont.body)
                                .foregroundStyle(Color.wtTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(WTSpacing.md)
                    .background(Color.wtSurface)
                    .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
                }
            }
            .padding(WTSpacing.lg)
        }
        .background(Color.wtBackground)
        .navigationTitle("记录详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HistoryCardPreview: View {
    let record: WODRecord

    var body: some View {
        GeometryReader { proxy in
            HistoryHero(record: record)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    private var aspectRatio: CGFloat {
        if let image = ImagePathResolver.loadImage(from: record.cardImagePath ?? "") {
            return image.size.width / max(image.size.height, 1)
        }
        return CardRenderer.fallbackAspectRatio
    }
}

struct HistoryRecordCard: View {
    let record: WODRecord

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: WTSpacing.md) {
            HistoryThumbnail(record: record)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))

            VStack(alignment: .leading, spacing: WTSpacing.sm) {
                HStack {
                    Text(Self.dateFormatter.string(from: record.wodDate))
                        .font(WTFont.bodyBold)
                        .foregroundStyle(Color.wtTextPrimary)
                    Spacer(minLength: 0)
                    if let rating = record.difficultyRating {
                        DifficultyStars(rating: rating)
                    }
                }

                Text(record.wodContent.prefix(2).joined(separator: "\n"))
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(WTSpacing.md)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: WTRadius.lg)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
        .shadow(color: Color.wtPrimary.opacity(0.08), radius: 10, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
    }
}

struct DifficultyStars: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< rating, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .shadow(color: .white.opacity(0.5), radius: 3, x: 0, y: 0)
            }
        }
    }
}

private struct HistoryHero: View {
    let record: WODRecord

    var body: some View {
        if let cardImage = cardImage {
            Image(uiImage: cardImage)
                .resizable()
                .scaledToFit()
        } else {
            CardView(record: record, style: CardStyleConfig.style(for: record.cardStyleId), isPro: false)
        }
    }

    private var cardImage: UIImage? {
        guard let path = record.cardImagePath else { return nil }
        return ImagePathResolver.loadImage(from: path)
    }
}

private struct HistoryMetaBadge: View {
    let title: String
    var isPrimary = false

    var body: some View {
        Text(title)
            .font(WTFont.micro)
            .foregroundStyle(isPrimary ? Color.black : Color.wtTextPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isPrimary ? Color.wtPrimary : Color.wtSurface2)
            .clipShape(Capsule())
    }
}
