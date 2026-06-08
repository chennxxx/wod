import SwiftData
import SwiftUI

struct ProgressionPathDetailView: View {
    let path: ProgressionPath

    @Query private var allStatuses: [SkillStatus]

    private var statusMap: [String: SkillMasteryStatus] {
        Dictionary(uniqueKeysWithValues: allStatuses.map { ($0.skillId, $0.status) })
    }

    private var steps: [(index: Int, skill: SkillDefinition)] {
        path.steps.compactMap { SkillLibrary.skillById[$0] }
            .enumerated()
            .map { (index: $0.offset, skill: $0.element) }
    }

    var body: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.element.skill.id) { outerIndex, step in
                        PathStepRow(
                            index: step.index + 1,
                            skill: step.skill,
                            status: statusMap[step.skill.id] ?? .unmarked,
                            isLast: outerIndex == steps.count - 1
                        )
                    }
                }
                .padding(.vertical, WTSpacing.md)
            }
        }
        .navigationTitle(path.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Path Step Row

private struct PathStepRow: View {
    let index: Int
    let skill: SkillDefinition
    let status: SkillMasteryStatus
    let isLast: Bool

    private var statusColor: Color {
        switch status {
        case .mastered: Color.wtPrimary
        case .inProgress: Color(hex: "#5E81F4")
        case .wantToLearn: Color.wtTextSecondary
        case .unmarked: Color.wtTextDisabled
        }
    }

    private var statusIcon: String {
        switch status {
        case .mastered: "checkmark.circle.fill"
        case .inProgress: "moon.fill"
        case .wantToLearn: "circle"
        case .unmarked: "circle"
        }
    }

    var body: some View {
        NavigationLink(destination: SkillDetailView(skill: skill)) {
            HStack(alignment: .top, spacing: WTSpacing.md) {
                // Step number + connector line
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(status == .mastered ? Color.wtPrimary : Color.wtSurface)
                            .frame(width: 36, height: 36)
                        if status == .mastered {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.black)
                        } else {
                            Text(String(format: "%02d", index))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.wtTextSecondary)
                        }
                    }

                    if !isLast {
                        Rectangle()
                            .fill(Color.wtSurface2)
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 36)

                // Skill info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: WTSpacing.xs) {
                        Text(skill.name)
                            .font(WTFont.bodyBold)
                            .foregroundStyle(Color.wtTextPrimary)

                        Text(skill.tier.label)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(skill.tier.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(skill.tier.color.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text(skill.englishName)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.wtTextSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 11))
                            .foregroundStyle(statusColor)
                        Text(status.label)
                            .font(WTFont.micro)
                            .foregroundStyle(statusColor)
                    }
                }
                .padding(.bottom, isLast ? 0 : WTSpacing.xl)
                .padding(.top, WTSpacing.xs)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.wtTextDisabled)
                    .padding(.top, WTSpacing.sm)
            }
            .padding(.horizontal, WTSpacing.lg)
        }
        .buttonStyle(.plain)
    }
}
