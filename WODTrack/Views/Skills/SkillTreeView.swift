import SwiftData
import SwiftUI

// MARK: - Page Switcher

private enum SkillPage: CaseIterable {
    case actions, paths
    var label: String {
        switch self {
        case .actions: "动作"
        case .paths: "进阶路径"
        }
    }
}

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

    var icon: String? {
        switch self {
        case .all: nil
        case .mastered: "checkmark.circle.fill"
        case .inProgress: "moon.fill"
        case .wantToLearn: "circle"
        }
    }

    var iconColor: Color {
        switch self {
        case .all: .clear
        case .mastered: Color.wtPrimary
        case .inProgress: Color(hex: "#5E81F4")
        case .wantToLearn: Color.wtTextSecondary
        }
    }

    func matches(_ status: SkillMasteryStatus) -> Bool {
        switch self {
        case .all: true
        case .mastered: status == .mastered
        case .inProgress: status == .inProgress
        case .wantToLearn: status == .wantToLearn
        }
    }
}

// MARK: - Main View

struct SkillTreeView: View {
    @Query private var allStatuses: [SkillStatus]
    @Query private var allEntries: [SkillTrainingEntry]

    @State private var selectedPage: SkillPage = .actions
    @State private var selectedFilter: SkillFilter = .all
    @State private var selectedSubcategory: String? = nil
    @State private var selectedTier: SkillTier? = nil

    private var statusMap: [String: SkillStatus] {
        Dictionary(uniqueKeysWithValues: allStatuses.map { ($0.skillId, $0) })
    }

    private var bestEntryMap: [String: SkillTrainingEntry] {
        var map: [String: SkillTrainingEntry] = [:]
        for entry in allEntries {
            if let current = map[entry.skillId] {
                if entry.value > current.value { map[entry.skillId] = entry }
            } else {
                map[entry.skillId] = entry
            }
        }
        return map
    }

    // MARK: Filter helpers

    private func status(for skill: SkillDefinition) -> SkillMasteryStatus {
        statusMap[skill.id]?.status ?? .unmarked
    }

    /// 分类/难度筛选是否被激活——决定用「大类卡片」还是「扁平列表」展示
    private var isSubFiltering: Bool {
        selectedSubcategory != nil || selectedTier != nil
    }

    private func matchesSecondary(_ skill: SkillDefinition) -> Bool {
        (selectedSubcategory == nil || skill.subcategoryId == selectedSubcategory) &&
        (selectedTier == nil || skill.tier == selectedTier)
    }

    /// 状态筛选计数，受当前分类/难度约束（联动）
    private func count(for filter: SkillFilter) -> Int {
        SkillLibrary.allSkills.filter {
            matchesSecondary($0) && (filter == .all || filter.matches(status(for: $0)))
        }.count
    }

    /// 扁平模式：通过全部筛选的动作，按子类别保序分组
    private var flatGroups: [(subcat: SkillSubcategoryDefinition, skills: [SkillDefinition])] {
        let matched = SkillLibrary.allSkills.filter {
            selectedFilter.matches(status(for: $0)) && matchesSecondary($0)
        }
        return SkillLibrary.categories.flatMap { $0.subcategories }.compactMap { sub in
            let skills = matched.filter { $0.subcategoryId == sub.id }
            return skills.isEmpty ? nil : (subcat: sub, skills: skills)
        }
    }

