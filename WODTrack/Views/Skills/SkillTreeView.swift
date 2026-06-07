import SwiftUI

struct SkillTreeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.wtBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: WTSpacing.lg) {
                        Text("CrossFit 动作涵盖体操、举重、有氧三大类，每类按 T0–T2 难度递进。")
                            .font(WTFont.caption)
                            .foregroundStyle(Color.wtTextSecondary)
                            .padding(.horizontal, WTSpacing.lg)

                        ForEach(SkillCategory.all) { category in
                            SkillCategorySection(category: category)
                        }
                    }
                    .padding(.vertical, WTSpacing.lg)
                }
            }
            .navigationTitle("技能树")
        }
    }
}

// MARK: - Category Section

private struct SkillCategorySection: View {
    let category: SkillCategory
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: WTSpacing.sm) {
                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(category.color)
                        .frame(width: 32, height: 32)
                        .background(category.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(WTFont.bodyBold)
                            .foregroundStyle(Color.wtTextPrimary)
                        Text(category.subtitle)
                            .font(WTFont.micro)
                            .foregroundStyle(Color.wtTextSecondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.wtTextSecondary)
                }
                .padding(.horizontal, WTSpacing.lg)
                .padding(.vertical, WTSpacing.md)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: WTSpacing.xs) {
                    ForEach(SkillTier.allCases) { tier in
                        let skills = category.skills.filter { $0.tier == tier }
                        if !skills.isEmpty {
                            SkillTierRow(tier: tier, skills: skills)
                        }
                    }
                }
                .padding(.horizontal, WTSpacing.lg)
                .padding(.bottom, WTSpacing.md)
            }
        }
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        .padding(.horizontal, WTSpacing.lg)
    }
}

// MARK: - Tier Row

private struct SkillTierRow: View {
    let tier: SkillTier
    let skills: [Skill]

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.xs) {
            HStack(spacing: WTSpacing.xs) {
                Text(tier.label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tier.textColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(tier.badgeColor)
                    .clipShape(Capsule())

                Text(tier.description)
                    .font(WTFont.micro)
                    .foregroundStyle(Color.wtTextSecondary)
            }
            .padding(.top, WTSpacing.xs)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: WTSpacing.xs) {
                ForEach(skills) { skill in
                    Text(skill.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.wtTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .padding(.horizontal, WTSpacing.xs)
                        .background(Color.wtSurface2)
                        .clipShape(RoundedRectangle(cornerRadius: WTRadius.sm))
                }
            }
        }
    }
}

// MARK: - Data Models

private enum SkillTier: String, CaseIterable, Identifiable {
    case t0, t1, t2
    var id: String { rawValue }

    var label: String {
        switch self {
        case .t0: "T0"
        case .t1: "T1"
        case .t2: "T2"
        }
    }

    var description: String {
        switch self {
        case .t0: "基础"
        case .t1: "进阶"
        case .t2: "精英"
        }
    }

    var badgeColor: Color {
        switch self {
        case .t0: Color(hex: "#2C2C2E")
        case .t1: Color(hex: "#1C3A5E")
        case .t2: Color(hex: "#3A1C1C")
        }
    }

    var textColor: Color {
        switch self {
        case .t0: Color(hex: "#AEAEB2")
        case .t1: Color(hex: "#64B5F6")
        case .t2: Color(hex: "#F5C518")
        }
    }
}

private struct Skill: Identifiable {
    let id = UUID()
    let name: String
    let tier: SkillTier
}

private struct SkillCategory: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let skills: [Skill]

    static let all: [SkillCategory] = [gymnastics, weightlifting, cardio]

    static let gymnastics = SkillCategory(
        name: "体操",
        subtitle: "Gymnastics",
        icon: "figure.gymnastics",
        color: Color(hex: "#5E81F4"),
        skills: [
            Skill(name: "俯卧撑", tier: .t0),
            Skill(name: "引体向上", tier: .t0),
            Skill(name: "双杠臂屈伸", tier: .t0),
            Skill(name: "空心体", tier: .t0),
            Skill(name: "跳箱", tier: .t0),
            Skill(name: "环上支撑", tier: .t1),
            Skill(name: "倒立行走", tier: .t1),
            Skill(name: "肌肉上翻", tier: .t1),
            Skill(name: "手倒立俯卧撑", tier: .t1),
            Skill(name: "蝴蝶引体", tier: .t2),
            Skill(name: "绳索攀爬", tier: .t2),
            Skill(name: "环上双力臂", tier: .t2),
        ]
    )

    static let weightlifting = SkillCategory(
        name: "举重",
        subtitle: "Weightlifting",
        icon: "figure.strengthtraining.traditional",
        color: Color(hex: "#F5A623"),
        skills: [
            Skill(name: "硬拉", tier: .t0),
            Skill(name: "深蹲", tier: .t0),
            Skill(name: "推举", tier: .t0),
            Skill(name: "划船", tier: .t0),
            Skill(name: "前蹲", tier: .t1),
            Skill(name: "悬垂抓举", tier: .t1),
            Skill(name: "悬垂挺举", tier: .t1),
            Skill(name: "颈后推举", tier: .t1),
            Skill(name: "抓举", tier: .t2),
            Skill(name: "挺举", tier: .t2),
            Skill(name: "分腿挺举", tier: .t2),
        ]
    )

    static let cardio = SkillCategory(
        name: "有氧",
        subtitle: "Monostructural",
        icon: "heart.circle.fill",
        color: Color(hex: "#34C759"),
        skills: [
            Skill(name: "跑步", tier: .t0),
            Skill(name: "划船机", tier: .t0),
            Skill(name: "跳绳", tier: .t0),
            Skill(name: "双摇跳绳", tier: .t1),
            Skill(name: "壶铃摆动", tier: .t1),
            Skill(name: "攻城锤", tier: .t1),
            Skill(name: "Echo Bike", tier: .t2),
            Skill(name: "Ski Erg", tier: .t2),
        ]
    )
}
