import SwiftData
import SwiftUI
import UIKit

struct HistoryListView: View {
    @Query(sort: \WODRecord.wodDate, order: .reverse) private var records: [WODRecord]
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

    /// 应用月份筛选后的记录（已按 wodDate 降序，来自 @Query）
    private var filteredRecords: [WODRecord] {
        guard let selectedMonth else { return records }
        let calendar = Calendar.current
        return records.filter { record in
            let comps = calendar.dateComponents([.year, .month], from: record.wodDate)
            let key = "\(comps.year ?? 0)-\(String(format: "%02d", comps.month ?? 0))"
            return key == selectedMonth
        }
    }

    /// 按年份分组（年份大标题），组内按 wodDate 降序
    private var groupedByYear: [(year: Int, records: [WODRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredRecords) { record in
            calendar.component(.year, from: record.wodDate)
        }
        return grouped.keys.sorted(by: >).map { year in
            (year: year, records: grouped[year]!.sorted { $0.wodDate > $1.wodDate })
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
        filteredRecords.count
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(groupedByYear, id: \.year) { group in
                    TimelineRailRow(dotProminent: true, dotTopPadding: WTSpacing.sm) {
                        Text("\(String(group.year)) 年")
                            .font(WTFont.title)
                            .foregroundStyle(Color.wtTextPrimary)
                            .padding(.vertical, WTSpacing.sm)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: WTSpacing.lg, bottom: 0, trailing: WTSpacing.lg))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    ForEach(group.records) { record in
                        TimelineRailRow(dotProminent: false, dotTopPadding: WTSpacing.md + 4) {
                            HistoryTimelineRow(record: record)
                        }
                        .background {
                            NavigationLink("") {
                                HistoryDetailView(record: record)
                            }
                            .opacity(0)
                        }
                        .id(record.id)
                        .listRowInsets(EdgeInsets(top: 0, leading: WTSpacing.lg, bottom: 0, trailing: WTSpacing.lg))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
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
            .contentMargins(.bottom, 80, for: .scrollContent)
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
            VStack(alignment: .leading, spacing: WTSpacing.lg) {
                headerBlock

                HistoryCardPreview(record: record)
                    .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)

                statStrip

                if !record.wodContent.isEmpty {
                    wodContentCard
                }

                if let note = record.note, !note.isEmpty {
                    detailTextCard(title: "备注", text: note)
                }

                checkinFootnote

                VStack(spacing: WTSpacing.sm) {
                    saveImageButton
                    deleteButton
                }
                .padding(.top, WTSpacing.sm)
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

    // MARK: - 头部

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: WTSpacing.xs) {
            Text(record.wodDate.formatted(.dateTime.year().month().day()))
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.wtTextPrimary)
            Text(record.wodDate.formatted(.dateTime.weekday(.wide)))
                .font(WTFont.body)
                .foregroundStyle(Color.wtTextSecondary)
        }
    }

    /// WOD 类型展示名（For Time / AMRAP …），无类型返回 nil
    private var wodTypeName: String? {
        guard let raw = record.scoreType, let type = WODType(rawValue: raw) else { return nil }
        return type.displayName
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

    // MARK: - 数据概览（成绩 / 强度 / 用时）

    private var statStrip: some View {
        let cells = statCells
        return Group {
            if !cells.isEmpty {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading),
                    ],
                    spacing: WTSpacing.md
                ) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                        cell
                    }
                }
                .padding(WTSpacing.md)
                .background(Color.wtSurface)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
            }
        }
    }

    /// 概览 2×2：成绩 / 类型 / 标准(RX·SC) / 强度（缺项不展示）
    private var statCells: [AnyView] {
        var cells: [AnyView] = []

        if let value = record.scoreValue, !value.isEmpty {
            cells.append(AnyView(StatCell(label: "成绩") {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.wtTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }))
        }

        if let type = wodTypeName {
            cells.append(AnyView(StatCell(label: "类型") {
                Text(type)
                    .font(WTFont.bodyBold)
                    .foregroundStyle(Color.wtTextPrimary)
            }))
        }

        if let scaling = scalingLabel {
            cells.append(AnyView(StatCell(label: "标准") {
                Text(scaling)
                    .font(WTFont.bodyBold)
                    .foregroundStyle(Color.wtTextPrimary)
            }))
        }

        if let rating = record.difficultyRating {
            let level = DifficultyLevel.from(stored: rating)
            cells.append(AnyView(StatCell(label: "强度") {
                HStack(spacing: 4) {
                    Text(level.emoji)
                        .font(.system(size: 16))
                    Text(level.label)
                        .font(WTFont.bodyBold)
                        .foregroundStyle(Color.wtTextPrimary)
                }
            }))
        }

        return cells
    }

    /// RX / SC 标签（无标记返回 nil）
    private var scalingLabel: String? {
        guard let raw = record.scoreScaling else { return nil }
        return ScoreScaling(rawValue: raw)?.label
    }

    // MARK: - 内容卡片

    private var wodContentCard: some View {
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

    private func detailTextCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text(title)
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            Text(text)
                .font(WTFont.body)
                .foregroundStyle(Color.wtTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(WTSpacing.md)
                .background(Color.wtSurface)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        }
    }

    private var checkinFootnote: some View {
        Text("打卡于 \(record.createdAt.formatted(date: .abbreviated, time: .shortened))")
            .font(WTFont.micro)
            .foregroundStyle(Color.wtTextSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
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
    }
}