    private func categoryColor(forSub subId: String) -> Color {
        for category in SkillLibrary.categories where category.subcategories.contains(where: { $0.id == subId }) {
            return category.color
        }
        return Color.wtTextSecondary
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: WTSpacing.md) {
                    Picker("视图", selection: $selectedPage.animation(.easeInOut(duration: 0.2))) {
                        ForEach(SkillPage.allCases, id: \.self) { page in
                            Text(page.label).tag(page)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, WTSpacing.lg)
                    .padding(.top, WTSpacing.xs)

                    switch selectedPage {
                    case .actions: actionsContent
                    case .paths:   pathsContent
                    }
                }
                .padding(.bottom, WTSpacing.md)
            }
            .background(Color.wtBackground)
            .navigationTitle("技能树")
        }
    }

    // MARK: Actions Content

    @ViewBuilder private var actionsContent: some View {
        VStack(spacing: WTSpacing.sm) {
            statusFilterBar
            secondaryFilters
        }

        if isSubFiltering {
            flatSkillList
        } else {
            ForEach(SkillLibrary.categories) { category in
                CategorySection(
                    category: category,
                    selectedFilter: selectedFilter,
                    statusMap: statusMap,
                    bestEntryMap: bestEntryMap
                )
            }
        }
    }

    private var statusFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: WTSpacing.sm) {
                ForEach(SkillFilter.allCases, id: \.self) { filter in
                    let n = count(for: filter)
                    let isSelected = selectedFilter == filter
                    Button {
                        selectedFilter = filter
                    } label: {
                        HStack(spacing: 5) {
                            if let icon = filter.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(isSelected ? Color.black : filter.iconColor)
                            }
                            Text("\(filter.label) \(n)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isSelected ? Color.black : Color.wtTextSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.wtPrimary : Color.wtSurface)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, WTSpacing.lg)
        }
    }

    // MARK: Secondary Filters (分类 + 难度)

    private var secondaryFilters: some View {
        VStack(spacing: WTSpacing.sm) {
            // 分类
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: WTSpacing.sm) {
                    SecondaryChip(label: "全部分类", dotColor: nil, isSelected: selectedSubcategory == nil) {
                        selectedSubcategory = nil
                    }
                    ForEach(SkillLibrary.categories) { category in
                        ForEach(category.subcategories) { sub in
                            SecondaryChip(label: sub.name, dotColor: category.color,
                                          isSelected: selectedSubcategory == sub.id) {
                                selectedSubcategory = selectedSubcategory == sub.id ? nil : sub.id
                            }
                        }
                    }
                }
                .padding(.horizontal, WTSpacing.lg)
            }

            // 难度
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: WTSpacing.sm) {
                    SecondaryChip(label: "全部难度", dotColor: nil, isSelected: selectedTier == nil) {
                        selectedTier = nil
                    }
                    ForEach(SkillTier.allCases) { tier in
                        SecondaryChip(label: "\(tier.label) · \(tier.description)", dotColor: tier.color,
                                      isSelected: selectedTier == tier) {
                            selectedTier = selectedTier == tier ? nil : tier
                        }
                    }
                }
                .padding(.horizontal, WTSpacing.lg)
            }
        }
    }

    private var flatSkillList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if flatGroups.isEmpty {
                Text("没有符合条件的动作")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, WTSpacing.xl)
            } else {
                ForEach(flatGroups, id: \.subcat.id) { group in
                    SubcategoryGroup(
                        subcat: group.subcat,
                        skills: group.skills,
                        categoryColor: categoryColor(forSub: group.subcat.id),
                        statusMap: statusMap,
                        bestEntryMap: bestEntryMap
                    )
                }
            }
        }
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        .padding(.horizontal, WTSpacing.lg)
    }

    // MARK: Paths Content

    @ViewBuilder private var pathsContent: some View {
        ForEach(SkillLibrary.categories) { category in
            let paths = ProgressionPathLibrary.all.filter { $0.categoryId == category.id }
            if !paths.isEmpty {
                VStack(alignment: .leading, spacing: WTSpacing.sm) {
                    HStack(spacing: WTSpacing.xs) {
                        Image(systemName: category.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(category.color)
                        Text("\(category.name) · \(paths.count) 条主线")
                            .font(WTFont.micro)
                            .foregroundStyle(Color.wtTextSecondary)
                    }
                    .padding(.horizontal, WTSpacing.lg)
                    .padding(.top, WTSpacing.sm)

                    VStack(spacing: WTSpacing.sm) {
                        ForEach(paths) { path in
                            NavigationLink(destination: ProgressionPathDetailView(path: path)) {
                                PathRowCard(path: path, color: category.color, statusMap: statusMap)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, WTSpacing.lg)
                }
            }
        }
    }
}

// MARK: - Secondary Chip

private struct SecondaryChip: View {
    let label: String
    let dotColor: Color?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let dotColor {
                    Circle()
                        .fill(isSelected ? Color.black : dotColor)
                        .frame(width: 6, height: 6)
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? Color.black : Color.wtTextSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.wtPrimary : Color.wtSurface)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Path Row Card

private struct PathRowCard: View {
    let path: ProgressionPath
    let color: Color
    let statusMap: [String: SkillStatus]

    private var progress: (mastered: Int, inProgress: Int, total: Int) {
        let skills = path.steps.compactMap { SkillLibrary.skillById[$0] }
        let m = skills.filter { statusMap[$0.id]?.status == .mastered }.count
        let ip = skills.filter { statusMap[$0.id]?.status == .inProgress }.count
        return (m, ip, skills.count)
    }

    var body: some View {
        HStack(spacing: WTSpacing.md) {
            Image(systemName: path.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(path.name)
                        .font(WTFont.bodyBold)
                        .foregroundStyle(Color.wtTextPrimary)
                    Spacer()
                    Text("\(progress.mastered)/\(progress.total)")
                        .font(WTFont.caption)
                        .foregroundStyle(Color.wtTextSecondary)
                }
                ProgressBar(total: progress.total, mastered: progress.mastered, inProgress: progress.inProgress)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.wtTextDisabled)
        }
        .padding(WTSpacing.md)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
    }
}

// MARK: - Category Section

private struct CategorySection: View {
    let category: SkillCategoryDefinition
    let selectedFilter: SkillFilter
    let statusMap: [String: SkillStatus]
    let bestEntryMap: [String: SkillTrainingEntry]

    @State private var isExpanded = true

    private func statusFor(_ skill: SkillDefinition) -> SkillMasteryStatus {
        statusMap[skill.id]?.status ?? .unmarked
    }

    private var filteredSkills: [SkillDefinition] {
        category.skills.filter { selectedFilter.matches(statusFor($0)) }
    }

    private var masteredCount: Int { category.skills.filter { statusFor($0) == .mastered }.count }
    private var inProgressCount: Int { category.skills.filter { statusFor($0) == .inProgress }.count }
    private var displayedSkills: [SkillDefinition] { selectedFilter == .all ? category.skills : filteredSkills }
    private var showSection: Bool { selectedFilter == .all || !filteredSkills.isEmpty }

    private var groupedSkills: [(subcat: SkillSubcategoryDefinition, skills: [SkillDefinition])] {
        category.subcategories.compactMap { subcat in
            let skills = displayedSkills.filter { $0.subcategoryId == subcat.id }
            return skills.isEmpty ? nil : (subcat: subcat, skills: skills)
        }
    }

    var body: some View {
        if showSection {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    VStack(alignment: .leading, spacing: WTSpacing.sm) {
                        HStack(spacing: WTSpacing.sm) {
                            Image(systemName: category.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(category.color)
                                .frame(width: 36, height: 36)
                                .background(category.color.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.name)
                                    .font(WTFont.bodyBold)
                                    .foregroundStyle(Color.wtTextPrimary)
                                Text(category.englishName)
                                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Color.wtTextSecondary)
                            }

                            Spacer()

                            Text("\(masteredCount)/\(category.skills.count)")
                                .font(WTFont.caption)
                                .foregroundStyle(Color.wtTextSecondary)

                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.wtTextSecondary)
                        }

                        ProgressBar(total: category.skills.count, mastered: masteredCount, inProgress: inProgressCount)
                    }
                    .padding(WTSpacing.md)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider().background(Color.wtSurface2)

                    ForEach(groupedSkills, id: \.subcat.id) { group in
                        SubcategoryGroup(
                            subcat: group.subcat,
                            skills: group.skills,
                            categoryColor: category.color,
                            statusMap: statusMap,
                            bestEntryMap: bestEntryMap
                        )
                    }
                    .padding(.bottom, WTSpacing.xs)
                }
            }
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
            .padding(.horizontal, WTSpacing.lg)
        }
    }
}

