import SwiftData
import SwiftUI

struct ProgressionPathDetailView: View {
    let path: ProgressionPath

    @Query private var allStatuses: [SkillStatus]

    private var statusMap: [String: SkillMasteryStatus] {
        allStatuses.indexedBySkillId.mapValues(\.status)
    }

    private var skills: [SkillDefinition] {
        path.steps.compactMap { SkillLibrary.skillById[$0] }
    }

    private var masteredCount: Int {
        skills.filter { (statusMap[$0.id] ?? .unmarked) == .mastered }.count
    }

    /// 当前站 = 第一个未掌握的动作
    private var currentIndex: Int? {
        skills.firstIndex { (statusMap[$0.id] ?? .unmarked) != .mastered }
    }

    private var progress: Double {
        skills.isEmpty ? 0 : Double(masteredCount) / Double(skills.count)
    }

    private var categoryName: String {
        SkillLibrary.categories.first { $0.id == path.categoryId }?.name ?? ""
    }

    var body: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: WTSpacing.lg) {
                    headerSection
                    stationsSection
                }
                .padding(.vertical, WTSpacing.lg)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(categoryName)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text(path.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.wtTextPrimary)

            HStack(spacing: WTSpacing.sm) {
                Text("\(masteredCount)/\(skills.count)")
                    .font(WTFont.mono(13, weight: .semibold))
                    .foregroundStyle(Color.wtTextPrimary)
                SkillProgressBar(total: skills.count, mastered: masteredCount, inProgress: 0)
                Text("\(Int((progress * 100).rounded()))%")
                    .font(WTFont.mono(11))
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
        .padding(.horizontal, WTSpacing.lg)
    }

    private var stationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(skills.enumerated()), id: \.element.id) { index, skill in
                NavigationLink(destination: SkillDetailView(skill: skill)) {
                    MetroStationRow(
                        index: index + 1,
                        skill: skill,
                        status: statusMap[skill.id] ?? .unmarked,
                        isCurrent: index == currentIndex,
                        isLast: index == skills.count - 1,
                        lineBelowActive: currentIndex.map { index < $0 } ?? true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
