import SwiftData
import SwiftUI

// MARK: - Filter

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
    @State private var selectedFilter: SkillFilter = .all

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

    private func status(for skill: SkillDefinition) -> SkillMasteryStatus {
        statusMap[skill.id]?.status ?? .unmarked
    }

    private func count(for filter: SkillFilter) -> Int {
        let allSkills = SkillLibrary.categories.flatMap { $0.skills }
        if filter == .all { return allSkills.count }
        return allSkills.filter { filter.matches(status(for: $0)) }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wtBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: WTSpacing.md) {
                        filterBar
                        ProgressionPathsCarousel()
                        ForEach(SkillLibrary.categories) { category in
                            CategorySection(
                                category: category,
                                selectedFilter: selectedFilter,
                                statusMap: statusMap,
                                bestEntryMap: bestEntryMap
                            )
                        }
                    }
                    .padding(.vertical, WTSpacing.md)
                }
            }
            .navigationTitle("技能树")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var filterBar: some View {
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
}

// MARK: - Progression Paths Carousel

private struct ProgressionPathsCarousel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            HStack {
                Text("进阶路径")
                    .font(WTFont.micro)
                    .foregroundStyle(Color.wtTextSecondary)
                Spacer()
                Text("\(ProgressionPathLibrary.all.count) 条主线")
                    .font(WTFont.micro)
                    .foregroundStyle(Color.wtTextDisabled)
            }
            .padding(.horizontal, WTSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: WTSpacing.sm) {
                    ForEach(ProgressionPathLibrary.all) { path in
                        NavigationLink(destination: ProgressionPathDetailView(path: path)) {
                            PathCard(path: path)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, WTSpacing.lg)
            }
        }
    }
}

private struct PathCard: View {
    let path: ProgressionPath

    private var categoryColor: Color {
        SkillLibrary.categories.first { $0.id == path.categoryId }?.color ?? Color.wtTextSecondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Image(systemName: path.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(categoryColor)
                .frame(width: 36, height: 36)
                .background(categoryColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))

            Text(path.name)
                .font(WTFont.bodyBold)
                .foregroundStyle(Color.wtTextPrimary)
                .lineLimit(1)

            Text("\(path.steps.count) 个动作")
                .font(WTFont.micro)
                .foregroundStyle(Color.wtTextSecondary)
        }
        .padding(WTSpacing.md)
        .frame(width: 120)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
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

    // Skills grouped by subcategory, preserving subcategory order
    private var groupedSkills: [(subcat: SkillSubcategoryDefinition, skills: [SkillDefinition])] {
        category.subcategories.compactMap { subcat in
            let skills = displayedSkills.filter { $0.subcategoryId == subcat.id }
            return skills.isEmpty ? nil : (subcat: subcat, skills: skills)
        }
    }

    var body: some View {
        if showSection {
            VStack(alignment: .leading, spacing: 0) {
                // Header
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
            // Subcategory header
            HStack(spacing: WTSpacing.xs) {
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
                Text(skill.name)
                    .font(WTFont.bodyBold)
                    .foregroundStyle(Color.wtTextPrimary)
                Text(skill.englishName)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.wtTextSecondary)
            }

            Spacer()

            Text(skill.tier.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(skill.tier.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(skill.tier.color.opacity(0.12))
                .clipShape(Capsule())

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
