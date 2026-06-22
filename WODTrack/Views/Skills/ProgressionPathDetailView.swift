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

    /// 当前站 = 第一个未掌握的动作。后续站点（前一站未掌握）视为未解锁。
    private var currentIndex: Int? {
        skills.firstIndex { (statusMap[$0.id] ?? .unmarked) != .mastered }
    }

    /// 顺序解锁：当前站之后、且本站尚未标记的站点视为未解锁。
    /// 若用户已独立标记（已掌握/进行中/想学），即便顺序靠后也按真实状态展示，不加锁。
    private func isLocked(_ index: Int) -> Bool {
        guard let current = currentIndex, index > current else { return false }
        return (statusMap[skills[index].id] ?? .unmarked) == .unmarked
    }

    private var progress: Double {
        skills.isEmpty ? 0 : Double(masteredCount) / Double(skills.count)
    }

    var body: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: WTSpacing.lg) {
                    headerSection
                    introSection
                    stationsSection
                }
                .padding(.vertical, WTSpacing.lg)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text(path.localizedName)
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

    @ViewBuilder private var introSection: some View {
        if !path.localizedIntro.isEmpty {
            VStack(alignment: .leading, spacing: WTSpacing.sm) {
                SkillSubSectionHeader(title: "路线进阶提示")
                Text(path.localizedIntro)
                    .font(WTFont.body)
                    .foregroundStyle(Color.wtTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(WTSpacing.md)
                    .background(Color.wtSurface)
                    .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
            }
            .padding(.horizontal, WTSpacing.lg)
        }
    }

    private var stationsSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            SkillSubSectionHeader(title: "路线解锁")
                .padding(.horizontal, WTSpacing.lg)

            stationsList
        }
    }

    private var stationsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(skills.enumerated()), id: \.element.id) { index, skill in
                NavigationLink(destination: SkillDetailView(skill: skill)) {
                    MetroStationRow(
                        skill: skill,
                        status: statusMap[skill.id] ?? .unmarked,
                        isCurrent: index == currentIndex,
                        isFirst: index == 0,
                        isLast: index == skills.count - 1,
                        lineAboveActive: currentIndex.map { index <= $0 } ?? true,
                        lineBelowActive: currentIndex.map { index < $0 } ?? true,
                        isLocked: isLocked(index)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
