import Foundation
import SwiftUI

// MARK: - SkillTier

enum SkillTier: String, CaseIterable, Identifiable, Codable {
    case l1, l2, l3, l4, l5
    var id: String { rawValue }

    var label: String {
        switch self {
        case .l1: "L1"
        case .l2: "L2"
        case .l3: "L3"
        case .l4: "L4"
        case .l5: "L5"
        }
    }

    var description: String {
        switch self {
        case .l1: "入门"
        case .l2: "基础"
        case .l3: "进阶"
        case .l4: "高阶"
        case .l5: "精英"
        }
    }

    var color: Color {
        switch self {
        case .l1: Color(hex: "#34C759")
        case .l2: Color(hex: "#5E81F4")
        case .l3: Color(hex: "#F5A623")
        case .l4: Color(hex: "#FF6B6B")
        case .l5: Color(hex: "#9B59B6")
        }
    }
}

// MARK: - SkillSubcategoryDefinition

struct SkillSubcategoryDefinition: Identifiable {
    let id: String
    let name: String
    let categoryId: String
}

// MARK: - SkillDefinition

struct SkillDefinition: Identifiable {
    let id: String
    let name: String
    let englishName: String
    let tier: SkillTier
    let categoryId: String
    let subcategoryId: String
    let prerequisites: [String]
    let unlockCondition: String?

    init(id: String, name: String, englishName: String, tier: SkillTier,
         categoryId: String, subcategoryId: String,
         prerequisites: [String] = [], unlockCondition: String? = nil) {
        self.id = id; self.name = name; self.englishName = englishName
        self.tier = tier; self.categoryId = categoryId; self.subcategoryId = subcategoryId
        self.prerequisites = prerequisites; self.unlockCondition = unlockCondition
    }
}

// MARK: - SkillCategoryDefinition

struct SkillCategoryDefinition: Identifiable {
    let id: String
    let name: String
    let englishName: String
    let icon: String
    let color: Color
    let subcategories: [SkillSubcategoryDefinition]
    let skills: [SkillDefinition]
}

// MARK: - SkillLibrary

enum SkillLibrary {
    static let categories: [SkillCategoryDefinition] = [gymnastics, weightlifting]

    static var allSkills: [SkillDefinition] { categories.flatMap { $0.skills } }
    static var skillById: [String: SkillDefinition] {
        Dictionary(uniqueKeysWithValues: allSkills.map { ($0.id, $0) })
    }

    // MARK: Gymnastics (49)

    static let gymnastics = SkillCategoryDefinition(
        id: "gymnastics",
        name: "体操",
        englishName: "Gymnastics",
        icon: "figure.gymnastics",
        color: Color(hex: "#5E81F4"),
        subcategories: [
            SkillSubcategoryDefinition(id: "gym_pulling",   name: "拉类",     categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_pushing",   name: "推类",     categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_handstand", name: "倒立类",   categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_core",      name: "核心与保持", categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_skills",    name: "技巧与体重", categoryId: "gymnastics"),
        ],
        skills: gymnasticSkills
    )

