import SwiftUI

// 重量小工具（现场速算，与历史记录无关）：
// ① WeightConverterView —— LB↔KG 双向换算 + 自重百分比 + CF 标准重量；
// ② BarbellCalculatorView —— 杠铃片统计：总重 Hero + 杠铃可视化 + 逐片步进。

// MARK: - 单位与换算

enum WeightUnit: String, CaseIterable, Identifiable {
    case lb
    case kg

    var id: String { rawValue }

    var label: String { rawValue.uppercased() }

    var other: WeightUnit { self == .lb ? .kg : .lb }

    /// 常用杆重预设（默认取第一个）。
    var barPresets: [Double] {
        switch self {
        case .lb: return [45, 35, 25, 15]
        case .kg: return [20, 15, 10]
        }
    }

    /// 常用杠铃片预设（由重到轻）。
    var platePresets: [Double] {
        switch self {
        case .lb: return [45, 35, 25, 15, 10, 5, 2.5]
        case .kg: return [25, 20, 15, 10, 5, 2.5, 1.25]
        }
    }

    /// 杠铃片配色（按实际重量对应的片色，区分 LB / KG 两套）。
    func plateColor(_ weight: Double) -> Color {
        let lbColors: [Double: String] = [
            45: "#1F66D0", // 蓝
            35: "#C9A800", // 黄
            25: "#1E7A3C", // 绿
            15: "#1C1F22", // 黑
            10: "#4F575C", // 深灰
            5: "#5AA0E0",  // 浅蓝
            2.5: "#1E7A3C", // 绿
        ]
        let kgColors: [Double: String] = [
            25: "#C0392B", 20: "#C9A800", 15: "#1E7A3C", 10: "#B0B8BA",
            5: "#1A5FAA", 2.5: "#9EA8AA", 1.25: "#526062",
        ]
        let hex = (self == .lb ? lbColors : kgColors)[weight] ?? "#526062"
        return Color(hex: hex)
    }
}

/// CF 常用标准重量（磅），男 / 女各 7 档。
enum CFStandard {
    static let men: [Double] = [95, 115, 135, 155, 185, 205, 225]
    static let women: [Double] = [65, 75, 85, 95, 105, 115, 135]
}

private let kgPerLb = 0.45359237

/// 单位换算。lb→kg ×系数；kg→lb ÷系数。
func convertWeight(_ value: Double, from: WeightUnit, to: WeightUnit) -> Double {
    guard from != to else { return value }
    return from == .lb ? value * kgPerLb : value / kgPerLb
}

/// 去除多余小数：整数不带小数点，否则保留 1 位。
private func trimWeight(_ value: Double) -> String {
    if value.truncatingRemainder(dividingBy: 1) == 0 {
        return String(Int(value.rounded()))
    }
    return String(format: "%.1f", value)
}

// 文档自定义强调色（局部使用，不进全局 token）。
private let wtGreenMid = Color(hex: "#2FAA63")

// MARK: - 工具①：重量换算

struct WeightConverterView: View {
    @State private var lbText = ""
    @State private var kgText = ""
    /// 当前聚焦的输入栏，决定联动方向，避免回写造成循环。
    @FocusState private var focus: WeightUnit?

    // 自重持久化（跨会话保留）。
    @AppStorage("wt.bodyweight") private var bodyweightText = ""
    @AppStorage("wt.bodyweightUnit") private var bodyweightUnitRaw = WeightUnit.kg.rawValue
    @State private var editingBodyweight = false
    @FocusState private var bodyweightFocused: Bool

    /// 百分比查对表的展示单位；nil 表示跟随自重单位，可经切换按钮覆盖。
    @State private var percentDisplayUnit: WeightUnit?

    private let percents = [50, 65, 75, 80, 85, 90, 100]

    private var bodyweightUnit: WeightUnit {
        WeightUnit(rawValue: bodyweightUnitRaw) ?? .lb
    }

    /// 百分比表实际展示单位（切换按钮优先，否则跟随自重单位）。
    private var displayUnit: WeightUnit {
        percentDisplayUnit ?? bodyweightUnit
    }

