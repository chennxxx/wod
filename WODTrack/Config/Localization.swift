import Foundation
import SwiftUI

// 运行时语言判定与动态数据（动作库/进阶路线）的中英取值。
// UI 字面量走 String Catalog；这里只处理「值是运行时数据」的本地化。
//
// 固定名词（分类/子类/计量/难度）数量少且枚举固定，用下方查表翻译，不进 xlsx；
// 动作的简介/步骤/要点/降阶等长文本由 xlsx 英文列经脚本生成，存在 SkillDefinition 的 english* 字段。

enum AppLanguage {
    /// 跟随系统：当前 App 实际使用的本地化是否英文。
    static var isEnglish: Bool {
        (Bundle.main.preferredLocalizations.first ?? "zh").hasPrefix("en")
    }

    /// 英文时取 en（非空则用），否则回退中文。供动态字段统一调用。
    static func pick(_ zh: String, _ en: String?) -> String {
        if isEnglish, let en, !en.isEmpty { return en }
        return zh
    }
}

// MARK: - 固定名词查表（中文 → 英文）

enum SkillTerms {
    /// 动作模式 / 子类名称
    static let movementPattern: [String: String] = [
        "核心": "Core",
        "位移有氧": "Cardio",
        "上肢拉(水平)": "Horizontal Pull",
        "上肢拉(垂直)": "Vertical Pull",
        "上肢拉(垂直)/核心": "Vertical Pull / Core",
        "上肢拉(水平)/核心": "Horizontal Pull / Core",
        "上肢推(水平)": "Horizontal Push",
        "上肢推(过头)": "Overhead Push",
        "深蹲": "Squat",
        "跳跃": "Jump",
        "弓步单腿": "Lunge / Single-Leg",
        "复合全身": "Full Body",
        "髋铰链": "Hip Hinge",
        "搬运行走": "Carry",
        "奥举": "Olympic Lifting",
    ]

    /// 计量方式
    static let measure: [String: String] = [
        "次数": "Reps",
        "距离": "Distance",
        "静力时长": "Hold Time",
        "卡路里": "Calories",
        "距离/卡路里": "Distance / Calories",
        "距离/时间": "Distance / Time",
        "距离/次数": "Distance / Reps",
    ]

    static func localized(pattern: String) -> String {
        AppLanguage.isEnglish ? (movementPattern[pattern] ?? pattern) : pattern
    }

    static func localized(measure: String) -> String {
        AppLanguage.isEnglish ? (Self.measure[measure] ?? measure) : measure
    }
}

// MARK: - 动态数据本地化扩展

extension SkillTier {
    /// 难度描述（入门/基础… ↔ Beginner/Foundation…）
    var localizedDescription: String {
        guard AppLanguage.isEnglish else { return description }
        switch self {
        case .l1: return "Beginner"
        case .l2: return "Foundation"
        case .l3: return "Intermediate"
        case .l4: return "Advanced"
        case .l5: return "Elite"
        }
    }
}

extension SkillDefinition {
    var localizedName: String { AppLanguage.pick(name, englishName) }
    var localizedIntro: String { AppLanguage.pick(intro, englishIntro) }
    var localizedSteps: String { AppLanguage.pick(steps, englishSteps) }
    var localizedScaling: String { AppLanguage.pick(scaling, englishScaling) }
    var localizedKeyPoints: String? {
        guard let keyPoints, !keyPoints.isEmpty else { return nil }
        return AppLanguage.pick(keyPoints, englishKeyPoints)
    }
    var localizedMovementPattern: String { SkillTerms.localized(pattern: movementPattern) }
    var localizedMeasure: String { SkillTerms.localized(measure: measure) }
}

extension SkillCategoryDefinition {
    var localizedName: String { AppLanguage.pick(name, englishName) }
}

extension SkillSubcategoryDefinition {
    var localizedName: String { SkillTerms.localized(pattern: name) }
}

extension ProgressionPath {
    var localizedName: String { AppLanguage.pick(name, englishName) }
    var localizedIntro: String { AppLanguage.pick(intro, englishIntro) }
}
