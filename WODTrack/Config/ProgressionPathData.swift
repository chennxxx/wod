import Foundation
import SwiftUI

// ⚠️ 本文件由 scripts/gen_progressionpath.py 从 CF解锁路径 xlsx 生成，请勿手改；改数据请更新 xlsx 后重跑脚本。

// MARK: - ProgressionPath

struct ProgressionPath: Identifiable {
    let id: String
    let name: String
    /// 英文路线名（来自 xlsx；空则运行时回退中文）。
    var englishName: String = ""
    let icon: String
    /// 代表/目标动作（动作ID），仅作路线身份，不作为站点。
    let targetSkillId: String
    /// 路径说明，展示在路线详情页顶部。
    let intro: String
    /// 英文路径说明（来自 xlsx；空则运行时回退中文）。
    var englishIntro: String = ""
    /// 需按顺序依次解锁的动作 id 序列（metro 站点）。
    let steps: [String]
}

// MARK: - ProgressionPathLibrary

enum ProgressionPathLibrary {
    static let all: [ProgressionPath] = [
        ProgressionPath(
            id: "path_1",
            name: "跳绳",
            englishName: "Jump Rope",
            icon: "circle.dashed",
            targetSkillId: "double_under",
            intro: "先掌握单摇跳绳，能单次连续完成 100 次后，进入“单-单-双”的混合节奏，熟练之后再过渡到连续双摇跳绳。",
            englishIntro: "First master the single under; once you can complete 100 unbroken reps in a row, move to a mixed “single-single-double” rhythm, and once that feels smooth, progress to continuous double unders.",
            steps: [
                "single_under",
                "double_under",
            ]
        ),
        ProgressionPath(
            id: "path_2",
            name: "倒立",
            englishName: "Handstand",
            icon: "figure.handball",
            targetSkillId: "handstand",
            intro: "进入倒立前需要肩上推举的过头支撑力量、俯卧撑的基础推力、平板与空心体的核心控制，并先用爬墙倒立建立倒立适应。练成自由倒立分四个阶段，每阶以保持时长过关：先面墙靠墙保持（做到 8 组×30 秒），再背墙踢腿上倒立（8 组×30 秒），然后离墙漂浮找平衡（3–4 组×30 秒），最后自由站立踢起——先踢低、由单腿带动，逐渐双脚并拢稳住。练成后会打开两条线：平衡位移线通向倒立行走；推力线依次通向倒立俯卧撑、严格倒立俯卧撑、吊环倒立俯卧撑。",
            englishIntro: "Before working toward the handstand you need the overhead support strength of the shoulder press, the basic pressing strength of the push-up, and the core control of the plank and hollow body; use the wall climb first to build comfort being inverted. Reaching a freestanding handstand has four stages, each cleared by hold time: first a chest-to-wall hold (build to 8 sets × 30 s), then kicking up to a back-to-wall handstand (8 sets × 30 s), then floating off the wall to find your balance (3–4 sets × 30 s), and finally a freestanding kick-up—start with a low kick led by one leg, then gradually bring the feet together and hold steady. Once achieved, it opens two lines: a balance/locomotion line leading to the handstand walk, and a pressing line leading in turn to the handstand push-up, the strict handstand push-up, and the ring handstand push-up.",
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
            englishName: "Bar Muscle-Up",
            icon: "arrow.up.to.line.circle.fill",
            targetSkillId: "bar_muscle_up",
            intro: "它需要三条能力线同时到位。拉力线从吊环划船到严格引体向上（先能连续 5 个以上、理想 7–10 个），再到借力引体向上和胸触杠引体向上，关键是能把身体拉到胸骨甚至肚脐过杠；推力线要能做 5 个以上双杠臂屈伸，保证翻杠后撑得起来；核心线靠脚触杠，控制摆动时身体不散。三线达标后再攻翻杠过渡：先练 hollow↔arch 的摆动节奏，再在摆动顶点用高位拉把杠拉到髋部，借跳跃或弹力带反复体会翻肘越杠的瞬间，最后串成完整动作。练成后可进阶到波比单杠双力臂。",
            englishIntro: "It requires three lines of ability to be in place at the same time. The pulling line runs from the ring row to the strict pull-up (first 5+ in a row, ideally 7–10), then to the kipping pull-up and the chest-to-bar pull-up—the key is pulling the body high enough that the sternum, or even the navel, clears the bar. The pressing line needs 5+ bar dips so you can press out after the transition. The core line relies on toes-to-bar to keep the body tight and controlled through the swing. Once all three are met, attack the transition over the bar: first drill the hollow↔arch swing rhythm, then at the peak of the swing use a high pull to bring the bar to the hips, and use jumps or a band to repeatedly feel the moment of turning the elbows over the bar, finally linking it into the full movement. After mastering it, you can progress to the burpee bar muscle-up.",
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
            englishName: "Pull-Up",
            icon: "figure.strengthtraining.functional",
            targetSkillId: "pull_up",
            intro: "从吊环划船这种可调高度的自重划船入门，建立基础拉力与握力；再通过静止悬挂和离心下放打底，练到能完成数个严格引体向上；在严格力量的基础上加入摆动节奏，过渡到借力引体向上；之后把身体拉得更高、让胸骨触杠，进阶为胸触杠引体向上，并进一步到借力胸触杠引体向上。这条线练扎实后，可由严格引体和胸触杠分叉，通向单杠双力臂、吊环双力臂等。",
            englishIntro: "Begin with the ring row, a height-adjustable bodyweight row, to build basic pulling strength and grip; then lay a foundation with dead hangs and eccentric lowers until you can complete several strict pull-ups; on that strict-strength base, add a swing rhythm to progress to the kipping pull-up; then pull the body higher so the sternum touches the bar, advancing to the chest-to-bar pull-up and on to the kipping chest-to-bar pull-up. Once this line is solid, it branches from the strict and chest-to-bar pull-ups toward the bar muscle-up, the ring muscle-up, and similar skills.",
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
            englishName: "Toes-to-Bar",
            icon: "flame.fill",
            targetSkillId: "toes_to_bar",
            intro: "先从主动悬挂开始，握杠、肩部下沉收紧，建立握力与肩部稳定；再做膝触肘，练悬垂屈膝的核心发力；进而过渡到直腿悬垂举腿，这是从屈膝到直腿的关键力量门槛；接着练 hollow↔arch 的摆动节奏，借摆动把脚送上杠并控制不晃，最后串成完整的脚触杠。它作为核心控制线，可汇入单杠双力臂。",
            englishIntro: "Start with an active hang—grip the bar and pull the shoulders down and tight to build grip and shoulder stability; then do knees-to-elbows to train the hanging knee-tuck core action; progress to straight-leg hanging leg raises, the key strength threshold from bent to straight legs; next drill the hollow↔arch swing rhythm, using the swing to send the feet to the bar while staying controlled, and finally link it into the full toes-to-bar. As a core-control line, it feeds into the bar muscle-up.",
            steps: [
                "knees_to_elbows",
                "toes_to_bar",
            ]
        )
    ]
}
