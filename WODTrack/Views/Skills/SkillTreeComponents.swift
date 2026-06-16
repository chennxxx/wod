import SwiftData
import SwiftUI

// MARK: - 状态配色（单一可信源）

extension SkillMasteryStatus {
    /// 四态强调色：已掌握绿 / 进行中蓝 / 想学灰描边 / 未标记暗。
    var accentColor: Color {
        switch self {
        case .mastered: Color.wtPrimary
        case .inProgress: Color.wtInProgress
        case .wantToLearn: Color.wtTextSecondary
        case .unmarked: Color.wtTextDisabled
        }
    }
}

// MARK: - 四态字形（StatusGlyph）

/// 四个视觉互异的状态字形，全页统一使用，避免「未标记 / 想学」混画成同一个 circle。
struct StatusGlyph: View {
    let status: SkillMasteryStatus
    var size: CGFloat = 20

    private var symbolName: String {
        switch status {
        case .mastered: "checkmark.circle.fill"
        case .inProgress: "circle.lefthalf.filled"
        case .wantToLearn: "circle"
        case .unmarked: "circle.dashed"
        }
    }

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size))
            .foregroundStyle(status.accentColor)
    }
}

// MARK: - 分区标题

/// 左侧细绿竖条 + 中文标题 + 灰色等宽副标 + 可选尾部读数。
struct SkillSectionHeader: View {
    let title: String
    var mono: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: WTSpacing.xs) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.wtPrimary)
                .frame(width: 3, height: 18)
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.wtTextPrimary)
            if let mono {
                Text(mono)
                    .font(WTFont.mono(11, weight: .medium))
                    .foregroundStyle(Color.wtTextSecondary)
            }
            Spacer(minLength: 0)
            if let trailing {
                Text(trailing)
                    .font(WTFont.mono(13, weight: .medium))
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
    }
}

// MARK: - 等级条形徽章

/// `L3 ▮▮▮▯▯`：等宽等级 + 5 格按 tier 点亮。
struct TierBars: View {
    let tier: SkillTier

    private var level: Int {
        switch tier {
        case .l1: 1
        case .l2: 2
        case .l3: 3
        case .l4: 4
        case .l5: 5
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(tier.label)
                .font(WTFont.mono(10, weight: .semibold))
                .foregroundStyle(Color.wtTextSecondary)
            HStack(spacing: 2) {
                ForEach(0 ..< 5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(i < level ? Color.wtPrimary : Color.wtSurface2)
                        .frame(width: 3, height: 9)
                }
            }
        }
    }
}

// MARK: - 掌握环

struct MasteryRing: View {
    /// 0...1
    let progress: Double
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.wtSurface2, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(Color.wtPrimary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(WTFont.mono(20, weight: .bold))
                    .foregroundStyle(Color.wtTextPrimary)
                Text("已掌握")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
    }
}

// MARK: - 进度条（已掌握绿 + 进行中蓝 + 余量灰）

struct SkillProgressBar: View {
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
                    RoundedRectangle(cornerRadius: 2).fill(Color.wtInProgress).frame(width: inProgressW)
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

// MARK: - 统一动作行

/// 列表 / 扁平列表 / 线路详情共用的动作行（StatusGlyph + 中文名 + 等宽英文名 + TierBars）。
struct SkillStatusRow: View {
    let skill: SkillDefinition
    let status: SkillMasteryStatus
    var bestEntry: SkillTrainingEntry? = nil
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: WTSpacing.sm) {
            StatusGlyph(status: status)
                .frame(width: 28)

            Text(skill.name)
                .font(WTFont.bodyBold)
                .foregroundStyle(Color.wtTextPrimary)

            Spacer(minLength: WTSpacing.sm)

            if let entry = bestEntry {
                Text(entry.formattedValue)
                    .font(WTFont.mono(12))
                    .foregroundStyle(Color.wtTextSecondary)
            }

            TierBars(tier: skill.tier)

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.wtTextSecondary)
                    .padding(.leading, 2)
            }
        }
        .padding(.horizontal, WTSpacing.md)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - 仪表盘分类模块

/// 大类名 + `已掌握/总` + 进度条 + 子类计数 + 跳转箭头（整卡可点）。
struct CategoryModuleCard: View {
    let category: SkillCategoryDefinition
    let statusMap: [String: SkillStatus]

    private func status(_ skill: SkillDefinition) -> SkillMasteryStatus {
        statusMap[skill.id]?.status ?? .unmarked
    }

