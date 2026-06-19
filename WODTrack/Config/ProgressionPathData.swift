import Foundation
import SwiftUI

// ⚠️ 本文件由 scripts/gen_progressionpath.py 从 CF解锁路径 xlsx 生成，请勿手改；改数据请更新 xlsx 后重跑脚本。

// MARK: - ProgressionPath

struct ProgressionPath: Identifiable {
    let id: String
    let name: String
    let icon: String
    /// 代表/目标动作（动作ID），仅作路线身份，不作为站点。
    let targetSkillId: String
    /// 路径说明，展示在路线详情页顶部。
    let intro: String
    /// 需按顺序依次解锁的动作 id 序列（metro 站点）。
    let steps: [String]
}

// MARK: - ProgressionPathLibrary

enum ProgressionPathLibrary {
    static let all: [ProgressionPath] = [
        ProgressionPath(
            id: "path_1",
            name: "跳绳",
            icon: "circle.dashed",
            targetSkillId: "double_under",
            intro: "先掌握单摇跳绳，能单次连续完成 100 次后，进入“单-单-双”的混合节奏，熟练之后再过渡到连续双摇跳绳。",
            steps: [
                "single_under",
                "double_under",
            ]
        ),
        ProgressionPath(
            id: "path_2",
            name: "倒立",
            icon: "figure.handball",
            targetSkillId: "handstand",
            intro: "进入倒立前需要肩上推举的过头支撑力量、俯卧撑的基础推力、平板与空心体的核心控制，并先用爬墙倒立建立倒立适应。练成自由倒立分四个阶段，每阶以保持时长过关：先面墙靠墙保持（做到 8 组×30 秒），再背墙踢腿上倒立（8 组×30 秒），然后离墙漂浮找平衡（3–4 组×30 秒），最后自由站立踢起——先踢低、由单腿带动，逐渐双脚并拢稳住。练成后会打开两条线：平衡位移线通向倒立行走；推力线依次通向倒立俯卧撑、严格倒立俯卧撑、吊环倒立俯卧撑。",
            steps: [
                "push_up",
                "shoulder_press",
                "wall_climb",
                "handstand",
                "handstand_walk",
                "handstand_push_up",
                "strict_handstand_push_up",
                "ring_handstand_push_up",
            ]
        ),
        ProgressionPath(
            id: "path_3",
            name: "单杠双力臂",
            icon: "arrow.up.to.line.circle.fill",
            targetSkillId: "bar_muscle_up",
            intro: "它需要三条能力线同时到位。拉力线从吊环划船到严格引体向上（先能连续 5 个以上、理想 7–10 个），再到借力引体向上和胸触杠引体向上，关键是能把身体拉到胸骨甚至肚脐过杠；推力线要能做 5 个以上双杠臂屈伸，保证翻杠后撑得起来；核心线靠脚触杠，控制摆动时身体不散。三线达标后再攻翻杠过渡：先练 hollow↔arch 的摆动节奏，再在摆动顶点用高位拉把杠拉到髋部，借跳跃或弹力带反复体会翻肘越杠的瞬间，最后串成完整动作。练成后可进阶到波比单杠双力臂。",
            steps: [
                "ring_row",
                "strict_pull_up",
                "kipping_pull_up",
                "chest_to_bar_pull_up",
                "bar_dip",
                "toes_to_bar",
            ]
        ),
        ProgressionPath(
            id: "path_4",
            name: "引体向上",
            icon: "figure.strengthtraining.functional",
            targetSkillId: "pull_up",
            intro: "从吊环划船这种可调高度的自重划船入门，建立基础拉力与握力；再通过静止悬挂和离心下放打底，练到能完成数个严格引体向上；在严格力量的基础上加入摆动节奏，过渡到借力引体向上；之后把身体拉得更高、让胸骨触杠，进阶为胸触杠引体向上，并进一步到借力胸触杠引体向上。这条线练扎实后，可由严格引体和胸触杠分叉，通向单杠双力臂、吊环双力臂等。",
            steps: [
                "ring_row",
                "strict_pull_up",
                "kipping_pull_up",
                "chest_to_bar_pull_up",
                "kipping_chest_to_bar_pull_up",
            ]
        ),
        ProgressionPath(
            id: "path_5",
            name: "脚触杠",
            icon: "flame.fill",
            targetSkillId: "toes_to_bar",
            intro: "先从主动悬挂开始，握杠、肩部下沉收紧，建立握力与肩部稳定；再做膝触肘，练悬垂屈膝的核心发力；进而过渡到直腿悬垂举腿，这是从屈膝到直腿的关键力量门槛；接着练 hollow↔arch 的摆动节奏，借摆动把脚送上杠并控制不晃，最后串成完整的脚触杠。它作为核心控制线，可汇入单杠双力臂。",
            steps: [
                "knees_to_elbows",
                "toes_to_bar",
            ]
        )
    ]
}