// MARK: - Subcategory Group

private struct SubcategoryGroup: View {
    let subcat: SkillSubcategoryDefinition
    let skills: [SkillDefinition]
    let categoryColor: Color
    let statusMap: [String: SkillStatus]
    let bestEntryMap: [String: SkillTrainingEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: WTSpacing.xs) {
                Circle().fill(categoryColor).frame(width: 6, height: 6)
                Text(subcat.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(categoryColor)
                Text("·")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtTextDisabled)
                Text("\(skills.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wtTextDisabled)
            }
            .padding(.horizontal, WTSpacing.md)
            .padding(.top, WTSpacing.sm)
            .padding(.bottom, WTSpacing.xs)

            ForEach(Array(skills.enumerated()), id: \.element.id) { index, skill in
                NavigationLink(destination: SkillDetailView(skill: skill)) {
                    SkillRow(skill: skill, statusEntry: statusMap[skill.id], bestEntry: bestEntryMap[skill.id])
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if index < skills.count - 1 {
                    Divider()
                        .background(Color.wtSurface2)
                        .padding(.leading, WTSpacing.md)
                }
            }

            Divider().background(Color.wtSurface2)
        }
    }
}

// MARK: - Progress Bar

private struct ProgressBar: View {
    let total: Int
    let mastered: Int
    let inProgress: Int

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let masteredW = total > 0 ? w * CGFloat(mastered) / CGFloat(total) : 0
            let inProgressW = total > 0 ? w * CGFloat(inProgress) / CGFloat(total) : 0
            HStack(spacing: 2) {
                if masteredW > 0 {
                    RoundedRectangle(cornerRadius: 2).fill(Color.wtPrimary).frame(width: masteredW)
                }
                if inProgressW > 0 {
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#5E81F4")).frame(width: inProgressW)
                }
                Spacer(minLength: 0)
                    .frame(maxWidth: .infinity)
                    .background(Color.wtSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Skill Row

private struct SkillRow: View {
    let skill: SkillDefinition
    let statusEntry: SkillStatus?
    let bestEntry: SkillTrainingEntry?

    private var masteryStatus: SkillMasteryStatus { statusEntry?.status ?? .unmarked }

    private var statusIcon: (name: String, color: Color) {
        switch masteryStatus {
        case .mastered:    ("checkmark.circle.fill", Color.wtPrimary)
        case .inProgress:  ("moon.fill",             Color(hex: "#5E81F4"))
        case .wantToLearn: ("circle",                Color.wtTextSecondary)
        case .unmarked:    ("circle",                Color.wtTextDisabled)
        }
    }

    var body: some View {
        HStack(spacing: WTSpacing.sm) {
            Image(systemName: statusIcon.name)
                .font(.system(size: 20))
                .foregroundStyle(statusIcon.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    TierBadge(tier: skill.tier)
                    Text(skill.name)
                        .font(WTFont.bodyBold)
                        .foregroundStyle(Color.wtTextPrimary)
                }
                Text(skill.englishName)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.wtTextSecondary)
            }

            Spacer()

            // 右侧预留：个人 RPT 数据
            if let entry = bestEntry {
                Text(entry.formattedValue)
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.wtTextDisabled)
        }
        .padding(.horizontal, WTSpacing.md)
        .padding(.vertical, 12)
    }
}

// MARK: - Tier Badge

struct TierBadge: View {
    let tier: SkillTier

    var body: some View {
        Text(tier.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(tier.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tier.color.opacity(0.12))
            .clipShape(Capsule())
    }
}
