import SwiftData
import SwiftUI

// MARK: - Status Filter

private enum SkillFilter: CaseIterable {
    case all, mastered, inProgress, wantToLearn

    var label: String {
        switch self {
        case .all: "全部"
        case .mastered: "已掌握"
        case .inProgress: "进行中"
        case .wantToLearn: "想学"
        }
    }

    var status: SkillMasteryStatus? {
        switch self {
        case .all: nil
        case .mastered: .mastered
        case .inProgress: .inProgress
        case .wantToLearn: .wantToLearn
        }
    }

    func matches(_ status: SkillMasteryStatus) -> Bool {
        switch self {
        case .all: true
        default: self.status == status
        }
    }
}

private extension SkillTier {
    var order: Int {
        switch self {
        case .l1: 1
        case .l2: 2
        case .l3: 3
        case .l4: 4
        case .l5: 5
        }
    }
}

// MARK: - 动作浏览页（独立 push 页面：原生返回 + 筛选 + 扁平列表，不按二级分类分组）

struct SkillBrowseView: View {
    /// 限定大类（从分类卡进入）。nil = 全部大类。
    let category: SkillCategoryDefinition?

    @Query private var allStatuses: [SkillStatus]

    @State private var selectedFilter: SkillFilter = .all
    @State private var selectedTier: SkillTier? = nil
    @State private var searchText: String = ""

    private var scopeSkills: [SkillDefinition] {
        category?.skills ?? SkillLibrary.allSkills
    }

    private var statusMap: [String: SkillStatus] { allStatuses.indexedBySkillId }

    private func status(for skill: SkillDefinition) -> SkillMasteryStatus {
        statusMap[skill.id]?.status ?? .unmarked
    }

    /// 中文名或英文名命中搜索词（去空格、忽略大小写）。空搜索词视为全部命中。
    private func matchesSearch(_ skill: SkillDefinition) -> Bool {
        let term = searchText.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return true }
        return skill.name.localizedCaseInsensitiveContains(term)
            || skill.englishName.localizedCaseInsensitiveContains(term)
    }

    private func count(for filter: SkillFilter) -> Int {
        scopeSkills.filter {
            (selectedTier == nil || $0.tier == selectedTier) &&
            matchesSearch($0) &&
            (filter == .all || filter.matches(status(for: $0)))
        }.count
    }

    /// 通过筛选 + 搜索的动作，按难度升序排列（同难度保持原顺序）。
    private var skills: [SkillDefinition] {
        scopeSkills
            .filter {
                selectedFilter.matches(status(for: $0)) &&
                (selectedTier == nil || $0.tier == selectedTier) &&
                matchesSearch($0)
            }
            .enumerated()
            .sorted { ($0.element.tier.order, $0.offset) < ($1.element.tier.order, $1.offset) }
            .map { $0.element }
    }

    var body: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: WTSpacing.md) {
                    filters
                        .padding(.top, WTSpacing.sm)

                    list
                }
                .padding(.bottom, WTSpacing.xl)
            }
        }
        .navigationTitle(category?.name ?? "全部动作")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索动作名称")
    }

    // MARK: 筛选（状态 + 难度）

    private var filters: some View {
        VStack(spacing: WTSpacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: WTSpacing.sm) {
                    ForEach(SkillFilter.allCases, id: \.self) { filter in
                        let n = count(for: filter)
                        let isSelected = selectedFilter == filter
                        Button { selectedFilter = filter } label: {
                            HStack(spacing: 5) {
                                if let status = filter.status {
                                    StatusGlyph(status: status, size: 13)
                                        .foregroundStyle(isSelected ? Color.wtPrimary : status.accentColor)
                                }
                                Text("\(filter.label) \(n)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(isSelected ? Color.wtPrimary : Color.wtTextSecondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .selectablePill(isOn: isSelected)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, WTSpacing.lg)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: WTSpacing.sm) {
                    chip("全部难度", isSelected: selectedTier == nil) { selectedTier = nil }
                    ForEach(SkillTier.allCases) { tier in
                        chip("\(tier.label) · \(tier.description)", isSelected: selectedTier == tier) {
                            selectedTier = selectedTier == tier ? nil : tier
                        }
                    }
                }
                .padding(.horizontal, WTSpacing.lg)
            }
        }
    }

    private func chip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? Color.wtPrimary : Color.wtTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .selectablePill(isOn: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: 扁平列表

    private var list: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            VStack(spacing: 0) {
                if skills.isEmpty {
                    Text(searchText.isEmpty ? "没有符合条件的动作" : "没有匹配“\(searchText)”的动作")
                        .font(WTFont.body)
                        .foregroundStyle(Color.wtTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, WTSpacing.xl)
                } else {
                    ForEach(Array(skills.enumerated()), id: \.element.id) { index, skill in
                        NavigationLink(destination: SkillDetailView(skill: skill)) {
                            SkillStatusRow(skill: skill, status: status(for: skill))
                        }
                        .buttonStyle(.plain)
                        if index < skills.count - 1 {
                            Divider().background(Color.wtSurface2).padding(.leading, WTSpacing.md)
                        }
                    }
                }
            }
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
            .padding(.horizontal, WTSpacing.lg)

            if !skills.isEmpty {
                Text("共 \(skills.count) 个")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.wtTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, WTSpacing.lg)
            }
        }
    }
}
