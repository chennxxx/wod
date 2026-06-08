import Foundation
import SwiftUI

enum SkillTier: String, CaseIterable, Identifiable, Codable {
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
}

struct SkillDefinition: Identifiable {
    let id: String
    let name: String
    let englishName: String
    let tier: SkillTier
    let categoryId: String
    // 后续扩展：prerequisites, scoreUnit 等
}

struct SkillCategoryDefinition: Identifiable {
    let id: String
    let name: String
    let englishName: String
    let icon: String       // SF Symbol name
    let color: Color
    let skills: [SkillDefinition]
}

enum SkillLibrary {
    static let categories: [SkillCategoryDefinition] = [gymnastics, weightlifting, cardio]

    static let gymnastics = SkillCategoryDefinition(
        id: "gymnastics",
        name: "体操",
        englishName: "Gymnastics",
        icon: "figure.gymnastics",
        color: Color(hex: "#5E81F4"),
        skills: [
            SkillDefinition(id: "gym_pushup", name: "俯卧撑", englishName: "Push-up", tier: .t0, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_situp", name: "仰卧起坐", englishName: "Sit-up", tier: .t0, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_airsquat", name: "空气深蹲", englishName: "Air Squat", tier: .t0, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_boxjump", name: "跳箱", englishName: "Box Jump", tier: .t0, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_burpee", name: "波比跳", englishName: "Burpee", tier: .t0, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_hollowhold", name: "空心体保持", englishName: "Hollow Hold", tier: .t0, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_ringrow", name: "辅助引体", englishName: "Ring Row", tier: .t0, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_pullup", name: "引体向上", englishName: "Pull-up", tier: .t1, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_dip", name: "双杠臂屈伸", englishName: "Dip", tier: .t1, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_ringsupport", name: "环上支撑", englishName: "Ring Support", tier: .t1, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_hspu", name: "手倒立俯卧撑", englishName: "Handstand Push-up", tier: .t1, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_muscleup_bar", name: "杠上肌肉上翻", englishName: "Bar Muscle-up", tier: .t2, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_muscleup_ring", name: "环上肌肉上翻", englishName: "Ring Muscle-up", tier: .t2, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_butterfly", name: "蝴蝶引体", englishName: "Butterfly Pull-up", tier: .t2, categoryId: "gymnastics"),
            SkillDefinition(id: "gym_ropeClimb", name: "绳索攀爬", englishName: "Rope Climb", tier: .t2, categoryId: "gymnastics"),
        ]
    )

    static let weightlifting = SkillCategoryDefinition(
        id: "weightlifting",
        name: "举重",
        englishName: "Weightlifting",
        icon: "figure.strengthtraining.traditional",
        color: Color(hex: "#F5A623"),
        skills: [
            SkillDefinition(id: "wl_deadlift", name: "硬拉", englishName: "Deadlift", tier: .t0, categoryId: "weightlifting"),
            SkillDefinition(id: "wl_squat", name: "深蹲", englishName: "Back Squat", tier: .t0, categoryId: "weightlifting"),
            SkillDefinition(id: "wl_press", name: "推举", englishName: "Strict Press", tier: .t0, categoryId: "weightlifting"),
            SkillDefinition(id: "wl_row", name: "划船", englishName: "Bent-over Row", tier: .t0, categoryId: "weightlifting"),
            SkillDefinition(id: "wl_frontsquat", name: "前蹲", englishName: "Front Squat", tier: .t1, categoryId: "weightlifting"),
            SkillDefinition(id: "wl_hangsnatch", name: "悬垂抓举", englishName: "Hang Power Snatch", tier: .t1, categoryId: "weightlifting"),
            SkillDefinition(id: "wl_hangclean", name: "悬垂挺举", englishName: "Hang Power Clean", tier: .t1, categoryId: "weightlifting"),
            SkillDefinition(id: "wl_pushpress", name: "借力推举", englishName: "Push Press", tier: .t1, categoryId: "weightlifting"),
            SkillDefinition(id: "wl_snatch", name: "抓举", englishName: "Snatch", tier: .t2, categoryId: "weightlifting"),
            SkillDefinition(id: "wl_clean", name: "挺举", englishName: "Clean & Jerk", tier: .t2, categoryId: "weightlifting"),
            SkillDefinition(id: "wl_splitjerk", name: "分腿挺举", englishName: "Split Jerk", tier: .t2, categoryId: "weightlifting"),
        ]
    )

    static let cardio = SkillCategoryDefinition(
        id: "cardio",
        name: "有氧",
        englishName: "Monostructural",
        icon: "heart.circle.fill",
        color: Color(hex: "#34C759"),
        skills: [
            SkillDefinition(id: "card_run", name: "跑步", englishName: "Running", tier: .t0, categoryId: "cardio"),
            SkillDefinition(id: "card_rower", name: "划船机", englishName: "Rowing", tier: .t0, categoryId: "cardio"),
            SkillDefinition(id: "card_jumprope", name: "单摇跳绳", englishName: "Single-under", tier: .t0, categoryId: "cardio"),
            SkillDefinition(id: "card_du", name: "双摇跳绳", englishName: "Double-under", tier: .t1, categoryId: "cardio"),
            SkillDefinition(id: "card_kb", name: "壶铃摆动", englishName: "Kettlebell Swing", tier: .t1, categoryId: "cardio"),
            SkillDefinition(id: "card_sledge", name: "攻城锤", englishName: "Sledgehammer", tier: .t1, categoryId: "cardio"),
            SkillDefinition(id: "card_echobike", name: "Echo Bike", englishName: "Echo Bike", tier: .t2, categoryId: "cardio"),
            SkillDefinition(id: "card_skierg", name: "Ski Erg", englishName: "Ski Erg", tier: .t2, categoryId: "cardio"),
        ]
    )
}
