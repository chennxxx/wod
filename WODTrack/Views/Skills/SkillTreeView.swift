import SwiftData
import SwiftUI

// MARK: - Main View

struct SkillTreeView: View {
    @Query private var allStatuses: [SkillStatus]

    @State private var selectedPage: SkillPage = .actions

    private enum SkillPage: CaseIterable {
        case actions, paths
        var label: String {
            switch self {
            case .actions: String(localized: "动作")
            case .paths: String(localized: "进阶路线")
            }
        }
    }

    private var statusMap: [String: SkillStatus] { allStatuses.indexedBySkillId }

    private func status(for skill: SkillDefinition) -> SkillMasteryStatus {
        statusMap[skill.id]?.status ?? .unmarked
    }

    // MARK: 总览统计

    private var totalSkills: Int { SkillLibrary.allSkills.count }
    private var masteredTotal: Int { SkillLibrary.allSkills.filter { status(for: $0) == .mastered }.count }
    private var inProgressTotal: Int { SkillLibrary.allSkills.filter { status(for: $0) == .inProgress }.count }
    private var wantToLearnTotal: Int { SkillLibrary.allSkills.filter { status(for: $0) == .wantToLearn }.count }
    private var unmarkedTotal: Int { totalSkills - masteredTotal - inProgressTotal - wantToLearnTotal }
    private var masteryProgress: Double { totalSkills > 0 ? Double(masteredTotal) / Double(totalSkills) : 0 }

    private var inProgressSkills: [SkillDefinition] {
        SkillLibrary.allSkills.filter { status(for: $0) == .inProgress }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: WTSpacing.md) {
                    pageSwitcher
                        .padding(.horizontal, WTSpacing.lg)

                    switch selectedPage {
                    case .actions: actionsContent
                    case .paths: pathsContent
                    }
                }
                .padding(.top, WTSpacing.sm)
                .padding(.bottom, WTSpacing.xl)
            }
            .background(WTScreenBackground())
            .navigationTitle("技能树")
        }
    }

    // MARK: 页签切换

    private var pageSwitcher: some View {
        Picker("", selection: $selectedPage) {
            ForEach(SkillPage.allCases, id: \.self) { page in
                Text(page.label).tag(page)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: 进阶路线

    @ViewBuilder private var pathsContent: some View {
        VStack(spacing: WTSpacing.sm) {
            ForEach(ProgressionPathLibrary.all) { path in
                NavigationLink(destination: ProgressionPathDetailView(path: path)) {
                    PathRowCard(path: path, statusMap: statusMap)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, WTSpacing.lg)
    }

    // MARK: 掌握卡（仪表盘）

    private var masteryCard: some View {
        HStack(spacing: WTSpacing.lg) {
            MasteryRing(progress: masteryProgress)
                .frame(width: 96, height: 96)

            VStack(alignment: .leading, spacing: WTSpacing.md) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(masteredTotal)")
                        .font(WTFont.mono(30, weight: .bold))
                        .foregroundStyle(Color.wtTextPrimary)
                    Text("/ \(totalSkills) 已掌握")
                        .font(WTFont.mono(12))
                        .foregroundStyle(Color.wtTextSecondary)
                }

                VStack(spacing: WTSpacing.xs) {
                    readout(.inProgress, inProgressTotal, "进行中")
                    readout(.wantToLearn, wantToLearnTotal, "想学")
                    readout(.unmarked, unmarkedTotal, "未标记")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WTSpacing.lg)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        .padding(.horizontal, WTSpacing.lg)
    }

    private func readout(_ status: SkillMasteryStatus, _ value: Int, _ label: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            StatusGlyph(status: status, size: 15)
            Text("\(value)")
                .font(WTFont.mono(14, weight: .semibold))
                .foregroundStyle(Color.wtTextPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.wtTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 动作 · 仪表盘

    @ViewBuilder private var actionsContent: some View {
        masteryCard

        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            SkillSectionHeader(title: "分类")
                .padding(.horizontal, WTSpacing.lg)

            ForEach(SkillLibrary.categories) { category in
                NavigationLink(destination: SkillBrowseView(category: category)) {
                    CategoryModuleCard(category: category, statusMap: statusMap)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, WTSpacing.lg)
            }
        }

        if !inProgressSkills.isEmpty {
            VStack(alignment: .leading, spacing: WTSpacing.sm) {
                SkillSectionHeader(title: "进行中")
                    .padding(.horizontal, WTSpacing.lg)

                VStack(spacing: 0) {
                    ForEach(Array(inProgressSkills.enumerated()), id: \.element.id) { index, skill in
                        NavigationLink(destination: SkillDetailView(skill: skill)) {
                            SkillStatusRow(skill: skill, status: .inProgress)
                        }
                        .buttonStyle(.plain)
                        if index < inProgressSkills.count - 1 {
                            Divider().background(Color.wtSurface2).padding(.leading, WTSpacing.md)
                        }
                    }
                }
                .background(Color.wtSurface)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
                .padding(.horizontal, WTSpacing.lg)
            }
            .padding(.top, WTSpacing.xs)
        }
    }
}