/// 详情页数据概览的单格：上方小标签、下方数值（左对齐，用于 2×2 网格）
private struct StatCell<Value: View>: View {
    let label: String
    @ViewBuilder var value: Value

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.xs) {
            Text(label)
                .font(WTFont.micro)
                .foregroundStyle(Color.wtTextSecondary)
            value
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HistoryCardPreview: View {
    let record: WODRecord
    /// 竖屏图片限高，避免占据过多屏幕；横屏图片仍按宽度铺满
    var maxHeight: CGFloat = 420

    var body: some View {
        HistoryHero(record: record)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .frame(maxHeight: maxHeight)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var aspectRatio: CGFloat {
        if let image = ImagePathResolver.loadCardImage(for: record) {
            return image.size.width / max(image.size.height, 1)
        }
        return CardRenderer.fallbackAspectRatio
    }
}

/// 时间线轨道行：左侧连续竖线 + 圆点，右侧任意内容。
/// 行间 spacing 设 0、靠内容自身 padding 撑高 → 竖线连续不断。
private struct TimelineRailRow<Content: View>: View {
    var dotProminent: Bool
    var dotTopPadding: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: WTSpacing.sm) {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Color.wtSurface2)
                    .frame(width: 2)
                Circle()
                    .fill(Color.wtPrimary)
                    .frame(width: dotProminent ? 12 : 9, height: dotProminent ? 12 : 9)
                    .overlay(Circle().stroke(Color.wtBackground, lineWidth: 2))
                    .padding(.top, dotTopPadding)
            }
            .frame(width: 14)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// 时间线单条记录：日期/星期 + 缩略图 + 成绩/RX·SC/难度
struct HistoryTimelineRow: View {
    let record: WODRecord

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM-dd"
        return f
    }()

    private var weekday: String {
        record.wodDate.formatted(.dateTime.weekday(.wide))
    }

    private var hasMeta: Bool {
        (record.scoreValue?.isEmpty == false) || record.difficultyRating != nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: WTSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dateFormatter.string(from: record.wodDate))
                    .font(WTFont.bodyBold)
                    .foregroundStyle(Color.wtTextPrimary)
                Text(weekday)
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
            }
            .frame(width: 52, alignment: .leading)

            HistoryThumbnail(record: record)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))

            VStack(alignment: .leading, spacing: WTSpacing.xs) {
                // 第一行：难度 emoji + 成绩
                if hasMeta {
                    HStack(spacing: WTSpacing.xs) {
                        if let rating = record.difficultyRating {
                            Text(DifficultyLevel.from(stored: rating).emoji)
                                .font(.system(size: 15))
                        }
                        if let score = record.scoreValue, !score.isEmpty {
                            Text(score)
                                .font(WTFont.bodyBold)
                                .foregroundStyle(Color.wtTextPrimary)
                                .lineLimit(1)
                        }
                    }
                }

                // WOD 内容（两行）
                if !record.wodContent.isEmpty {
                    Text(record.wodContent.prefix(2).joined(separator: "\n"))
                        .font(WTFont.caption)
                        .foregroundStyle(Color.wtTextSecondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, WTSpacing.md)
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