    private static let gymnasticSkills: [SkillDefinition] = [
        // MARK: 拉类 Pulling (16)
        g("gym_dead_hang",        "死悬",              "Dead Hang",             .l1, "gym_pulling"),
        g("gym_ring_row",         "吊环划船",           "Ring Row",              .l1, "gym_pulling"),
        g("gym_pull_over",        "拉过杠",             "Pull-over",             .l2, "gym_pulling",
          prereqs: ["gym_dead_hang"]),
        g("gym_strict_pullup",    "严格引体向上",        "Strict Pull-up",        .l2, "gym_pulling",
          prereqs: ["gym_dead_hang", "gym_ring_row"],
          unlock: "可连续完成 5+ 个"),
        g("gym_kipping_pullup",   "Kipping 引体向上",   "Kipping Pull-up",       .l3, "gym_pulling",
          prereqs: ["gym_strict_pullup", "gym_hollow_hold"],
          unlock: "严格引体 3+ 个"),
        g("gym_butterfly_pullup", "蝶式引体向上",        "Butterfly Pull-up",     .l3, "gym_pulling",
          prereqs: ["gym_kipping_pullup"],
          unlock: "Kipping 引体连续 10+ 个"),
        g("gym_strict_c2b",       "严格胸触杠引体",      "Strict Chest-to-Bar",   .l3, "gym_pulling",
          prereqs: ["gym_strict_pullup"],
          unlock: "严格引体向上 8+ 个"),
        g("gym_kipping_c2b",      "Kipping 胸触杠引体", "Kipping Chest-to-Bar",  .l4, "gym_pulling",
          prereqs: ["gym_kipping_pullup", "gym_strict_c2b"]),
        g("gym_l_pullup",         "L 形引体",          "L Pull-up",             .l4, "gym_pulling",
          prereqs: ["gym_strict_pullup", "gym_hanging_l_sit"]),
        g("gym_strict_bar_mu",    "严格杠上双力臂",      "Strict Bar Muscle-up",  .l4, "gym_pulling",
          prereqs: ["gym_strict_c2b", "gym_dip"],
          unlock: "胸触杠引体 5+ 个 + 双杠臂屈伸 5+ 个"),
        g("gym_kipping_bar_mu",   "Kipping 杠上双力臂", "Kipping Bar Muscle-up", .l5, "gym_pulling",
          prereqs: ["gym_kipping_pullup", "gym_strict_bar_mu"]),
        g("gym_strict_ring_mu",   "严格吊环双力臂",      "Strict Ring Muscle-up", .l5, "gym_pulling",
          prereqs: ["gym_strict_pullup", "gym_ring_dip"],
          unlock: "严格引体 5+ 个 + 吊环臂屈伸 5+ 个"),
        g("gym_kipping_ring_mu",  "Kipping 吊环双力臂", "Kipping Ring Muscle-up",.l5, "gym_pulling",
          prereqs: ["gym_strict_ring_mu"]),
        g("gym_rope_climb",       "爬绳",              "Rope Climb",            .l3, "gym_pulling",
          prereqs: ["gym_dead_hang", "gym_strict_pullup"],
          unlock: "死悬 60 秒 + 严格引体 4+ 个"),
        g("gym_legless_rope",     "无腿爬绳",           "Legless Rope Climb",    .l4, "gym_pulling",
          prereqs: ["gym_rope_climb"],
          unlock: "严格引体 8+ 个"),
        g("gym_l_rope_climb",     "L 形爬绳",          "L-sit Rope Climb",      .l5, "gym_pulling",
          prereqs: ["gym_rope_climb", "gym_l_sit"]),

        // MARK: 推类 Pushing (9)
        g("gym_pushup",            "俯卧撑",           "Push-up",               .l1, "gym_pushing"),
        g("gym_ring_pushup",       "吊环俯卧撑",        "Ring Push-up",          .l2, "gym_pushing",
          prereqs: ["gym_pushup"],
          unlock: "俯卧撑 10+ 个"),
        g("gym_dip",               "双杠臂屈伸",        "Dip",                   .l2, "gym_pushing",
          prereqs: ["gym_pushup"],
          unlock: "俯卧撑 10+ 个"),
        g("gym_ring_dip",          "吊环臂屈伸",        "Ring Dip",              .l3, "gym_pushing",
          prereqs: ["gym_dip", "gym_ring_support_hold"],
          unlock: "双杠臂屈伸 5+ 个"),
        g("gym_wall_walk",         "爬墙",             "Wall Walk",             .l2, "gym_pushing",
          prereqs: ["gym_pushup"]),
        g("gym_strict_hspu",       "严格倒立俯卧撑",    "Strict HSPU",           .l4, "gym_pushing",
          prereqs: ["gym_wall_walk", "gym_handstand_hold"],
          unlock: "俯卧撑 15+ 个"),
        g("gym_kipping_hspu",      "Kipping 倒立俯卧撑","Kipping HSPU",          .l4, "gym_pushing",
          prereqs: ["gym_strict_hspu"],
          unlock: "严格 HSPU 3+ 个"),
        g("gym_deficit_hspu",      "亏位倒立俯卧撑",    "Deficit HSPU",          .l5, "gym_pushing",
          prereqs: ["gym_kipping_hspu"]),
        g("gym_freestanding_hspu", "自由倒立俯卧撑",    "Freestanding HSPU",     .l5, "gym_pushing",
          prereqs: ["gym_handstand_walk", "gym_strict_hspu"],
          unlock: "自由倒立保持 30+ 秒"),

        // MARK: 倒立类 Handstand (4)
        g("gym_handstand_hold",      "倒立保持",   "Handstand Hold",              .l2, "gym_handstand",
          prereqs: ["gym_wall_walk"]),
        g("gym_handstand_walk",      "倒立行走",   "Handstand Walk",              .l4, "gym_handstand",
          prereqs: ["gym_handstand_hold"],
          unlock: "靠墙倒立保持 30+ 秒"),
        g("gym_handstand_pirouette", "倒立转体",   "Handstand Pirouette",         .l5, "gym_handstand",
          prereqs: ["gym_handstand_walk"]),
        g("gym_straddle_press_hs",   "分腿压倒立", "Straddle Press to Handstand", .l5, "gym_handstand",
          prereqs: ["gym_handstand_hold", "gym_l_sit"]),

        // MARK: 核心与保持 Core & Holds (10)
        g("gym_hollow_hold",       "空心体保持",    "Hollow Hold",              .l1, "gym_core"),
        g("gym_situp",             "仰卧起坐",      "Sit-up",                   .l1, "gym_core"),
        g("gym_ghd_situp",         "GHD 仰卧起坐", "GHD Sit-up",               .l2, "gym_core",
          prereqs: ["gym_situp"]),
        g("gym_l_sit",             "L 形支撑",     "L-sit",                    .l2, "gym_core",
          prereqs: ["gym_hollow_hold"]),
        g("gym_ring_support_hold", "吊环支撑保持",  "Ring Support Hold",         .l2, "gym_core",
          prereqs: ["gym_dip"]),
        g("gym_strict_kte",        "严格屈膝触肘",  "Strict Knees-to-Elbows",   .l2, "gym_core",
          prereqs: ["gym_dead_hang"]),
        g("gym_skin_the_cat",      "猫式翻转",      "Skin the Cat",             .l3, "gym_core",
          prereqs: ["gym_dead_hang"]),
        g("gym_hanging_l_sit",     "悬挂 L 形",    "Hanging L-sit",            .l3, "gym_core",
          prereqs: ["gym_dead_hang", "gym_l_sit"],
          unlock: "死悬 60 秒"),
        g("gym_strict_ttb",        "严格脚触杠",    "Strict Toes-to-Bar",       .l3, "gym_core",
          prereqs: ["gym_strict_kte", "gym_hanging_l_sit"]),
        g("gym_kipping_ttb",       "Kipping 脚触杠","Kipping Toes-to-Bar",      .l3, "gym_core",
          prereqs: ["gym_kipping_pullup", "gym_strict_kte"]),

        // MARK: 技巧与体重 Skills & Bodyweight (10)
        g("gym_box_stepup",          "踏箱",    "Box Step-up",               .l1, "gym_skills"),
        g("gym_single_under",        "单摇跳绳", "Single-under",              .l1, "gym_skills"),
        g("gym_burpee",              "波比跳",   "Burpee",                    .l2, "gym_skills",
          prereqs: ["gym_pushup"]),
        g("gym_box_jump",            "跳箱",    "Box Jump",                  .l2, "gym_skills",
          prereqs: ["gym_box_stepup"]),
        g("gym_double_under",        "双摇跳绳", "Double-under",              .l2, "gym_skills",
          prereqs: ["gym_single_under"],
          unlock: "单摇连续 50 个不间断"),
        g("gym_windshield_wiper",    "雨刷",    "Windshield Wiper",          .l4, "gym_core",
          prereqs: ["gym_hanging_l_sit", "gym_strict_ttb"]),
        g("gym_shoot_through",       "穿越",    "Shoot-through",             .l3, "gym_skills",
          prereqs: ["gym_l_sit", "gym_dip"]),
        g("gym_pistol",              "单腿深蹲", "Pistol Squat",              .l3, "gym_skills",
          prereqs: ["gym_box_stepup"]),
        g("gym_forward_roll",        "支撑前滚", "Forward Roll from Support", .l2, "gym_skills"),
        g("gym_swing_backward_roll", "支撑后滚", "Swing to Backward Roll",   .l3, "gym_skills",
          prereqs: ["gym_dead_hang"]),
    ]