    var body: some View {
        ZStack {
            WTScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: WTSpacing.xxl) {
                    converterSection
                    bodyweightSection
                    cfStandardSection
                }
                .padding(WTSpacing.lg)
                .padding(.top, WTSpacing.md)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("重量换算")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: lbText) {
            if focus == .lb { sync(from: .lb) }
        }
        .onChange(of: kgText) {
            if focus == .kg { sync(from: .kg) }
        }
        // 重新聚焦已有内容的输入框时，把光标移到数字末尾（修正 UITextField 默认落点不稳）。
        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { note in
            guard let field = note.object as? UITextField else { return }
            DispatchQueue.main.async {
                let end = field.endOfDocument
                field.selectedTextRange = field.textRange(from: end, to: end)
            }
        }
    }

    // MARK: 换算输入区（第一层）

    private var converterSection: some View {
        VStack(spacing: WTSpacing.lg) {
            unitRow(unit: .lb, label: "LB（磅）", text: $lbText)
            unitRow(unit: .kg, label: "KG（公斤）", text: $kgText)
        }
        .padding(WTSpacing.lg)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
    }

    private func unitRow(unit: WeightUnit, label: LocalizedStringKey, text: Binding<String>) -> some View {
        let active = focus == unit
        return VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: WTSpacing.md) {
                Text(label)
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                    .frame(width: 96, alignment: .leading)

                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .focused($focus, equals: unit)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.wtTextPrimary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity)

                Text(unit.label)
                    .font(WTFont.bodyBold)
                    .foregroundStyle(active ? Color.wtPrimary : Color.wtTextSecondary)
                    .frame(width: 34, alignment: .leading)
            }
            // 焦点行底线：聚焦时绿色 2px 实线，否则灰色细线。
            Rectangle()
                .fill(active ? Color.wtPrimary : Color.wtSurface2)
                .frame(height: active ? 2 : 1)
        }
    }

    // MARK: 自重 + 百分比快捷（第二层）

    private var hasBodyweight: Bool { Double(bodyweightText) != nil }

    private var bodyweightSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text("自重查对表")
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            VStack(alignment: .leading, spacing: WTSpacing.md) {
                if editingBodyweight {
                    bodyweightEditor
                } else if hasBodyweight {
                    bodyweightContent
                } else {
                    bodyweightEmptyState
                }
            }
            .padding(WTSpacing.lg)
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        }
    }

    /// 已填自重：当前值 + 编辑入口 → 百分比查对网格 → 单位切换。
    @ViewBuilder private var bodyweightContent: some View {
        HStack {
            Text("\(bodyweightText) \(bodyweightUnit.label)")
                .font(WTFont.mono(22, weight: .bold))
                .foregroundStyle(Color.wtTextPrimary)
            Spacer()
            Button {
                startEditingBodyweight()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.wtPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.wtSurface2)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }

        // 自重百分比：填了自重后直接展示每档对应重量（两行平铺，纯查对、不可点）。
        LazyVGrid(columns: percentColumns, spacing: WTSpacing.sm) {
            ForEach(percents, id: \.self) { pct in
                VStack(spacing: 2) {
                    Text("\(pct)%")
                        .font(WTFont.mono(14, weight: .bold))
                        .foregroundStyle(Color.wtTextPrimary)
                    Text(percentWeightLabel(pct))
                        .font(WTFont.micro)
                        .foregroundStyle(Color.wtTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.wtSurface2)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
            }
        }

        // 右下角：切换查对表的展示单位（LB / KG）。
        HStack {
            Spacer()
            Button {
                percentDisplayUnit = displayUnit.other
            } label: {
                HStack(spacing: WTSpacing.xs) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                    Text("切换为 \(displayUnit.other.label)")
                        .font(WTFont.caption)
                }
                .foregroundStyle(Color.wtPrimary)
            }
            .buttonStyle(.plain)
        }
    }

    /// 自重空态：一句引导 + 醒目的「设置自重」按钮。
    private var bodyweightEmptyState: some View {
        VStack(spacing: WTSpacing.md) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(Color.wtTextSecondary)

            Text("填入自重后，即可快速查看 50%–100% 各强度对应的重量")
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                startEditingBodyweight()
            } label: {
                HStack(spacing: WTSpacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("设置自重")
                        .font(WTFont.bodyBold)
                }
                .foregroundStyle(Color.wtPrimary)
                .padding(.horizontal, WTSpacing.lg)
                .padding(.vertical, WTSpacing.sm + 2)
                .selectablePill(isOn: true)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, WTSpacing.md)
    }

    private let percentColumns = Array(
        repeating: GridItem(.flexible(), spacing: WTSpacing.sm),
        count: 4
    )

    /// 进入自重编辑并让输入框自动获得光标。
    private func startEditingBodyweight() {
        editingBodyweight = true
        DispatchQueue.main.async { bodyweightFocused = true }
    }

    /// 某百分比对应的自重重量文案（按查对表展示单位）；未填自重显示「—」。
    private func percentWeightLabel(_ pct: Int) -> String {
        guard let bw = Double(bodyweightText) else { return "—" }
        let bwInDisplay = convertWeight(bw, from: bodyweightUnit, to: displayUnit)
        return "\(trimWeight(bwInDisplay * Double(pct) / 100)) \(displayUnit.label)"
    }

    private var bodyweightEditor: some View {
        VStack(alignment: .leading, spacing: WTSpacing.lg) {
            HStack(spacing: WTSpacing.md) {
                TextField("0", text: $bodyweightText)
                    .keyboardType(.decimalPad)
                    .focused($bodyweightFocused)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.wtTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: WTSpacing.xs) {
                    ForEach(WeightUnit.allCases) { u in
                        Button {
                            bodyweightUnitRaw = u.rawValue
                            percentDisplayUnit = nil  // 改自重单位后查对表跟随新单位
                        } label: {
                            Text(u.label)
                                .font(WTFont.caption)
                                .foregroundStyle(bodyweightUnit == u ? Color.wtPrimary : Color.wtTextSecondary)
                                .padding(.horizontal, WTSpacing.sm + 2)
                                .padding(.vertical, 7)
                                .selectablePill(isOn: bodyweightUnit == u)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                editingBodyweight = false
                bodyweightFocused = false
            } label: {
                HStack(spacing: WTSpacing.xs) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                    Text("完成")
                        .font(WTFont.bodyBold)
                }
                .foregroundStyle(Color.wtPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, WTSpacing.sm + 2)
                .selectablePill(isOn: true)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: CF 标准重量（第三层）

    private var cfStandardSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text("CF 标准重量查对表")
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            VStack(alignment: .leading, spacing: WTSpacing.md) {
                standardRow(title: "男子", values: CFStandard.men)
                standardRow(title: "女子", values: CFStandard.women)
            }
            .padding(WTSpacing.lg)
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        }
    }

    /// 7 档两行平铺（4 列 → 4+3），纯查对、不可点。
    private func standardRow(title: LocalizedStringKey, values: [Double]) -> some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text(title)
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            LazyVGrid(columns: percentColumns, spacing: WTSpacing.sm) {
                ForEach(values, id: \.self) { lb in
                    VStack(spacing: 1) {
                        Text("\(trimWeight(lb)) LB")
                            .font(WTFont.mono(13, weight: .semibold))
                            .foregroundStyle(Color.wtTextPrimary)
                        Text("\(trimWeight(convertWeight(lb, from: .lb, to: .kg))) KG")
                            .font(WTFont.micro)
                            .foregroundStyle(Color.wtTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.wtSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
                }
            }
        }
    }

    // MARK: 逻辑

    /// 从某一侧的输入联动另一侧。源为空则清空另一侧；非法输入不动。
    private func sync(from source: WeightUnit) {
        let raw = source == .lb ? lbText : kgText
        let target = source.other

        if raw.isEmpty {
            if target == .lb { lbText = "" } else { kgText = "" }
            return
        }
        guard let value = Double(raw) else { return }

        let converted = trimWeight(convertWeight(value, from: source, to: target))
        if target == .lb {
            lbText = converted
        } else {
            kgText = converted
        }
    }

}

// MARK: - 工具②：杠铃片统计

struct BarbellCalculatorView: View {
    @State private var unit: WeightUnit = .lb
    @State private var barWeight: Double = WeightUnit.lb.barPresets[0]
    /// 每种片重选中的「成对」数量（每加 1 = 两侧各 1 片）。key=片重。
    @State private var plateCounts: [Double: Int] = [:]

    private var totalWeight: Double {
        let plates = plateCounts.reduce(0.0) { sum, pair in
            sum + pair.key * Double(pair.value) * 2
        }
        return barWeight + plates
    }

    /// 当前实际加上的片（重→轻），供可视化与明细使用。
    private var loadedPlates: [(weight: Double, count: Int)] {
        unit.platePresets.compactMap { w in
            let c = plateCounts[w, default: 0]
            return c > 0 ? (w, c) : nil
        }
    }

    var body: some View {
        ZStack {
            WTScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: WTSpacing.xl) {
                    totalHero
                    BarbellView(unit: unit, plates: loadedPlates)
                    unitAndBarSection
                    plateSection
                }
                .padding(WTSpacing.lg)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("杠铃片统计")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: 总重 Hero（第一层）

    private var totalHero: some View {
        VStack(alignment: .leading, spacing: WTSpacing.xs) {
            Text("总重")
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            HStack(alignment: .center, spacing: WTSpacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(trimWeight(totalWeight))
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(Color.wtPrimary)
                    Text(unit.label)
                        .font(WTFont.title)
                        .foregroundStyle(Color.wtPrimary)
                    Text("= \(trimWeight(convertWeight(totalWeight, from: unit, to: unit.other))) \(unit.other.label)")
                        .font(WTFont.body)
                        .foregroundStyle(Color.wtTextSecondary)
                        .padding(.leading, WTSpacing.xs)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)

                Spacer(minLength: 0)

                if !loadedPlates.isEmpty {
                    Button {
                        plateCounts = [:]
                        haptic()
                    } label: {
                        HStack(spacing: WTSpacing.xs) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11, weight: .semibold))
                            Text("清空杠铃片")
                                .font(WTFont.caption)
                        }
                        .foregroundStyle(Color.wtTextSecondary)
                        .padding(.horizontal, WTSpacing.sm + 2)
                        .padding(.vertical, 7)
                        .background(Color.wtSurface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.wtSurface2, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                }
            }
        }
    }

    // MARK: 单位 + 杆重（第三层）

    private var unitAndBarSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {
            // 单位：标题行 + LB / KG 两个按钮另起一行（与杆重一致）
            VStack(alignment: .leading, spacing: WTSpacing.sm) {
                Text("单位")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)

                HStack(spacing: WTSpacing.sm) {
                    ForEach(WeightUnit.allCases) { u in
                        Button {
                            selectUnit(u)
                        } label: {
                            Text(u.label)
                                .font(WTFont.mono(15, weight: .semibold))
                                .foregroundStyle(unit == u ? Color.wtPrimary : Color.wtTextPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .selectableChip(isOn: unit == u)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // 杆重：标题行 + 预设另起一行
            VStack(alignment: .leading, spacing: WTSpacing.sm) {
                Text("杆重")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)

                HStack(spacing: WTSpacing.sm) {
                    ForEach(unit.barPresets, id: \.self) { w in
                        Button {
                            barWeight = w
                        } label: {
                            Text(trimWeight(w))
                                .font(WTFont.mono(15, weight: .semibold))
                                .foregroundStyle(barWeight == w ? Color.wtPrimary : Color.wtTextPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .selectableChip(isOn: barWeight == w)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    /// 切换单位：重置杆重为对应预设、清空片数（两套单位不混用）。
    private func selectUnit(_ u: WeightUnit) {
        guard unit != u else { return }
        unit = u
        barWeight = u.barPresets[0]
        plateCounts = [:]
    }

    // MARK: 逐片步进（第四层）

    private var plateSection: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            HStack {
                Text("杠铃片")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                Spacer()
                Text("每加 1 = 两侧各 1 片")
                    .font(WTFont.micro)
                    .foregroundStyle(Color.wtTextSecondary)
            }

            ForEach(unit.platePresets, id: \.self) { plate in
                plateRow(plate)
            }
        }
    }

    private func plateRow(_ plate: Double) -> some View {
        let count = plateCounts[plate, default: 0]
        let hasPlate = count > 0
        return HStack(spacing: WTSpacing.md) {
            // 片色徽章：色块上直接显示片重，比小圆点更清晰
            Text(trimWeight(plate))
                .font(WTFont.mono(15, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.45), radius: 1, y: 0.5)
                .frame(width: 48, height: 34)
                .background(unit.plateColor(plate))
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: WTRadius.sm).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                .opacity(hasPlate ? 1 : 0.55)

            VStack(alignment: .leading, spacing: 1) {
                Text(unit.label)
                    .font(WTFont.mono(14, weight: .medium))
                    .foregroundStyle(hasPlate ? Color.wtTextPrimary : Color.wtTextSecondary)
                if hasPlate {
                    // 该片两侧合计贡献
                    Text("+ \(trimWeight(plate * Double(count) * 2)) \(unit.label)")
                        .font(WTFont.micro)
                        .foregroundStyle(wtGreenMid)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: WTSpacing.md) {
                stepperButton(systemName: "minus", enabled: hasPlate) {
                    if count > 0 {
                        plateCounts[plate] = count - 1
                        haptic()
                    }
                }
                Text("\(count)")
                    .font(WTFont.mono(17, weight: .bold))
                    .foregroundStyle(Color.wtTextPrimary)
                    .frame(minWidth: 28)
                stepperButton(systemName: "plus", enabled: true) {
                    plateCounts[plate] = count + 1
                    haptic()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(hasPlate ? Color.wtSurface2 : Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
    }

    private func stepperButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(enabled ? Color.wtPrimary : Color.wtTextDisabled)
                .frame(width: 32, height: 32)
                .background(Color.wtSurface)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func haptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - 杠铃侧视示意图

/// 清晰示意图：中央裸杆 + 两端卡领，杠铃片从内（紧贴卡领的重片）向外（轻片）按重量分组排列、按真实标准上色。
private struct BarbellView: View {
    let unit: WeightUnit
    let plates: [(weight: Double, count: Int)]

    /// 单侧片序列（重→轻，按对数展开、同重相邻成组）。重片紧贴卡领，向外逐渐变轻。
    private var sidePlates: [Double] {
        plates.flatMap { Array(repeating: $0.weight, count: $0.count) }
    }

    private var maxPlate: Double {
        unit.platePresets.max() ?? 45
    }

    private let gripWidth: CGFloat = 96
    private let collarWidth: CGFloat = 8
    private let plateSpacing: CGFloat = 2

    /// 整副杠铃的自然宽度（两侧片 + 卡领 + 中央抓手段）。
    private var contentWidth: CGFloat {
        let oneSide = sidePlates.reduce(CGFloat(0)) { $0 + plateWidth($1) + plateSpacing }
        return oneSide * 2 + collarWidth * 2 + gripWidth
    }

    var body: some View {
        let height: CGFloat = 96
        // 整副杠铃居中；自然宽度超出可用宽度时整体等比缩放，始终不溢出。
        GeometryReader { geo in
            let scale = min(1, geo.size.width / max(contentWidth, 1))
            assembly(height: height)
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: height)
        }
        .frame(height: height)
        .padding(.vertical, WTSpacing.sm)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
    }

    /// 整副杠铃（按内容宽度自适应）：中央留抓手段，片从卡领向两端外侧生长。
    private func assembly(height: CGFloat) -> some View {
        ZStack {
            // 杆（贯穿整副，含两端套筒）
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#8A8F94"))
                .frame(height: 8)

            HStack(spacing: 0) {
                // 左侧：外→内 = 轻→重（重片紧贴卡领、向外变轻）
                plateStack(Array(sidePlates.reversed()), maxHeight: height)
                collar
                // 中央抓手段（裸杆，握距）
                Color.clear.frame(width: gripWidth, height: 1)
                collar
                // 右侧：内→外 = 重→轻
                plateStack(sidePlates, maxHeight: height)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    /// 卡领（套筒挡片），位于裸杆与杠铃片之间。
    private var collar: some View {
        Capsule()
            .fill(Color(hex: "#5A5F64"))
            .frame(width: 8, height: 24)
    }

    private func plateStack(_ weights: [Double], maxHeight: CGFloat) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(weights.enumerated()), id: \.offset) { _, w in
                RoundedRectangle(cornerRadius: 2)
                    .fill(unit.plateColor(w))
                    .frame(width: plateWidth(w), height: plateHeight(w, maxHeight: maxHeight))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.white.opacity(0.22), lineWidth: 0.5))
            }
        }
    }

    /// 片高按重量比例（最小 0.4 高度起步），直观区分大小片。
    private func plateHeight(_ w: Double, maxHeight: CGFloat) -> CGFloat {
        let ratio = 0.4 + 0.6 * (w / maxPlate)
        return maxHeight * min(1, ratio)
    }

    private func plateWidth(_ w: Double) -> CGFloat {
        w >= maxPlate * 0.5 ? 12 : 9
    }
}

#Preview {
    NavigationStack {
        WeightConverterView()
    }
    .preferredColorScheme(.dark)
}
