import SwiftData
import SwiftUI
import UIKit

struct HistoryListView: View {
    @Query(sort: \WODRecord.createdAt, order: .reverse) private var records: [WODRecord]
    var scrollToDate: Date? = nil
    @State private var scrollPosition: UUID?

    private var groupedByMonth: [(key: String, records: [WODRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record -> String in
            let comps = calendar.dateComponents([.year, .month], from: record.wodDate)
            return "\(comps.year ?? 0)-\(String(format: "%02d", comps.month ?? 0))"
        }
        return grouped.keys.sorted(by: >).map { key in
            (key: key, records: grouped[key]!.sorted { $0.wodDate > $1.wodDate })
        }
    }

    private func monthTitle(from key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let date = Calendar.current.date(from: DateComponents(year: year, month: month))
        else { return key }
        return date.formatted(.dateTime.year().month(.wide))
    }

    var body: some View {
        List {
            ForEach(groupedByMonth, id: \.key) { group in
                Section(monthTitle(from: group.key)) {
                    ForEach(group.records) { record in
                        NavigationLink {
                            HistoryDetailView(record: record)
                        } label: {
                            HistoryRecordCard(record: record)
                        }
                        .listRowBackground(Color.wtBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: WTSpacing.xs, leading: WTSpacing.lg, bottom: WTSpacing.xs, trailing: WTSpacing.lg))
                        .id(record.id)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.wtBackground)
        .navigationTitle("历史记录")
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

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            HStack {
                Text(record.wodDate.formatted(Date.FormatStyle().year().month().day()))
                    .font(WTFont.bodyBold)
                    .foregroundStyle(Color.wtPrimary)
                Spacer(minLength: 0)
                if let rating = record.difficultyRating {
                    DifficultyStars(rating: rating)
                }
            }

            HStack(alignment: .top, spacing: WTSpacing.md) {
                HistoryThumbnail(record: record)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))

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
            ForEach(1 ... 5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundStyle(i <= rating ? Color.wtPrimary : Color.wtTextSecondary.opacity(0.5))
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