    private var mastered: Int { category.skills.filter { status($0) == .mastered }.count }
    private var inProgress: Int { category.skills.filter { status($0) == .inProgress }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: WTSpacing.sm) {
                Text(category.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.wtTextPrimary)
                Spacer(minLength: WTSpacing.sm)
                Text("\(mastered)")
                    .font(WTFont.mono(22, weight: .bold))
                    .foregroundStyle(Color.wtTextPrimary)
                Text("/\(category.skills.count)")
                    .font(WTFont.mono(13))
                    .foregroundStyle(Color.wtTextSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.wtTextSecondary)
                    .padding(.leading, 2)
            }

            SkillProgressBar(total: category.skills.count, mastered: mastered, inProgress: inProgress)
        }
        .padding(WTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        .contentShape(Rectangle())
    }
}

// MARK: - 地铁线路（横向迷你）

/// 站点 = 动作，主线 = 线路。绿实心 = 已掌握，绿描边 = 当前站。
struct MetroLineMini: View {
    let skills: [SkillDefinition]
    let statusMap: [String: SkillMasteryStatus]

    /// 当前站 = 第一个未掌握的动作。
    private var currentIndex: Int? {
        skills.firstIndex { (statusMap[$0.id] ?? .unmarked) != .mastered }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(skills.enumerated()), id: \.element.id) { idx, skill in
                let status = statusMap[skill.id] ?? .unmarked
                dot(status: status, isCurrent: idx == currentIndex)
                if idx < skills.count - 1 {
                    Rectangle()
                        .fill(connectorActive(after: idx) ? Color.wtPrimary : Color.wtSurface2)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 14)
    }

    /// 当前站之前的连线点亮。
    private func connectorActive(after idx: Int) -> Bool {
        guard let current = currentIndex else { return true }
        return idx < current
    }

    @ViewBuilder
    private func dot(status: SkillMasteryStatus, isCurrent: Bool) -> some View {
        if status == .mastered {
            Circle().fill(Color.wtPrimary).frame(width: 10, height: 10)
        } else if isCurrent {
            Circle()
                .strokeBorder(Color.wtPrimary, lineWidth: 2.5)
                .background(Circle().fill(Color.wtBackground))
                .frame(width: 12, height: 12)
        } else {
            Circle().fill(Color.wtSurface2).frame(width: 8, height: 8)
        }
    }
}

// MARK: - 地铁线路（纵向单站）

/// 路径详情的单个站点：左侧站点圆 + 上下连线 + 序号；右侧动作信息；当前站挂 YOU ARE HERE 标。
struct MetroStationRow: View {
    let index: Int
    let skill: SkillDefinition
    let status: SkillMasteryStatus
    let isCurrent: Bool
    let isLast: Bool
    /// 此站下方连线是否点亮（当前站之前为绿）。
    let lineBelowActive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: WTSpacing.md) {
            VStack(spacing: 0) {
                stationDot
                if !isLast {
                    Rectangle()
                        .fill(lineBelowActive ? Color.wtPrimary : Color.wtSurface2)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: WTSpacing.xs) {
                    Text(String(format: "%02d", index))
                        .font(WTFont.mono(11, weight: .medium))
                        .foregroundStyle(Color.wtTextDisabled)
                    Text(skill.name)
                        .font(WTFont.bodyBold)
                        .foregroundStyle(isReachable ? Color.wtTextPrimary : Color.wtTextDisabled)
                    Spacer(minLength: WTSpacing.sm)
                    TierBars(tier: skill.tier)
                }

                if isCurrent {
                    HStack(spacing: 5) {
                        Text("当前")
                            .font(.system(size: 10, weight: .semibold))
                        if let rationale = skill.prereqRationale {
                            Text("· \(rationale)")
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.wtPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))
                    .padding(.top, 2)
                }
            }
            .padding(.bottom, isLast ? 0 : WTSpacing.lg)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.wtTextDisabled)
                .padding(.top, WTSpacing.xs)
        }
        .padding(.horizontal, WTSpacing.lg)
        .contentShape(Rectangle())
    }

    /// 已掌握 / 进行中 / 想学 = 可达（实心字），未标记 = 暗（视作未解锁）。
    private var isReachable: Bool { status != .unmarked }

    @ViewBuilder
    private var stationDot: some View {
        ZStack {
            if status == .mastered {
                Circle().fill(Color.wtPrimary).frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.black)
            } else if isCurrent {
                Circle()
                    .strokeBorder(Color.wtPrimary, lineWidth: 2.5)
                    .frame(width: 28, height: 28)
            } else if status == .unmarked {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .foregroundStyle(Color.wtTextDisabled)
                    .frame(width: 28, height: 28)
            } else {
                Circle()
                    .strokeBorder(status.accentColor, lineWidth: 2)
                    .frame(width: 28, height: 28)
            }
        }
        .frame(width: 28, height: 28)
    }
}

// MARK: - 简易流式布局

/// 子视图按行自动换行排列（用于子类计数 chips、筛选 chips）。
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