    // MARK: Weightlifting (35)

    static let weightlifting = SkillCategoryDefinition(
        id: "weightlifting",
        name: "举重",
        englishName: "Weightlifting",
        icon: "figure.strengthtraining.traditional",
        color: Color(hex: "#F5A623"),
        subcategories: [
            SkillSubcategoryDefinition(id: "wl_squat",  name: "深蹲系列",  categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_press",  name: "推举系列",  categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_hinge",  name: "铰链/拉类", categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_clean",  name: "上挺系列",  categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_snatch", name: "抓举系列",  categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_combo",  name: "组合动作",  categoryId: "weightlifting"),
        ],
        skills: weightliftingSkills
    )

    private static let weightliftingSkills: [SkillDefinition] = [
        // MARK: 深蹲系列 Squat (5)
        w("wl_air_squat",      "空气深蹲",    "Air Squat",         .l1, "wl_squat"),
        w("wl_goblet_squat",   "Goblet 深蹲", "Goblet Squat",      .l1, "wl_squat",
          prereqs: ["wl_air_squat"]),
        w("wl_back_squat",     "后蹲",        "Back Squat",        .l2, "wl_squat",
          prereqs: ["wl_air_squat"]),
        w("wl_front_squat",    "前蹲",        "Front Squat",       .l2, "wl_squat",
          prereqs: ["wl_air_squat", "wl_goblet_squat"]),
        w("wl_overhead_squat", "过头深蹲",    "Overhead Squat",    .l3, "wl_squat",
          prereqs: ["wl_front_squat", "wl_strict_press"]),

        // MARK: 推举系列 Press (4)
        w("wl_strict_press", "严格推举", "Strict Press", .l1, "wl_press"),
        w("wl_push_press",   "借力推举", "Push Press",   .l2, "wl_press",
          prereqs: ["wl_strict_press"]),
        w("wl_push_jerk",    "推举蹲接", "Push Jerk",    .l3, "wl_press",
          prereqs: ["wl_push_press", "wl_overhead_squat"]),
        w("wl_split_jerk",   "分腿挺举", "Split Jerk",   .l4, "wl_press",
          prereqs: ["wl_push_jerk"]),

        // MARK: 铰链/拉类 Hinge & Pull (6)
        w("wl_good_morning",  "早安动作",    "Good Morning",      .l1, "wl_hinge"),
        w("wl_rdl",           "罗马尼亚硬拉", "Romanian Deadlift", .l1, "wl_hinge"),
        w("wl_bent_row",      "弯腰划船",    "Bent-over Row",     .l1, "wl_hinge"),
        w("wl_deadlift",      "硬拉",        "Deadlift",          .l1, "wl_hinge",
          prereqs: ["wl_air_squat", "wl_good_morning", "wl_rdl"]),
        w("wl_sumo_deadlift", "相扑硬拉",    "Sumo Deadlift",     .l2, "wl_hinge",
          prereqs: ["wl_deadlift"]),
        w("wl_sdhp",          "相扑硬拉高拉", "SDHP",              .l2, "wl_hinge",
          prereqs: ["wl_sumo_deadlift"]),

        // MARK: 上挺系列 Clean (6)
        w("wl_mb_clean",         "药球上挺",    "Medicine Ball Clean", .l1, "wl_clean",
          prereqs: ["wl_air_squat", "wl_deadlift"]),
        w("wl_hang_power_clean", "悬挂借力上挺", "Hang Power Clean",    .l2, "wl_clean",
          prereqs: ["wl_deadlift", "wl_front_squat", "wl_sdhp"]),
        w("wl_power_clean",      "借力上挺",    "Power Clean",         .l3, "wl_clean",
          prereqs: ["wl_hang_power_clean"]),
        w("wl_hang_clean",       "悬挂深蹲上挺", "Hang Clean",          .l3, "wl_clean",
          prereqs: ["wl_hang_power_clean", "wl_front_squat"]),
        w("wl_squat_clean",      "深蹲上挺",    "Squat Clean",         .l4, "wl_clean",
          prereqs: ["wl_hang_clean", "wl_power_clean"]),
        w("wl_clean_jerk",       "上挺加挺举",  "Clean & Jerk",        .l5, "wl_clean",
          prereqs: ["wl_squat_clean", "wl_split_jerk"]),

        // MARK: 抓举系列 Snatch (7)
        w("wl_muscle_snatch",     "肌肉抓举",    "Muscle Snatch",       .l2, "wl_snatch",
          prereqs: ["wl_strict_press", "wl_overhead_squat"]),
        w("wl_hang_power_snatch", "悬挂借力抓举", "Hang Power Snatch",   .l2, "wl_snatch",
          prereqs: ["wl_overhead_squat", "wl_muscle_snatch", "wl_sdhp"]),
        w("wl_snatch_balance",    "抓举平衡",    "Snatch Balance",      .l3, "wl_snatch",
          prereqs: ["wl_overhead_squat", "wl_push_jerk"]),
        w("wl_power_snatch",      "借力抓举",    "Power Snatch",        .l3, "wl_snatch",
          prereqs: ["wl_hang_power_snatch", "wl_deadlift"]),
        w("wl_hang_snatch",       "悬挂深蹲抓举", "Hang Snatch",         .l4, "wl_snatch",
          prereqs: ["wl_hang_power_snatch", "wl_overhead_squat"]),
        w("wl_sots_press",        "Sots 推举",   "Sots Press",          .l4, "wl_snatch",
          prereqs: ["wl_overhead_squat", "wl_strict_press"]),
        w("wl_squat_snatch",      "深蹲抓举",    "Squat Snatch",        .l5, "wl_snatch",
          prereqs: ["wl_hang_snatch", "wl_power_snatch", "wl_snatch_balance"]),

        // MARK: 组合动作 Combo (7)
        w("wl_lunge",          "弓步蹲",      "Lunge",                  .l1, "wl_combo"),
        w("wl_kb_swing",       "壶铃摆荡",    "Kettlebell Swing",        .l1, "wl_combo",
          prereqs: ["wl_deadlift", "wl_rdl"]),
        w("wl_thruster",       "推力蹲",      "Thruster",               .l2, "wl_combo",
          prereqs: ["wl_front_squat", "wl_push_press"]),
        w("wl_wall_ball",      "投墙球",      "Wall Ball Shot",          .l2, "wl_combo",
          prereqs: ["wl_front_squat", "wl_push_press"]),
        w("wl_bulgarian_split","保加利亚分腿蹲","Bulgarian Split Squat",  .l2, "wl_combo",
          prereqs: ["wl_air_squat", "wl_lunge"]),
        w("wl_kb_snatch",      "壶铃抓举",    "Kettlebell Snatch",       .l3, "wl_combo",
          prereqs: ["wl_kb_swing"]),
        w("wl_clean_pull",     "上挺高拉",    "Clean Pull",             .l2, "wl_combo",
          prereqs: ["wl_deadlift"]),
    ]

    // MARK: - Helpers

    private static func g(_ id: String, _ name: String, _ en: String, _ tier: SkillTier, _ sub: String,
                          prereqs: [String] = [], unlock: String? = nil) -> SkillDefinition {
        SkillDefinition(id: id, name: name, englishName: en, tier: tier,
                        categoryId: "gymnastics", subcategoryId: sub,
                        prerequisites: prereqs, unlockCondition: unlock)
    }

    private static func w(_ id: String, _ name: String, _ en: String, _ tier: SkillTier, _ sub: String,
                          prereqs: [String] = [], unlock: String? = nil) -> SkillDefinition {
        SkillDefinition(id: id, name: name, englishName: en, tier: tier,
                        categoryId: "weightlifting", subcategoryId: sub,
                        prerequisites: prereqs, unlockCondition: unlock)
    }
}
