import SwiftData
import SwiftUI
import UIKit

struct HistoryListView: View {
    @Query(sort: \WODRecord.createdAt, order: .reverse) private var records: [WODRecord]
    @Environment(\.modelContext) private var modelContext
    var scrollToDate: Date? = nil
    @State private var selectedMonth: String? = nil
    @State private var recordPendingDelete: WODRecord?
    @State private var showDeleteConfirm = false

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
        ScrollViewReader { proxy in
            List {
                ForEach(groupedByMonth, id: \.key) { group in
                    ForEach(group.records) { record in
                        HistoryRecordCard(record: record)
                            .background {
                                NavigationLink("") {
                                    HistoryDetailView(record: record)
                                }
                                .opacity(0)
                            }
                            .id(record.id)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: WTSpacing.md / 2,
                                leading: WTSpacing.lg,
                                bottom: WTSpacing.md / 2,
                                trailing: WTSpacing.lg
                            ))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    recordPendingDelete = record
                                    showDeleteConfirm = true
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .tint(Color.wtDanger)
                            }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.vertical, WTSpacing.md / 2, for: .scrollContent)
            .onAppear {
                guard let targetDate = scrollToDate else { return }
                let calendar = Calendar.current
                let target = calendar.startOfDay(for: targetDate)
                guard let match = records.first(where: { calendar.startOfDay(for: $0.wodDate) <= target }) else { return }
                DispatchQueue.main.async {
                    proxy.scrollTo(match.id, anchor: .top)
                }
            }
        }
        .background(Color.wtBackground)
        .alert("删除这条记录", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive) {
                if let record = recordPendingDelete {
                    RecordDeletionService.delete(record, context: modelContext)
                }
                recordPendingDelete = nil
            }
            Button("取消", role: .cancel) {
                recordPendingDelete = nil
            }
        } message: {
            Text("记录删除后，训练记录和图片将从本机删除，不可恢复")
        }
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
    }
}

struct HistoryDetailView: View {
    let record: WODRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var saveState: SaveState = .idle
    @State private var showDeleteConfirm = false

    private enum SaveState {
        case idle, saving, saved, failed
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WTSpacing.md) {
                HistoryCardPreview(record: record)

                saveImageButton

                infoSection

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

                deleteButton
            }
            .padding(WTSpacing.lg)
        }
        .background(Color.wtBackground)
        .navigationTitle("记录详情")
        .navigationBarTitleDisplayMode(.inline)
        .alert("删除这条记录", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive) {
                RecordDeletionService.delete(record, context: modelContext)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("记录删除后，训练记录和图片将从本机删除，不可恢复")
        }
    }

    // MARK: - 保存图片

    private var saveImageButton: some View {
        Button(action: saveCardImage) {
            HStack(spacing: WTSpacing.xs) {
                Image(systemName: saveState == .saved ? "checkmark" : "square.and.arrow.down")
                Text(saveButtonTitle)
            }
            .font(WTFont.bodyBold)
            .foregroundStyle(saveState == .saved ? Color.black : Color.wtTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, WTSpacing.md)
            .background(saveState == .saved ? Color.wtPrimary : Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        }
        .buttonStyle(.plain)
        .disabled(saveState == .saving)
    }

    private var saveButtonTitle: String {
        switch saveState {
        case .idle: "保存图片到相册"
        case .saving: "保存中…"
        case .saved: "已保存"
        case .failed: "保存失败"
        }
    }

    private func saveCardImage() {
        guard saveState == .idle || saveState == .failed else { return }
        saveState = .saving
        Task { @MainActor in
            guard let image = await loadOrRenderCardImage() else {
                finishSave(success: false)
                return
            }
            PhotoLibraryService.save(image) { success in
                finishSave(success: success)
            }
        }
    }

    @MainActor
    private func loadOrRenderCardImage() async -> UIImage? {
        if let image = ImagePathResolver.loadCardImage(for: record) {
            return image
        }
        let checkinImages = record.checkinPhotoURLs.compactMap { ImagePathResolver.loadImage(from: $0) }
        return try? await CardRenderer.render(
            record: record,
            style: CardStyleConfig.style(for: record.cardStyleId),
            isPro: false,
            checkinImages: checkinImages
        )
    }

    private func finishSave(success: Bool) {
        saveState = success ? .saved : .failed
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if saveState != .saving {
                saveState = .idle
            }
        }
    }

    // MARK: - 信息区

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text(record.wodDate.formatted(.dateTime.year().month().day().weekday(.wide)))
                .font(WTFont.title)
                .foregroundStyle(Color.wtTextPrimary)

            VStack(spacing: 0) {
                if let rating = record.difficultyRating {
                    HistoryInfoRow(label: "难度") {
                        DifficultyStars(rating: rating)
                    }
                }
                if let minutes = record.completionMinutes {
                    HistoryInfoRow(label: "训练用时") {
                        Text("\(minutes) 分钟")
                            .font(WTFont.body)
                            .foregroundStyle(Color.wtTextPrimary)
                    }
                }
                HistoryInfoRow(label: "打卡时间") {
                    Text(record.createdAt.formatted(date: .numeric, time: .shortened))
                        .font(WTFont.body)
                        .foregroundStyle(Color.wtTextPrimary)
                }
            }
            .padding(.horizontal, WTSpacing.md)
            .padding(.vertical, WTSpacing.xs)
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        }
    }

    // MARK: - 删除

    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            HStack(spacing: WTSpacing.xs) {
                Image(systemName: "trash")
                Text("删除记录")
            }
            .font(WTFont.bodyBold)
            .foregroundStyle(Color.wtDanger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, WTSpacing.md)
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        }
        .buttonStyle(.plain)
        .padding(.top, WTSpacing.sm)
    }
}

private struct HistoryInfoRow<Value: View>: View {
    let label: String
    @ViewBuilder var value: Value

    var body: some View {
        HStack {
            Text(label)
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)
            Spacer(minLength: WTSpacing.md)
            value
        }
        .padding(.vertical, WTSpacing.sm)
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
        if let image = ImagePathResolver.loadCardImage(for: record) {
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
        ImagePathResolver.loadCardImage(for: record)
    }
}
