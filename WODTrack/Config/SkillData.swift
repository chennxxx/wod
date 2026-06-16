import Foundation
import SwiftUI

// ⚠️ 本文件由 scripts/gen_skilldata.py 从 CF动作库 xlsx 生成，请勿手改；改数据请更新 xlsx 后重跑脚本。

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
    let tier: SkillTier
    let categoryId: String
    let subcategoryId: String
    /// 动作模式（= 子类名称，如「核心」「上肢拉(垂直)」）
    let movementPattern: String
    /// 计量方式（次数 / 静力时长 / 距离 …）
    let measure: String
    /// 动作简介
    let intro: String
    /// 动作步骤
    let steps: String
    /// 要点与注意（部分动作有）
    let keyPoints: String?
    /// 降阶替代
    let scaling: String
    /// 前置动作 id
    let prerequisites: [String]
    /// 前置依据
    let prereqRationale: String?
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

    // MARK: 体操 Gymnastics (56)

    static let gymnastics = SkillCategoryDefinition(
        id: "gymnastics",
        name: "体操",
        englishName: "Gymnastics",
        icon: "figure.gymnastics",
        color: Color(hex: "#5BE88F"),
        subcategories: [
            SkillSubcategoryDefinition(id: "gym_m01", name: "核心", categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_m02", name: "位移有氧", categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_m03", name: "上肢拉(水平)", categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_m04", name: "深蹲", categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_m05", name: "跳跃", categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_m06", name: "弓步单腿", categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_m07", name: "复合全身", categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_m08", name: "上肢推(水平)", categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_m09", name: "上肢推(过头)", categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_m10", name: "上肢拉(垂直)", categoryId: "gymnastics"),
            SkillSubcategoryDefinition(id: "gym_m11", name: "上肢拉(垂直)/核心", categoryId: "gymnastics"),
        ],
        skills: gymnasticSkills
    )

    private static let gymnasticSkills: [SkillDefinition] = [
        s("abmat_sit_up", "AbMat仰卧起坐", "gym_m01", .l1, "核心", "次数",
          intro: "用 AbMat 垫支撑腰背的仰卧起坐。", steps: "脚底相对、腰下垫 AbMat，起身双手触脚前地面，回落肩胛触地。", keyPoints: nil,
          scaling: "屈膝 / 减小幅度", prereqs: [], rationale: "基础动作"),
        s("sit_up", "仰卧起坐", "gym_m01", .l1, "核心", "次数",
          intro: "锻炼核心的起坐动作。", steps: "仰卧脚底相对、双膝外展，双臂过头触地；起身双手前伸触地，肩胛回落触地。", keyPoints: nil,
          scaling: "屈膝仰卧起坐 / 减小幅度", prereqs: [], rationale: "基础动作"),
        s("row", "划船", "gym_m02", .l1, "位移有氧", "距离/卡路里",
          intro: "使用划船机完成有氧输出。", steps: "蹬腿—后倒—拉手柄至肋下，再伸臂—前倾—收腿回位，保持连贯节奏。", keyPoints: nil,
          scaling: "降低目标距离或时间", prereqs: [], rationale: "基础动作"),
        s("single_under", "单摇跳绳", "gym_m02", .l1, "位移有氧", "次数",
          intro: "每次起跳绳子绕身一圈的跳绳。", steps: "前脚掌轻跳、用手腕摇绳，每跳一次绳过脚一次，保持节奏。", keyPoints: "前脚掌轻跳、手腕摇绳；适合各水平的入门有氧。",
          scaling: "原地跳+甩绳分解 / 减少次数", prereqs: [], rationale: "基础动作"),
        s("ring_row", "吊环划船", "gym_m03", .l1, "上肢拉(水平)", "次数",
          intro: "握吊环身体后倾完成的水平拉力动作。", steps: "握环身体后倾成直线，把胸尽量拉向吊环，控制放回，环越低越难。", keyPoints: "吊环训练入门动作，也是引体向上的进阶过渡；吊环越低越难。",
          scaling: "升高吊环减难 / 屈膝减难", prereqs: [], rationale: "基础动作"),
        s("air_squat", "徒手深蹲", "gym_m04", .l1, "深蹲", "次数",
          intro: "无负重的基础深蹲。", steps: "双脚与肩同宽，屈髋屈膝下蹲至髋低于膝，膝随脚尖外展，蹬地站直。", keyPoints: "学习正确深蹲的最佳方式是先无负重打好动作基础。",
          scaling: "扶撑深蹲 / 坐箱深蹲", prereqs: [], rationale: "基础动作"),
        s("shuttle_sprint", "折返跑", "gym_m02", .l1, "位移有氧", "距离/次数",
          intro: "在标志物间往返冲刺。", steps: "在标志物间全力冲刺折返，转身减速时控制身体，按要求完成距离或次数。", keyPoints: "在安全地面进行、做好热身、穿合适鞋；折返距离宜短（≤15-20 米）。",
          scaling: "缩短折返距离", prereqs: [], rationale: "基础动作"),
        s("star_jump", "星跳", "gym_m05", .l1, "跳跃", "次数",
          intro: "跳起四肢张开成星形的爆发动作。", steps: "微蹲后尽力跳高，空中伸展四肢成星形，收回四肢屈膝落地。", keyPoints: "增强式跳跃，提升爆发力与垂直弹跳。",
          scaling: "开合跳 / 减小幅度", prereqs: [], rationale: "基础动作"),
        s("bear_crawl", "熊爬", "gym_m01", .l1, "核心", "距离",
          intro: "四肢着地、膝离地的爬行动作。", steps: "手在肩下、膝离地约一拳，对侧手脚协同向前爬行，保持背平、髋不晃。", keyPoints: "常见错误：拱背、膝抬过高、膝超肘、髋部左右晃动。",
          scaling: "缩短距离 / 慢速", prereqs: [], rationale: "基础动作"),
        s("walking_lunge", "行走弓步", "gym_m06", .l1, "弓步单腿", "次数",
          intro: "向前行进的弓步。", steps: "向前迈步下蹲至后膝近地，前膝对准脚尖，蹬前脚起身收步，换腿交替前进。", keyPoints: nil,
          scaling: "原地分腿蹲 / 减小步幅", prereqs: ["air_squat"], rationale: "CF通用进阶"),
        s("box_step_up", "踏箱上步", "gym_m06", .l1, "弓步单腿", "次数",
          intro: "单脚踩上跳箱再站起的动作。", steps: "一脚踏满箱面、重心压脚跟蹬起站直，控制下落，换腿交替。", keyPoints: "重心压脚跟、勿压脚趾；膝保持在脚趾后方。",
          scaling: "降低箱高 / 扶撑", prereqs: [], rationale: "基础动作"),
        s("assault_bike", "风阻单车", "gym_m02", .l1, "位移有氧", "卡路里",
          intro: "用风阻单车完成骑行输出。", steps: "坐稳握把，腿部踩踏配合手臂推拉持续发力，按目标完成卡路里或时间。", keyPoints: nil,
          scaling: "降低卡路里或时间目标", prereqs: [], rationale: "基础动作"),
        s("lateral_burpee", "侧向波比跳", "gym_m07", .l2, "复合全身", "次数",
          intro: "波比跳后侧向跳过杠铃。", steps: "完成一次波比跳，起身侧向跳过杠铃，从另一侧进入下一次。", keyPoints: nil,
          scaling: "去侧跳 / 踏步波比", prereqs: ["burpee"], rationale: "CF通用进阶"),
        s("push_up", "俯卧撑", "gym_m08", .l2, "上肢推(水平)", "次数",
          intro: "双手撑地的上肢推力基础动作。", steps: "双手位于肩下、核心收紧，身体成直线下降至胸部接近地面，再推起至手臂伸直。", keyPoints: nil,
          scaling: "膝盖俯卧撑 / 斜面（手扶箱）俯卧撑", prereqs: [], rationale: "基础动作"),
        s("sprint", "冲刺跑", "gym_m02", .l2, "位移有氧", "距离/时间",
          intro: "短距离全力快跑。", steps: "身体前倾、前脚掌发力，加大步频与摆臂，全力冲刺至指定距离。", keyPoints: nil,
          scaling: "降低距离 / 改快走", prereqs: [], rationale: "基础动作"),
        s("forward_roll", "前滚翻", "gym_m07", .l2, "复合全身", "次数",
          intro: "收头团身向前翻滚的技巧动作。", steps: "下蹲撑手、收下巴拱背，蹬地使髋越头团身滚动，顺势收腿起身站立。", keyPoints: "收下巴、勿让头顶触地以保护头颈；高风险技巧，建议配合视频并注意安全。",
          scaling: "斜面辅助滚翻 / 团身练习", prereqs: [], rationale: "基础动作"),
        s("burpee", "波比跳", "gym_m07", .l2, "复合全身", "次数",
          intro: "由下蹲、俯卧撑与跳跃组成的全身动作。", steps: "双手撑地双脚后跳成平板，胸与髋触地；收腿起身向上跳，双臂过头。", keyPoints: "CrossFit 标准需胸与髋触地；俯卧撑后脚尖触地、双脚与髋同宽可减小幅度护膝；腰椎疾病或损伤者慎做。",
          scaling: "踏步式波比（不跳）/ 去俯卧撑或去跳跃", prereqs: [], rationale: "基础动作"),
        s("squat_jump", "深蹲跳", "gym_m05", .l2, "跳跃", "次数",
          intro: "深蹲后向上跳起的爆发动作。", steps: "下蹲至大腿平行，前脚掌蹬地尽力跳高，屈膝缓冲落地接下一次。", keyPoints: "冲击大，膝/背有伤者勿做；脚尖先着地、控制落地以防扭伤。",
          scaling: "徒手深蹲 / 减小跳高", prereqs: ["air_squat"], rationale: "CF通用进阶"),
        s("wall_climb", "爬墙倒立", "gym_m09", .l2, "上肢推(过头)", "次数",
          intro: "脚沿墙向上、身体贴近墙面的攀爬。", steps: "脚趾胸部着地，双脚沿墙向上、双手向墙靠近，直至胸贴墙，再退回。", keyPoints: nil,
          scaling: "减少向上步数 / 平板支撑", prereqs: ["push_up"], rationale: "CF通用进阶"),
        s("knees_to_elbows", "膝触肘", "gym_m01", .l2, "核心", "次数",
          intro: "悬垂将膝盖抬至肘部的核心动作。", steps: "双臂伸直悬垂于单杠，向上向后踢腿使膝触碰或接近肘部，控制下放。", keyPoints: nil,
          scaling: "悬垂屈膝抬腿 / 平板提膝", prereqs: [], rationale: "CF通用进阶"),
        s("box_jump", "跳箱", "gym_m05", .l2, "跳跃", "次数",
          intro: "向上跳上跳箱的下肢爆发动作。", steps: "站于箱前屈膝摆臂，爆发跳上箱顶屈膝缓冲，顶端髋膝伸直站直后下箱。", keyPoints: "落地屈膝缓冲以降低受伤风险；膝/脊柱疾病或损伤、高血压、植物神经紊乱者慎做。",
          scaling: "降低箱高 / 踏箱上步", prereqs: ["air_squat", "squat_jump"], rationale: "CF通用进阶"),
        s("hand_release_push_up", "释手俯卧撑", "gym_m08", .l2, "上肢推(水平)", "次数",
          intro: "每次最低点双手离地的俯卧撑。", steps: "下降至胸触地，双手短暂离地放松，再放回用力推起至手臂伸直。", keyPoints: nil,
          scaling: "膝盖释手俯卧撑 / 普通俯卧撑", prereqs: ["push_up"], rationale: "CF通用进阶"),
        s("bar_facing_burpee", "面对杠铃波比跳", "gym_m07", .l2, "复合全身", "次数",
          intro: "面向杠铃的波比跳并跳过杠铃。", steps: "完成一次波比跳，起身双脚跳过杠铃，从另一侧进入下一次。", keyPoints: "顶端无需完全伸直；腰椎疾病或损伤者慎做。",
          scaling: "去跳杠 / 踏步式波比", prereqs: ["burpee"], rationale: "CF通用进阶"),
        s("strict_pull_up", "严格引体向上", "gym_m10", .l3, "上肢拉(垂直)", "次数",
          intro: "不借摆动、纯靠力量的引体向上。", steps: "正握悬垂、身体稳定，仅靠上肢拉至下巴过杠，控制下放至完全伸直。", keyPoints: "进阶：吊环划船、离心下放、顶端与悬垂静力保持，逐步过渡到完整动作。",
          scaling: "弹力带辅助 / 离心引体 / 吊环划船", prereqs: ["ring_row"], rationale: "源数据"),
        s("handstand", "倒立", "gym_m09", .l3, "上肢推(过头)", "静力时长",
          intro: "靠墙或自由保持的倒立姿势。", steps: "双手撑地、肩部主动撑起，收紧核心保持身体竖直成一线。", keyPoints: "进阶：靠墙行走→靠墙踢起→离墙漂浮→自由倒立。",
          scaling: "爬墙倒立 / 靠墙倒立", prereqs: ["wall_climb"], rationale: "源数据"),
        s("kipping_pull_up", "借力引体向上", "gym_m10", .l3, "上肢拉(垂直)", "次数",
          intro: "借身体摆动连续完成的引体向上。", steps: "悬垂做弓形—空心摆动蓄力，借髋部发力拉至下巴过杠，控制回摆接下一次。", keyPoints: "先能连续完成 8-10 个标准引体再学摆动，否则易伤肩。",
          scaling: "严格引体向上 / 弹力带辅助", prereqs: ["strict_pull_up"], rationale: "源数据+CF"),
        s("kipping_chest_to_bar_pull_up", "借力胸触杠引体向上", "gym_m10", .l3, "上肢拉(垂直)", "次数",
          intro: "借摆动使胸触杠的引体向上。", steps: "弓形—空心摆动蓄力，爆发上拉使锁骨下方触杠，控制下放接下一次。", keyPoints: nil,
          scaling: "借力引体向上 / 拉到下巴过杠", prereqs: ["kipping_pull_up", "chest_to_bar_pull_up"], rationale: "CF通用进阶"),
        s("clapping_push_up", "击掌俯卧撑", "gym_m08", .l3, "上肢推(水平)", "次数",
          intro: "爆发推起、空中击掌的俯卧撑。", steps: "平板下降至肘约 90 度，用力推起使身体离地、空中击掌，落地接下一次。", keyPoints: nil,
          scaling: "爆发俯卧撑（推起离地）/ 俯卧撑", prereqs: ["push_up"], rationale: "CF通用进阶"),
        s("double_under", "双摇跳绳", "gym_m02", .l3, "位移有氧", "次数",
          intro: "每次起跳绳子绕身两圈的跳绳。", steps: "身体挺直、双臂收于体侧，用手腕快速摇绳，每跳一次绳过脚两次，前脚掌落地。", keyPoints: "建议先能连续完成 100 次以上单摇再学习；用轻型速度绳、选合适绳长，靠手腕控制绳子。",
          scaling: "单摇跳绳 / 单-双交替", prereqs: ["single_under"], rationale: "源数据+CF"),
        s("bar_dip", "双杠臂屈伸", "gym_m09", .l3, "上肢推(过头)", "次数",
          intro: "在双杠上完成的臂屈伸。", steps: "支撑于双杠、肘部伸直，屈肘前倾下降至肩低于肘，再伸臂推起。", keyPoints: "能做 20 次以上可加负重；力量不足可先做离心（缓慢下放）训练；肩关节损伤或慢性病者慎做。",
          scaling: "脚辅助或弹力带臂屈伸 / 离心下放", prereqs: ["push_up"], rationale: "源数据+CF"),
        s("ring_push_up", "吊环俯卧撑", "gym_m08", .l3, "上肢推(水平)", "次数",
          intro: "双手撑吊环增加不稳定性的俯卧撑。", steps: "握吊环身体成直线，屈肘下降至胸与环平齐，再推起至手臂伸直。", keyPoints: "调整吊环高度控制难度，吊环越低越难。",
          scaling: "升高吊环减难 / 俯卧撑", prereqs: ["push_up"], rationale: "源数据+CF"),
        s("ring_pull_up", "吊环引体向上", "gym_m10", .l3, "上肢拉(垂直)", "次数",
          intro: "握吊环完成的引体向上。", steps: "站于环下握环悬垂，屈臂把胸拉向吊环，控制下放，躯干稳定不晃。", keyPoints: "可练反握增强手腕，为双力臂做准备。",
          scaling: "升高减难 / 严格引体向上", prereqs: ["ring_row", "strict_pull_up"], rationale: "源数据+CF"),
        s("ring_dip", "吊环臂屈伸", "gym_m09", .l3, "上肢推(过头)", "次数",
          intro: "在吊环上完成的臂屈伸。", steps: "支撑于吊环、手臂伸直，屈肘下降至肩低于肘，再推起回到支撑位。", keyPoints: "能连续完成 20 次以上可加负重提升难度。",
          scaling: "脚辅助吊环臂屈伸 / 双杠臂屈伸", prereqs: ["bar_dip"], rationale: "源数据+CF"),
        s("turkish_get_up", "土耳其起立", "gym_m07", .l3, "复合全身", "次数",
          intro: "从仰卧到站立全程把壶铃举过头的复合动作。", steps: "仰卧单臂举铃过头，依次起身经肘撑、手撑、抬髋、扫腿到弓步起立，再原路返回。", keyPoints: "几乎调动全身肌肉；可用壶铃、哑铃或小杠铃。",
          scaling: "徒手分解练习 / 减轻负重", prereqs: [], rationale: "CF通用进阶"),
        s("pull_up", "引体向上", "gym_m10", .l3, "上肢拉(垂直)", "次数",
          intro: "悬垂于单杠将身体拉起的上肢拉力动作。", steps: "正握悬垂、手臂伸直；发力拉至下巴过杠，控制下放至完全悬垂。", keyPoints: "进阶顺序：跳跃引体向上→等长悬停→标准引体；可用辅助器械或递减组增强力量。",
          scaling: "弹力带辅助引体 / 跳跃引体 / 吊环划船", prereqs: ["ring_row"], rationale: "源数据"),
        s("burpee_pull_up", "波比引体向上", "gym_m07", .l3, "复合全身", "次数",
          intro: "波比跳衔接引体向上的复合动作。", steps: "完成一次波比跳，跳起握杠借力拉至下巴过杠，落地进入下一次。", keyPoints: "需分别掌握波比跳与引体两个动作。",
          scaling: "弹力带辅助引体 / 拆成波比+引体", prereqs: ["burpee", "pull_up"], rationale: "CF通用进阶"),
        s("burpee_box_jump_over", "波比跳箱越过", "gym_m07", .l3, "复合全身", "次数",
          intro: "波比跳衔接越过跳箱。", steps: "完成一次波比跳，起身跳上或越过跳箱并从另一侧落地。", keyPoints: "顶端无需完全伸直身体；可调整次数与箱高适合各水平。",
          scaling: "降低箱高 / 波比+踏箱上步", prereqs: ["burpee", "box_jump"], rationale: "CF通用进阶"),
        s("rope_climb", "爬绳", "gym_m10", .l3, "上肢拉(垂直)", "次数",
          intro: "利用腿夹绳与上肢拉力向上攀爬。", steps: "双手握绳、用脚夹绳支撑，伸腿—屈臂换手向上攀爬至指定高度，控制下降。", keyPoints: "标准绳长约 4.5 米（15 英尺）；动作正确时腿部承力，握力常最先受挑战。",
          scaling: "坐姿拉绳起立 / 降低攀爬高度", prereqs: ["pull_up"], rationale: "源数据+CF"),
        s("chest_to_bar_pull_up", "胸触杠引体向上", "gym_m10", .l3, "上肢拉(垂直)", "次数",
          intro: "借摆动将胸部触碰单杠的引体。", steps: "弓形—空心摆动蓄力，爆发上拉使锁骨下方胸部触杠，控制下放保持节奏。", keyPoints: "需借摆动（kipping）把胸拉到杠；先掌握标准引体再练。",
          scaling: "借力引体向上 / 拉到下巴过杠", prereqs: ["kipping_pull_up"], rationale: "源数据"),
        s("toes_to_bar", "脚触杠", "gym_m01", .l3, "核心", "次数",
          intro: "悬垂将双脚抬起触碰单杠的核心动作。", steps: "悬垂于单杠，肩部主动、核心收紧；摆动把双脚同时上抬触杠，控制下放回弧形位。", keyPoints: nil,
          scaling: "膝触肘 / 悬垂屈膝抬腿", prereqs: ["knees_to_elbows"], rationale: "源数据+CF"),
        s("box_jump_over", "跳箱越过", "gym_m05", .l3, "跳跃", "次数",
          intro: "跳上并越过跳箱落到另一侧。", steps: "屈膝摆臂跳上或直接越过跳箱，从另一侧落地，转身重复。", keyPoints: "顶端无需完全锁定膝髋。",
          scaling: "降低箱高 / 跳上再下", prereqs: ["box_jump"], rationale: "CF通用进阶"),
        s("l_sit_pull_up", "L坐引体向上", "gym_m11", .l4, "上肢拉(垂直)/核心", "静力时长",
          intro: "保持 L 坐姿同时完成引体向上。", steps: "悬垂抬腿成 L 形，保持双腿水平拉至下巴过杠，控制下放，全程缓慢可控。", keyPoints: "先掌握标准引体与各位置 L 坐；节奏慢、全程可控，勿借惯性。",
          scaling: "屈腿引体保持 / 严格引体向上", prereqs: ["strict_pull_up"], rationale: "源数据"),
        s("strict_handstand_push_up", "严格倒立俯卧撑", "gym_m09", .l4, "上肢推(过头)", "次数",
          intro: "不借摆动的靠墙倒立俯卧撑。", steps: "靠墙倒立、身体收紧，控制屈肘下降至头顶触地，再纯靠上肢推起伸直。", keyPoints: "纯靠力量、不借摆动，难度高于借力版本。",
          scaling: "倒立俯卧撑 / 垫高减幅", prereqs: ["handstand_push_up"], rationale: "源数据"),
        s("strict_ring_dip", "严格吊环臂屈伸", "gym_m09", .l4, "上肢推(过头)", "次数",
          intro: "不借摆动的吊环臂屈伸。", steps: "支撑于环、颈长身空，肩前倾下降至肩低于肘，再撑回稳定支撑位。", keyPoints: nil,
          scaling: "吊环臂屈伸 / 脚辅助", prereqs: ["ring_dip"], rationale: "源数据+CF"),
        s("handstand_push_up", "倒立俯卧撑", "gym_m09", .l4, "上肢推(过头)", "次数",
          intro: "倒立姿势下完成的过头推力动作。", steps: "靠墙倒立、身体收紧；屈肘下降至头顶触地，再推起至手臂完全伸直。", keyPoints: "进阶：先掌握标准俯卧撑、靠墙倒立保持 60 秒、屈体俯卧撑、半程与控制下落，再做完整动作。",
          scaling: "垫高减幅 / 屈体俯卧撑 / 箱上HSPU", prereqs: ["push_up", "shoulder_press"], rationale: "源数据+CF"),
        s("pistol_squat", "手枪深蹲", "gym_m06", .l4, "弓步单腿", "次数",
          intro: "单腿完成的全幅深蹲。", steps: "单腿支撑、另一腿前伸离地，控制膝盖方向下蹲至最低点，再蹬地站起。", keyPoints: "高难动作，可借单杠辅助、抬高后腿或部分幅度等方式简化。",
          scaling: "箱上单腿蹲 / 辅助单腿蹲", prereqs: ["air_squat"], rationale: "源数据+CF"),
        s("strict_muscle_up", "严格双力臂", "gym_m10", .l5, "上肢拉(垂直)", "次数",
          intro: "不借摆动的吊环双力臂。", steps: "假握悬垂，纯靠上拉使肩过环，前倾过渡后撑起至手臂锁定。", keyPoints: "纯靠力量、不借摆动，难度高。",
          scaling: "吊环双力臂 / 弹力带辅助", prereqs: ["ring_muscle_up", "strict_ring_dip"], rationale: "源数据+CF"),
        s("handstand_walk", "倒立行走", "gym_m09", .l5, "上肢推(过头)", "距离",
          intro: "倒立姿势下用手向前行走。", steps: "稳定倒立、重心在手指，肩部主动撑起，交替移动双手向前行走。", keyPoints: nil,
          scaling: "靠墙倒立漂浮 / 熊爬", prereqs: ["handstand"], rationale: "源数据+CF"),
        s("kipping_bar_muscle_up", "借力单杠双力臂", "gym_m10", .l5, "上肢拉(垂直)", "次数",
          intro: "借摆动连续完成的单杠双力臂。", steps: "弓形摆动蓄力上拉使胸过杠，双肩同步过渡撑起至手臂伸直。", keyPoints: "先掌握标准引体、摆动引体、胸触杠与双杠臂屈伸；双肩双肘须同步，勿单侧过杠以免受伤。",
          scaling: "弹力带辅助 / 高位胸触杠+翻杠", prereqs: ["chest_to_bar_pull_up", "bar_dip", "toes_to_bar"], rationale: "源数据"),
        s("bar_muscle_up", "单杠双力臂", "gym_m10", .l5, "上肢拉(垂直)", "次数",
          intro: "在单杠上由引体过渡到撑起的高难动作。", steps: "弓形摆动蓄力，爆发上拉使胸过杠并翻转过渡，撑起至手臂伸直。", keyPoints: "高难动作，建议先掌握准备动作；肩关节损伤或慢性病者慎做。",
          scaling: "弹力带辅助双力臂 / 高位胸触杠+翻杠过渡", prereqs: ["strict_pull_up", "chest_to_bar_pull_up", "bar_dip", "toes_to_bar"], rationale: "源数据+CF"),
        s("ring_handstand_push_up", "吊环倒立俯卧撑", "gym_m09", .l5, "上肢推(过头)", "次数",
          intro: "在吊环上完成的倒立俯卧撑，高难度。", steps: "吊环倒立、身体核心收紧，控制屈肘下降头近地，再推起伸直，尽量保持环稳定。", keyPoints: "高难，需强肩部稳定与核心控制，建议在教练指导下训练。",
          scaling: "严格倒立俯卧撑 / 垫高减幅", prereqs: ["strict_handstand_push_up"], rationale: "CF通用进阶"),
        s("ring_muscle_up", "吊环双力臂", "gym_m10", .l5, "上肢拉(垂直)", "次数",
          intro: "在吊环上由引体过渡到臂屈伸的高难动作。", steps: "假握悬垂摆动，爆发上拉、快速过渡使肩过环，撑起至手臂锁定。", keyPoints: "高难动作，需良好力量、速度与协调，不适合初学者。",
          scaling: "弹力带辅助双力臂 / 拆成引体+吊环臂屈伸+过渡", prereqs: ["strict_pull_up", "ring_dip"], rationale: "源数据+CF"),
        s("back_flip", "后空翻", "gym_m05", .l5, "跳跃", "次数",
          intro: "原地向后翻转的高风险技巧动作。", steps: "屈膝摆臂蹬地起跳并向后甩头团身翻转，看到地面后展体、屈膝脚尖落地。建议在保护下练习。", keyPoints: "高风险技巧动作，建议在保护下练习。",
          scaling: "保护下练习 / 后滚翻过渡", prereqs: ["forward_roll"], rationale: "源数据+CF"),
        s("legless_rope_climb", "无腿爬绳", "gym_m10", .l5, "上肢拉(垂直)", "次数",
          intro: "不借腿、仅用手臂攀爬绳索。", steps: "双臂完全悬垂，用手拉手或摆动方式仅靠上肢交替向上攀爬，握力要强。", keyPoints: "强握力是关键；手拉手最快但易疲劳，疲劳后改摆动式。",
          scaling: "爬绳 / 降低攀爬高度", prereqs: ["rope_climb", "strict_pull_up"], rationale: "源数据+CF"),
        s("burpee_bar_muscle_up", "波比单杠双力臂", "gym_m07", .l5, "复合全身", "次数",
          intro: "波比跳衔接单杠双力臂。", steps: "完成一次波比跳，跳起握杠爆发上拉过杠，撑起至手臂伸直。", keyPoints: nil,
          scaling: "弹力带辅助双力臂 / 拆成波比+双力臂", prereqs: ["bar_muscle_up", "burpee"], rationale: "CF通用进阶"),
        s("burpee_muscle_up", "波比双力臂", "gym_m07", .l5, "复合全身", "次数",
          intro: "波比跳衔接吊环双力臂。", steps: "完成一次波比跳，跳上吊环借摆动过渡撑起至手臂锁定。", keyPoints: "需分别掌握波比跳与吊环双力臂。",
          scaling: "弹力带辅助双力臂 / 拆成波比+吊环双力臂", prereqs: ["ring_muscle_up", "burpee"], rationale: "CF通用进阶")
    ]

    // MARK: 举重 Weightlifting (67)

    static let weightlifting = SkillCategoryDefinition(
        id: "weightlifting",
        name: "举重",
        englishName: "Weightlifting",
        icon: "figure.strengthtraining.traditional",
        color: Color(hex: "#5BE88F"),
        subcategories: [
            SkillSubcategoryDefinition(id: "wl_m01", name: "搬运行走", categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_m02", name: "髋铰链", categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_m03", name: "上肢拉(水平)", categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_m04", name: "深蹲", categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_m05", name: "上肢推(过头)", categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_m06", name: "上肢拉(水平)/核心", categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_m07", name: "上肢推(水平)", categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_m08", name: "奥举", categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_m09", name: "复合全身", categoryId: "weightlifting"),
            SkillSubcategoryDefinition(id: "wl_m10", name: "弓步单腿", categoryId: "weightlifting"),
        ],
        skills: weightliftingSkills
    )

    private static let weightliftingSkills: [SkillDefinition] = [
        s("farmers_walk", "农夫行走", "wl_m01", .l1, "搬运行走", "距离",
          intro: "双手负重行走的搬运动作。", steps: "双手各持重物，收紧核心挺直身体，迈小而快的步伐走完指定距离。", keyPoints: "勿直接把重物摔在地上，控制放下。",
          scaling: "减重 / 缩短距离", prereqs: [], rationale: "基础动作"),
        s("double_kettlebell_deadlift", "双壶铃硬拉", "wl_m02", .l1, "髋铰链", "次数",
          intro: "双手各持壶铃从地面拉起。", steps: "双壶铃置脚两侧、背部中立，伸髋伸膝拉起站直，再控制放回。", keyPoints: nil,
          scaling: "减重 / 单壶铃硬拉", prereqs: ["deadlift"], rationale: "CF通用进阶"),
        s("two_arm_kettlebell_row", "双臂壶铃划船", "wl_m03", .l1, "上肢拉(水平)", "次数",
          intro: "双手持壶铃俯身划船。", steps: "双手持壶铃屈髋、背中立，把壶铃拉向躯干收肩胛，控制放回。", keyPoints: nil,
          scaling: "减重 / 减小幅度", prereqs: [], rationale: "基础动作"),
        s("dumbbell_squat", "哑铃深蹲", "wl_m04", .l1, "深蹲", "次数",
          intro: "手持哑铃完成的深蹲。", steps: "哑铃置肩、体侧或前架位，核心收紧下蹲后站起。", keyPoints: nil,
          scaling: "减重 / 徒手深蹲", prereqs: ["air_squat", "goblet_squat"], rationale: "CF通用进阶"),
        s("dumbbell_deadlift", "哑铃硬拉", "wl_m02", .l1, "髋铰链", "次数",
          intro: "用哑铃完成的硬拉。", steps: "双哑铃置身侧、屈膝不屈背，下放至哑铃近地，再伸髋伸膝站直。", keyPoints: "屈膝不屈背、手臂全程伸直；无杠铃时的理想替代。",
          scaling: "减重 / 减小幅度", prereqs: ["deadlift"], rationale: "CF通用进阶"),
        s("kettlebell_sumo_deadlift", "壶铃相扑硬拉", "wl_m02", .l1, "髋铰链", "次数",
          intro: "宽站距用壶铃完成的硬拉。", steps: "宽站距窄握壶铃、臀低胸挺，伸髋伸膝拉起站直，再控制放回。", keyPoints: nil,
          scaling: "减重 / 减小幅度", prereqs: ["deadlift", "sumo_deadlift"], rationale: "CF通用进阶"),
        s("sumo_deadlift", "相扑硬拉", "wl_m02", .l1, "髋铰链", "次数",
          intro: "宽站距完成的硬拉。", steps: "宽站距窄握、臀低胸挺，伸髋伸膝拉起至站直，再控制放回。", keyPoints: "对许多人比常规硬拉更友好的变式。",
          scaling: "减重 / 常规硬拉", prereqs: ["deadlift"], rationale: "CF通用进阶"),
        s("goblet_squat", "高脚杯深蹲", "wl_m04", .l1, "深蹲", "次数",
          intro: "胸前抱单只哑铃或壶铃的深蹲。", steps: "双手抱铃于胸前，屈髋屈膝下蹲至最低点，膝随脚尖外展，蹬地站直。", keyPoints: "胸前抱铃可减轻下背压力，适合肩部活动受限者。",
          scaling: "减重 / 徒手深蹲", prereqs: ["air_squat"], rationale: "CF通用进阶"),
        s("alternating_kettlebell_shoulder_press", "交替壶铃肩推", "wl_m05", .l2, "上肢推(过头)", "次数",
          intro: "左右交替的单臂壶铃肩上推举。", steps: "双壶铃举至肩侧，一侧推过头另一侧不动，挺胸收腹不晃身，换侧交替。", keyPoints: "推举时勿左右晃身、收紧腹部稳定。",
          scaling: "减重 / 双手壶铃推举", prereqs: ["shoulder_press"], rationale: "CF通用进阶"),
        s("renegade_row", "俯撑哑铃划船", "wl_m06", .l2, "上肢拉(水平)/核心", "次数",
          intro: "俯撑姿势下单臂交替划船。", steps: "双手撑哑铃成俯撑，一手撑地另一手把哑铃拉至腰侧，核心稳定交替进行。", keyPoints: "需大量稳定力量，能强化腹部与核心；在平稳表面进行。",
          scaling: "膝盖俯撑 / 减重", prereqs: [], rationale: "CF通用进阶"),
        s("push_press", "借力推举", "wl_m05", .l2, "上肢推(过头)", "次数",
          intro: "借腿部下蹲发力把杠铃推举过头。", steps: "前架持杠微屈膝下蹲，爆发蹬地借力把杠铃推举过头锁定，落回肩部。", keyPoints: nil,
          scaling: "减重 / 肩上推举", prereqs: ["shoulder_press"], rationale: "CF通用进阶"),
        s("front_squat", "前蹲", "wl_m04", .l2, "深蹲", "次数",
          intro: "杠铃置于前架位的深蹲。", steps: "前架持杠、肘部抬高，屈髋屈膝下蹲至大腿过平行，蹬地站直。", keyPoints: "前架位能用更小重量激活更多股四头肌，适合肩部活动受限者。",
          scaling: "减重 / 高脚杯深蹲", prereqs: ["air_squat", "back_squat"], rationale: "CF通用进阶"),
        s("one_arm_kettlebell_press", "单臂壶铃推举", "wl_m05", .l2, "上肢推(过头)", "次数",
          intro: "单臂把壶铃从肩推举至过头。", steps: "单臂壶铃置肩，肋骨下沉核心收紧，推举过头锁定，避免侧倾后仰。", keyPoints: nil,
          scaling: "减重 / 双手推举", prereqs: ["shoulder_press"], rationale: "CF通用进阶"),
        s("bench_press", "卧推", "wl_m07", .l2, "上肢推(水平)", "次数",
          intro: "仰卧将杠铃推离胸部的上肢推力动作。", steps: "仰卧收紧肩胛、双脚踩实，握距略宽于肩；吸气下放杠铃至胸，再推起至手臂伸直。", keyPoints: "建议有同伴保护；下背自然拱不过度、勿让杠铃弹胸；腰/颈椎创伤或慢性病者慎做。",
          scaling: "减重 / 俯卧撑", prereqs: ["push_up"], rationale: "CF通用进阶"),
        s("back_squat", "后蹲", "wl_m04", .l2, "深蹲", "次数",
          intro: "杠铃置于后背的深蹲。", steps: "杠铃置斜方肌、双脚与肩同宽，屈髋屈膝下蹲至大腿过平行，背部挺直蹬地站直。", keyPoints: "不建议初学者无教练指导进行；膝外展、下背中立、勿让脚尖超过膝、勿抬头；腰椎间盘突出或膝关节疾病复杂者慎做。",
          scaling: "减重 / 徒手深蹲", prereqs: ["air_squat"], rationale: "CF通用进阶"),
        s("dumbbell_push_press", "哑铃借力推举", "wl_m05", .l2, "上肢推(过头)", "次数",
          intro: "借腿部发力把哑铃推举过头。", steps: "双哑铃置肩、微屈膝下蹲，蹬地借力将哑铃推举过头锁定，落回肩部。", keyPoints: nil,
          scaling: "减重 / 哑铃推举", prereqs: ["dumbbell_press"], rationale: "CF通用进阶"),
        s("dumbbell_power_clean", "哑铃力量翻站", "wl_m08", .l2, "奥举", "次数",
          intro: "双哑铃翻至肩、不进入深蹲。", steps: "哑铃从地面或低位爆发上拉，在高位屈臂接至肩，背部中立。", keyPoints: nil,
          scaling: "减重 / 哑铃翻站", prereqs: ["dumbbell_clean"], rationale: "CF通用进阶"),
        s("dumbbell_press", "哑铃推举", "wl_m05", .l2, "上肢推(过头)", "次数",
          intro: "站姿将哑铃严格推举过头。", steps: "双哑铃举至头侧、肘约 90 度，不借腿力伸肘把哑铃推过头，控制回落。", keyPoints: nil,
          scaling: "减重 / 肩上推举", prereqs: ["shoulder_press"], rationale: "CF通用进阶"),
        s("dumbbell_burpee_deadlift", "哑铃波比硬拉", "wl_m09", .l2, "复合全身", "次数",
          intro: "手持哑铃完成的波比硬拉。", steps: "持哑铃俯身下蹲、双腿后撑成俯撑做俯卧撑，跳回起身把哑铃拉至肩高站直。", keyPoints: "勿用过重哑铃，否则动作易变形受伤。",
          scaling: "减重 / 拆成波比+哑铃硬拉", prereqs: ["burpee", "dumbbell_deadlift"], rationale: "CF通用进阶"),
        s("dumbbell_clean", "哑铃翻站", "wl_m08", .l2, "奥举", "次数",
          intro: "双哑铃从地面翻至肩的动作。", steps: "哑铃落地屈髋,爆发伸髋伸膝上拉，屈臂在肩前接住，站直。", keyPoints: nil,
          scaling: "减重 / 哑铃高拉至肩", prereqs: ["deadlift", "kettlebell_swing"], rationale: "CF通用进阶"),
        s("wall_ball", "墙球", "wl_m09", .l2, "复合全身", "次数",
          intro: "深蹲后将药球抛向墙面目标的动作。", steps: "高脚杯抱球下蹲至髋低于膝，蹬地起身借力将球抛向墙面目标，接住落球顺势下蹲。", keyPoints: "选择适合自己的球重，下蹲深度可比杠铃深蹲更低。",
          scaling: "减轻球重 / 降低目标高度 / 拆成深蹲+推举", prereqs: ["goblet_squat", "push_press"], rationale: "CF通用进阶"),
        s("kettlebell_swing", "壶铃摆动", "wl_m02", .l2, "髋铰链", "次数",
          intro: "靠髋部发力将壶铃摆至胸高的全身动作。", steps: "屈髋后坐握壶铃，爆发伸髋把壶铃摆到胸高，手臂放松；顺势回摆至两腿间连续进行。", keyPoints: "初学先用较轻壶铃掌握动作再加重。",
          scaling: "减轻壶铃 / 俄式摆动（摆至胸高）", prereqs: ["deadlift"], rationale: "CF通用进阶"),
        s("kettlebell_high_pull", "壶铃高拉", "wl_m02", .l2, "髋铰链", "次数",
          intro: "壶铃高拉至肩部的爆发动作。", steps: "壶铃置两脚间屈髋握住，伸髋伸膝同时把壶铃上拉至肩、肘抬高，控制回位。", keyPoints: nil,
          scaling: "减重 / 壶铃摆动", prereqs: ["kettlebell_swing"], rationale: "CF通用进阶"),
        s("kettlebell_goblet_thruster", "壶铃高脚杯深蹲推举", "wl_m09", .l2, "复合全身", "次数",
          intro: "壶铃高脚杯深蹲接推举过头。", steps: "胸前抱壶铃下蹲至大腿过平行，蹬地起身借力把壶铃推举过头锁定。", keyPoints: nil,
          scaling: "减重 / 拆成高脚杯深蹲+推举", prereqs: ["goblet_squat", "push_press"], rationale: "CF通用进阶"),
        s("stiff_legged_deadlift", "直腿硬拉", "wl_m02", .l2, "髋铰链", "次数",
          intro: "保持腿近伸直、屈髋的硬拉。", steps: "双手正握杠铃，腿近伸直屈髋下放至腘绳肌拉伸极限，收紧后链拉起站直。", keyPoints: "保持腿近伸直、感受腘绳肌拉伸，看向上方、肩后收以防弓背。",
          scaling: "减重 / 减小幅度", prereqs: ["deadlift"], rationale: "CF通用进阶"),
        s("sumo_deadlift_high_pull", "相扑硬拉高拉", "wl_m02", .l2, "髋铰链", "次数",
          intro: "宽站距硬拉接高拉至下巴的复合动作。", steps: "宽站距窄握，伸髋伸膝拉起，过膝后抬肘把杠铃上拉至下巴，控制回放。", keyPoints: nil,
          scaling: "减重 / 相扑硬拉", prereqs: ["sumo_deadlift"], rationale: "CF通用进阶"),
        s("deadlift", "硬拉", "wl_m02", .l2, "髋铰链", "次数",
          intro: "将杠铃从地面拉起至站直的基础力量动作。", steps: "杠铃贴小腿、背部挺直，蹬地伸髋伸膝拉起至站直，再屈髋屈膝控制放回。", keyPoints: "源自力量举，训练初期数月不建议进行；下背保持中立、勿弓背，重量勿压在手臂和肩上。",
          scaling: "减重 / 架上硬拉（垫高起拉）", prereqs: [], rationale: "基础动作"),
        s("shoulder_press", "肩上推举", "wl_m05", .l2, "上肢推(过头)", "次数",
          intro: "靠上肢力量将杠铃严格推举过头。", steps: "前架持杠、核心收紧，不借腿力把杠铃沿垂直路线推举过头锁定，再落回肩。", keyPoints: nil,
          scaling: "减重 / 哑铃推举", prereqs: [], rationale: "基础动作"),
        s("weighted_lunge", "负重弓步", "wl_m10", .l2, "弓步单腿", "次数",
          intro: "手持或负重完成的弓步。", steps: "持重物保持躯干直立，向前或原地下蹲至后膝近地，蹬前脚起身换腿。", keyPoints: "可用哑铃、壶铃、杠铃、沙袋等负重。",
          scaling: "减重 / 徒手行走弓步", prereqs: ["walking_lunge"], rationale: "CF通用进阶"),
        s("alternating_dumbbell_snatch", "交替哑铃抓举", "wl_m08", .l3, "奥举", "次数",
          intro: "左右交替的单臂哑铃抓举。", steps: "哑铃落地，伸髋伸膝爆发上拉贴身，翻肘举过头锁定，换手交替进行。", keyPoints: nil,
          scaling: "减重 / 哑铃力量抓举", prereqs: ["dumbbell_power_snatch"], rationale: "CF通用进阶"),
        s("alternating_kettlebell_snatch", "交替壶铃抓举", "wl_m08", .l3, "奥举", "次数",
          intro: "左右交替的单臂壶铃抓举。", steps: "壶铃于两腿间摆起，伸髋发力过头翻腕锁定，下放回摆换手交替。", keyPoints: nil,
          scaling: "减重 / 壶铃抓举", prereqs: ["kettlebell_snatch"], rationale: "CF通用进阶"),
        s("push_jerk", "借力挺举", "wl_m05", .l3, "上肢推(过头)", "次数",
          intro: "借下蹲发力把杠铃送过头并下蹲接杠。", steps: "前架微屈膝爆发蹬地推杠，快速下蹲至杠铃下方手臂锁定接住，站直。", keyPoints: nil,
          scaling: "减重 / 借力推举", prereqs: ["shoulder_press", "push_press"], rationale: "CF通用进阶"),
        s("power_clean", "力量翻站", "wl_m08", .l3, "奥举", "次数",
          intro: "杠铃翻至前架位但不进入深蹲。", steps: "蹬地拉起、伸髋耸肩快速翻肘，于高于平行的位置接杠至前架位，站直。", keyPoints: "与翻站区别：在高于平行处接杠、不进入全深蹲；脊柱膝关节有伤者慎做。",
          scaling: "减重 / 悬垂力量翻站", prereqs: ["deadlift", "hang_power_clean"], rationale: "CF通用进阶"),
        s("single_arm_db_overhead_lunge", "单臂哑铃过头弓步", "wl_m10", .l3, "弓步单腿", "次数",
          intro: "单臂哑铃锁定过头完成的弓步。", steps: "单臂哑铃稳定锁定过头，向前或退步下蹲至后膝近地，蹬前脚起身。", keyPoints: nil,
          scaling: "减重 / 前架弓步", prereqs: ["walking_lunge"], rationale: "CF通用进阶"),
        s("double_kettlebell_clean", "双壶铃翻站", "wl_m08", .l3, "奥举", "次数",
          intro: "双手各持壶铃翻至肩架位。", steps: "双壶铃于两腿间后摆，伸髋发力翻至肩前架位，全程背部挺直。", keyPoints: "高难，建议在教练指导下纳入计划；腰椎受伤者慎做。",
          scaling: "减重 / 单壶铃翻站", prereqs: ["kettlebell_high_pull", "front_squat"], rationale: "CF通用进阶"),
        s("dumbbell_squat_clean", "哑铃下蹲翻站", "wl_m08", .l3, "奥举", "次数",
          intro: "双哑铃翻至肩并全深蹲接住。", steps: "哑铃落地爆发上拉，下蹲在肩前接住，再伸髋伸膝站直。", keyPoints: nil,
          scaling: "减重 / 哑铃翻站", prereqs: ["dumbbell_clean", "front_squat"], rationale: "CF通用进阶"),
        s("dumbbell_push_jerk", "哑铃借力挺举", "wl_m05", .l3, "上肢推(过头)", "次数",
          intro: "借腿部发力把双哑铃挺举过头。", steps: "双哑铃置肩微屈膝下蹲，蹬地借力推过头锁定，再缓慢回到肩。", keyPoints: nil,
          scaling: "减重 / 哑铃借力推举", prereqs: ["dumbbell_press", "dumbbell_push_press"], rationale: "CF通用进阶"),
        s("dumbbell_power_snatch", "哑铃力量抓举", "wl_m08", .l3, "奥举", "次数",
          intro: "单臂哑铃一次性举过头、不深蹲。", steps: "哑铃置两腿间下蹲，伸髋伸膝爆发上拉贴身，翻肘在高位将哑铃举过头锁定。", keyPoints: "全程哑铃贴身、靠髋臀发力，避免把哑铃甩离身体。",
          scaling: "减重 / 哑铃高拉至肩", prereqs: ["kettlebell_swing"], rationale: "CF通用进阶"),
        s("dumbbell_hang_clean_and_jerk", "哑铃悬垂翻站挺举", "wl_m08", .l3, "奥举", "次数",
          intro: "哑铃从悬垂位翻至肩再挺举过头。", steps: "哑铃悬于大腿，伸髋翻至肩，微屈膝借力挺举过头锁定后站直。", keyPoints: nil,
          scaling: "减重 / 拆成哑铃翻站+借力挺举", prereqs: ["dumbbell_clean", "dumbbell_push_jerk"], rationale: "CF通用进阶"),
        s("dumbbell_thruster", "哑铃深蹲推举", "wl_m09", .l3, "复合全身", "次数",
          intro: "哑铃前蹲接借力推举的复合动作。", steps: "双哑铃置肩下蹲至大腿过平行，蹬地起身借力把哑铃推举过头锁定，落回肩。", keyPoints: nil,
          scaling: "减重 / 拆成哑铃深蹲+推举", prereqs: ["dumbbell_squat", "dumbbell_press"], rationale: "CF通用进阶"),
        s("kettlebell_snatch", "壶铃抓举", "wl_m08", .l3, "奥举", "次数",
          intro: "将壶铃一次性摆举至头顶锁定。", steps: "壶铃置两脚间屈髋握住，伸髋伸膝摆起，过肩时翻腕送至头顶手臂锁定。", keyPoints: nil,
          scaling: "减重 / 壶铃高拉", prereqs: ["kettlebell_swing", "kettlebell_high_pull"], rationale: "CF通用进阶"),
        s("kettlebell_thruster", "壶铃深蹲推举", "wl_m09", .l3, "复合全身", "次数",
          intro: "双壶铃深蹲接推举过头的复合动作。", steps: "双壶铃置肩架位下蹲至大腿过平行，蹬地起身借力把壶铃推举过头锁定，落回肩。", keyPoints: "调动大量大小肌群、能耗高，并能强化稳定肌群。",
          scaling: "减重 / 单壶铃高脚杯深蹲推举", prereqs: ["kettlebell_goblet_thruster"], rationale: "CF通用进阶"),
        s("kettlebell_clean_and_jerk", "壶铃翻站挺举", "wl_m08", .l3, "奥举", "次数",
          intro: "壶铃翻至肩后再挺举过头。", steps: "伸髋翻壶铃至肩架位，微屈膝爆发挺举过头手臂锁定，下蹲接住后站直。", keyPoints: nil,
          scaling: "减重 / 拆成壶铃高拉+借力推举", prereqs: ["kettlebell_high_pull", "push_press"], rationale: "CF通用进阶"),
        s("hang_power_clean", "悬垂力量翻站", "wl_m08", .l3, "奥举", "次数",
          intro: "从悬垂位翻站至前架位、不进入深蹲。", steps: "杠铃悬于大腿，伸髋伸膝耸肩拉起，快速翻肘在高位接杠至前架位站直。", keyPoints: "从悬垂位接杠、不进入全深蹲；脊柱膝关节有伤者慎做。",
          scaling: "减重 / 高悬垂位翻站", prereqs: ["deadlift", "kettlebell_swing"], rationale: "CF通用进阶"),
        s("hang_clean", "悬垂翻站", "wl_m08", .l3, "奥举", "次数",
          intro: "从悬垂位翻站至前架位。", steps: "杠铃悬于大腿，伸髋伸膝耸肩拉起，快速翻肘接杠至前架位站直。", keyPoints: "脊柱、膝关节有创伤或破坏性改变者慎做。",
          scaling: "减重 / 悬垂力量翻站", prereqs: ["hang_power_clean", "front_squat"], rationale: "CF通用进阶"),
        s("thruster", "深蹲推举", "wl_m09", .l3, "复合全身", "次数",
          intro: "前蹲接借力推举的复合动作。", steps: "前架持杠下蹲至髋低于膝，蹬地起身借惯性将杠铃推举过头锁定，落回肩部接下一次。", keyPoints: "结合了翻站、前蹲与借力推，对心肺要求高；加重练力量、减重练耐力。",
          scaling: "减重 / 哑铃深蹲推举 / 拆成前蹲+借力推举", prereqs: ["front_squat", "push_press"], rationale: "CF通用进阶"),
        s("clean", "翻站", "wl_m08", .l3, "奥举", "次数",
          intro: "将杠铃从地面翻至前架位的奥举基础动作。", steps: "蹬地拉起贴身、伸髋耸肩，快速翻肘下蹲在前架位接杠，蹬地站直。", keyPoints: "翻站是奥举基础动作；脊柱、膝关节有创伤或破坏性改变者慎做。",
          scaling: "减重 / 力量翻站", prereqs: ["power_clean", "front_squat"], rationale: "CF通用进阶"),
        s("muscle_snatch", "肌肉抓举", "wl_m08", .l3, "奥举", "次数",
          intro: "不下蹲、靠手臂将杠铃翻过头的抓举。", steps: "抓举握距拉起，身体伸展后尽量高抬肘，翻腕把杠铃送至过头锁定，腿全程伸直。", keyPoints: "全程腿伸直、保持对杠铃持续张力、动作连续无停顿。",
          scaling: "减重 / 抓举高拉", prereqs: [], rationale: "CF通用进阶"),
        s("muscle_clean", "肌肉翻站", "wl_m08", .l3, "奥举", "次数",
          intro: "不下蹲、靠手臂把杠铃翻至肩。", steps: "蹬地耸肩高抬肘把杠铃拉至上胸，快速翻肘在前架位接住，腿不下蹲。", keyPoints: "全程腿伸直、动作连续，肘尽量高抬。",
          scaling: "减重 / 翻站高拉", prereqs: ["deadlift", "kettlebell_swing"], rationale: "CF通用进阶"),
        s("push_jerk_behind_head", "颈后借力挺举", "wl_m05", .l3, "上肢推(过头)", "次数",
          intro: "杠铃置颈后的借力挺举。", steps: "杠铃置斜方肌微屈膝下蹲，蹬地推过头、分腿接杠锁定后收脚站直。", keyPoints: nil,
          scaling: "减重 / 借力挺举", prereqs: ["push_jerk"], rationale: "CF通用进阶"),
        s("squat_clean", "下蹲翻站", "wl_m08", .l4, "奥举", "次数",
          intro: "翻站接杠后落入全深蹲再起立。", steps: "蹬地拉起、伸髋耸肩，快速下蹲在前架位接住杠铃，蹬地站直。", keyPoints: "翻站后落入全深蹲再起立；脊柱膝关节有伤者慎做。",
          scaling: "减重 / 力量翻站", prereqs: ["power_clean", "front_squat"], rationale: "CF通用进阶"),
        s("split_jerk", "分腿挺举", "wl_m05", .l4, "上肢推(过头)", "次数",
          intro: "下蹲发力、前后分腿接杠的挺举。", steps: "前架微屈膝下蹲爆发推杠，快速前后分腿在过头锁定位接住，再收脚站直。", keyPoints: "目前最主流的竞技挺举方式。",
          scaling: "减重 / 借力挺举", prereqs: ["push_press", "push_jerk"], rationale: "CF通用进阶"),
        s("power_snatch", "力量抓举", "wl_m08", .l4, "奥举", "次数",
          intro: "杠铃一次性举过头、不进入深蹲。", steps: "宽握拉起、伸髋耸肩，过头时翻腕在高于平行处接杠锁定，站直。", keyPoints: nil,
          scaling: "减重 / 悬垂力量抓举", prereqs: ["overhead_squat", "hang_power_snatch"], rationale: "CF通用进阶"),
        s("power_clean_and_jerk", "力量翻站挺举", "wl_m08", .l4, "奥举", "次数",
          intro: "力量翻站接挺举的奥举复合动作。", steps: "翻站至前架位站直，再微屈膝爆发挺举过头锁定，下蹲接杠后站直。", keyPoints: "脊柱、膝关节有创伤或破坏性改变者慎做。",
          scaling: "减重 / 拆成力量翻站+挺举", prereqs: ["power_clean", "jerk"], rationale: "CF通用进阶"),
        s("single_arm_db_overhead_squat", "单臂哑铃过头深蹲", "wl_m04", .l4, "深蹲", "次数",
          intro: "单臂将哑铃锁定过头完成深蹲。", steps: "单臂把哑铃稳定锁定过头、贴近身体中线，肩部稳定下蹲后站直。", keyPoints: nil,
          scaling: "减重 / 双臂过头深蹲", prereqs: ["overhead_squat"], rationale: "CF通用进阶"),
        s("dumbbell_squat_snatch", "哑铃下蹲抓举", "wl_m08", .l4, "奥举", "次数",
          intro: "单臂哑铃举过头并全深蹲接住。", steps: "哑铃于两膝间，伸髋伸膝上拉贴身，下蹲在过头位接住锁定，蹬地站直。", keyPoints: nil,
          scaling: "减重 / 哑铃力量抓举", prereqs: ["dumbbell_power_snatch", "overhead_squat"], rationale: "CF通用进阶"),
        s("dumbbell_hang_squat_clean", "哑铃悬垂下蹲翻站", "wl_m08", .l4, "奥举", "次数",
          intro: "哑铃从悬垂位翻至肩并下蹲接住。", steps: "哑铃悬于大腿，爆发上拉下蹲在肩前接住，再伸髋伸膝站直。", keyPoints: nil,
          scaling: "减重 / 哑铃下蹲翻站", prereqs: ["dumbbell_squat_clean"], rationale: "CF通用进阶"),
        s("hang_squat_clean", "悬垂下蹲翻站", "wl_m08", .l4, "奥举", "次数",
          intro: "从悬垂位翻站接全深蹲。", steps: "杠铃悬于大腿，伸髋耸肩拉起，快速翻肘下蹲在前架位接杠，蹬地站直。", keyPoints: "脊柱、膝关节有创伤或破坏性改变者慎做。",
          scaling: "减重 / 悬垂翻站", prereqs: ["hang_clean", "front_squat"], rationale: "CF通用进阶"),
        s("hang_power_snatch", "悬垂力量抓举", "wl_m08", .l4, "奥举", "次数",
          intro: "从悬垂位一次性举过头、不深蹲。", steps: "杠铃悬于大腿，伸髋耸肩爆发上拉，过头翻腕在高位接杠锁定站直。", keyPoints: nil,
          scaling: "减重 / 高悬垂位抓举", prereqs: ["overhead_squat"], rationale: "CF通用进阶"),
        s("hang_snatch", "悬垂抓举", "wl_m08", .l4, "奥举", "次数",
          intro: "从悬垂位一次性举过头并下蹲接杠。", steps: "杠铃悬于大腿，伸髋耸肩拉起，翻腕在下蹲位接杠锁定，站直。", keyPoints: "脊柱、膝关节有创伤或破坏性改变者慎做。",
          scaling: "减重 / 悬垂力量抓举", prereqs: ["hang_power_snatch", "overhead_squat"], rationale: "CF通用进阶"),
        s("jerk", "挺举", "wl_m05", .l4, "上肢推(过头)", "次数",
          intro: "将杠铃从肩送过头并下蹲接杠。", steps: "前架微屈膝下蹲，爆发蹬地推杠过头，快速下蹲在手臂锁定位接住后站直。", keyPoints: "脊柱、膝关节有创伤或破坏性改变者慎做。",
          scaling: "减重 / 借力挺举", prereqs: ["push_press", "push_jerk"], rationale: "源数据+CF"),
        s("clean_and_jerk", "翻站挺举", "wl_m08", .l4, "奥举", "次数",
          intro: "杠铃从地面翻至肩、再挺举过头的奥举动作。", steps: "硬拉发力翻至前架位接住站直，再微屈膝爆发挺举过头、分腿接杠锁定后收脚站直。", keyPoints: "脊柱、膝关节有创伤或破坏性改变者慎做。",
          scaling: "减重 / 力量翻站挺举 / 拆成翻站+挺举", prereqs: ["clean", "jerk"], rationale: "CF通用进阶"),
        s("cluster", "翻站接深蹲推举", "wl_m09", .l4, "复合全身", "次数",
          intro: "下蹲翻站接深蹲推举的复合动作。", steps: "杠铃从地面翻至前架位下蹲，蹬地起身借力直接推举过头锁定。", keyPoints: "每次从地面开始。",
          scaling: "减重 / 拆成下蹲翻站+深蹲推举", prereqs: ["squat_clean", "thruster"], rationale: "CF通用进阶"),
        s("overhead_squat", "过头深蹲", "wl_m04", .l4, "深蹲", "次数",
          intro: "杠铃举过头完成深蹲，难度较高。", steps: "抓举握距将杠铃锁定过头、肘部伸直，保持杠铃在头上方下蹲至髋低于膝，蹬地站直。", keyPoints: "下蹲时髋折低于膝、全程肘部锁定；也是学习抓举接杠与改善灵活性的练习。",
          scaling: "减重或持PVC / 前蹲+过头持杆", prereqs: ["front_squat"], rationale: "源数据+CF"),
        s("squat_snatch", "下蹲抓举", "wl_m08", .l5, "奥举", "次数",
          intro: "杠铃从地面一次性举过头并全深蹲接杠。", steps: "宽握拉起贴身、三关节伸展，翻腕在过头深蹲位接住锁定，蹬地站直。", keyPoints: "全程肘部锁定，过头深蹲位接杠。",
          scaling: "减重 / 力量抓举", prereqs: ["power_snatch", "overhead_squat"], rationale: "CF通用进阶"),
        s("hang_squat_snatch", "悬垂下蹲抓举", "wl_m08", .l5, "奥举", "次数",
          intro: "从悬垂位一次性举过头并全深蹲接杠。", steps: "杠铃悬于大腿，伸髋耸肩拉起，翻腕在过头深蹲位接住锁定，站直。", keyPoints: "脊柱、膝关节有创伤或破坏性改变者慎做。",
          scaling: "减重 / 悬垂抓举", prereqs: ["hang_snatch", "overhead_squat"], rationale: "CF通用进阶"),
        s("snatch", "抓举", "wl_m08", .l5, "奥举", "次数",
          intro: "杠铃从地面一次性举过头并下蹲接杠。", steps: "宽握拉起贴身、三关节伸展，翻腕在过头深蹲位接住锁定，再蹬地站直。", keyPoints: "技巧性很强的爆发动作，动作完美时重量会显得很轻。",
          scaling: "减重 / 力量抓举", prereqs: ["power_snatch", "overhead_squat"], rationale: "CF通用进阶")
    ]

    // MARK: - Helper

    private static func s(_ id: String, _ name: String, _ sub: String, _ tier: SkillTier,
                          _ measure: String, _ pattern: String,
                          intro: String, steps: String, keyPoints: String?,
                          scaling: String, prereqs: [String] = [], rationale: String? = nil) -> SkillDefinition {
        // 注意：参数顺序 measure 在 pattern 之前是生成器约定；此处显式映射，避免歧义。
        SkillDefinition(
            id: id, name: name, tier: tier,
            categoryId: sub.hasPrefix("gym") ? "gymnastics" : "weightlifting",
            subcategoryId: sub, movementPattern: pattern, measure: measure,
            intro: intro, steps: steps, keyPoints: keyPoints,
            scaling: scaling, prerequisites: prereqs, prereqRationale: rationale
        )
    }
}
