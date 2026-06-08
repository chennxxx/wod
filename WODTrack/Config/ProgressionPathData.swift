import Foundation
import SwiftUI

// MARK: - ProgressionPath

struct ProgressionPath: Identifiable {
    let id: String
    let name: String
    let icon: String
    let categoryId: String
    let steps: [String]
}

// MARK: - ProgressionPathLibrary

enum ProgressionPathLibrary {
    static let all: [ProgressionPath] = gymnasticsPaths + weightliftingPaths

    static let gymnasticsPaths: [ProgressionPath] = [
        ProgressionPath(
            id: "path_pulling",
            name: "拉类主线",
            icon: "arrow.up.to.line.circle.fill",
            categoryId: "gymnastics",
            steps: [
                "gym_dead_hang",
                "gym_ring_row",
                "gym_strict_pullup",
                "gym_kipping_pullup",
                "gym_butterfly_pullup",
                "gym_strict_c2b",
                "gym_strict_bar_mu",
                "gym_kipping_bar_mu",
                "gym_strict_ring_mu",
                "gym_rope_climb",
            ]
        ),
        ProgressionPath(
            id: "path_pushing",
            name: "推类主线",
            icon: "figure.strengthtraining.functional",
            categoryId: "gymnastics",
            steps: [
                "gym_pushup",
                "gym_ring_pushup",
                "gym_dip",
                "gym_ring_dip",
                "gym_wall_walk",
                "gym_strict_hspu",
                "gym_kipping_hspu",
                "gym_deficit_hspu",
            ]
        ),
        ProgressionPath(
            id: "path_handstand",
            name: "倒立主线",
            icon: "figure.handball",
            categoryId: "gymnastics",
            steps: [
                "gym_wall_walk",
                "gym_handstand_hold",
                "gym_handstand_walk",
                "gym_handstand_pirouette",
                "gym_straddle_press_hs",
            ]
        ),
        ProgressionPath(
            id: "path_core",
            name: "核心主线",
            icon: "flame.fill",
            categoryId: "gymnastics",
            steps: [
                "gym_hollow_hold",
                "gym_strict_kte",
                "gym_strict_ttb",
                "gym_kipping_ttb",
                "gym_l_sit",
                "gym_hanging_l_sit",
                "gym_windshield_wiper",
            ]
        ),
        ProgressionPath(
            id: "path_jump_rope",
            name: "跳绳主线",
            icon: "circle.dashed",
            categoryId: "gymnastics",
            steps: [
                "gym_single_under",
                "gym_double_under",
            ]
        ),
        ProgressionPath(
            id: "path_pistol",
            name: "单腿深蹲主线",
            icon: "figure.step.training",
            categoryId: "gymnastics",
            steps: [
                "gym_box_stepup",
                "gym_pistol",
            ]
        ),
    ]

    static let weightliftingPaths: [ProgressionPath] = [
        ProgressionPath(
            id: "path_squat",
            name: "深蹲主线",
            icon: "arrow.down.to.line.circle.fill",
            categoryId: "weightlifting",
            steps: [
                "wl_air_squat",
                "wl_goblet_squat",
                "wl_front_squat",
                "wl_back_squat",
                "wl_overhead_squat",
            ]
        ),
        ProgressionPath(
            id: "path_press",
            name: "推举主线",
            icon: "arrow.up.circle.fill",
            categoryId: "weightlifting",
            steps: [
                "wl_strict_press",
                "wl_push_press",
                "wl_push_jerk",
                "wl_split_jerk",
            ]
        ),
        ProgressionPath(
            id: "path_deadlift",
            name: "硬拉主线",
            icon: "arrow.down.circle.fill",
            categoryId: "weightlifting",
            steps: [
                "wl_good_morning",
                "wl_rdl",
                "wl_deadlift",
                "wl_sumo_deadlift",
                "wl_sdhp",
            ]
        ),
        ProgressionPath(
            id: "path_clean",
            name: "上挺主线",
            icon: "arrow.2.circlepath.circle.fill",
            categoryId: "weightlifting",
            steps: [
                "wl_mb_clean",
                "wl_hang_power_clean",
                "wl_power_clean",
                "wl_hang_clean",
                "wl_squat_clean",
                "wl_clean_jerk",
            ]
        ),
        ProgressionPath(
            id: "path_snatch",
            name: "抓举主线",
            icon: "trophy.circle.fill",
            categoryId: "weightlifting",
            steps: [
                "wl_overhead_squat",
                "wl_muscle_snatch",
                "wl_hang_power_snatch",
                "wl_power_snatch",
                "wl_hang_snatch",
                "wl_squat_snatch",
            ]
        ),
    ]
}
