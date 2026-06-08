import SwiftData
import SwiftUI
import UIKit

struct HistoryListView: View {
    @Query(sort: \WODRecord.createdAt, order: .reverse) private var records: [WODRecord]
    var scrollToDate: Date? = nil
    @State private var scrollPosition: UUID?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: WTSpacing.md) {
                ForEach(records) { record in
                    NavigationLink {
                        HistoryDetailView(record: record)
                    } label: {
                        HistoryRecordCard(record: record)
                    }
                    .buttonStyle(.plain)
                    .id(record.id)
                }
            }
            .padding(WTSpacing.lg)
        }
        .scrollPosition(id: $scrollPosition)
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

private struct HistoryRecordCard: View {
    let record: WODRecord

    var body: some View {
        HStack(alignment: .top, spacing: WTSpacing.md) {
            HistoryThumbnail(record: record)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))

            VStack(alignment: .leading, spacing: WTSpacing.sm) {
                Text(record.wodDate.formatted(.dateTime.year().month().day().weekday(.wide)))
                    .font(WTFont.bodyBold)
                    .foregroundStyle(Color.wtTextPrimary)

                Text(record.wodContent.prefix(3).joined(separator: " · "))
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                    .lineLimit(3)

                HStack(spacing: WTSpacing.sm) {
                    HistoryMetaBadge(title: record.completionStatus.label, isPrimary: record.completionStatus == .completed)
                    if let difficultyRating = record.difficultyRating {
                        HistoryMetaBadge(title: "难度 \(difficultyRating)/5")
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(WTSpacing.md)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
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
