import Foundation
import SwiftData

enum SkillMasteryStatus: String, Codable {
    case unmarked, wantToLearn, inProgress, mastered

    var label: String {
        switch self {
        case .unmarked: "未标记"
        case .wantToLearn: "想学"
        case .inProgress: "进行中"
        case .mastered: "已掌握"
        }
    }
}

// CloudKit 约束：去 .unique（skillId 唯一性由 SyncDedupService 去重）；非可选需声明处默认值。
@Model final class SkillStatus {
    var skillId: String = ""
    var statusRaw: String = "unmarked"
    var updatedAt: Date = Date.now

    init(skillId: String, status: SkillMasteryStatus = .unmarked) {
        self.skillId = skillId
        self.statusRaw = status.rawValue
        self.updatedAt = Date()
    }

    var status: SkillMasteryStatus {
        get { SkillMasteryStatus(rawValue: statusRaw) ?? .unmarked }
        set { statusRaw = newValue.rawValue; updatedAt = Date() }
    }
}

@Model final class SkillTrainingEntry {
    /// 去重身份键（CloudKit 不支持 unique，合并后按它识别同一条目）
    var entryId: UUID = UUID()
    var skillId: String = ""
    var date: Date = Date.now
    var value: Double = 0
    var unit: String = ""   // "kg" | "lb" | "reps" | "seconds"
    var notes: String?

    init(skillId: String, date: Date = Date(), value: Double, unit: String, notes: String? = nil) {
        self.entryId = UUID()
        self.skillId = skillId
        self.date = date
        self.value = value
        self.unit = unit
        self.notes = notes
    }

    var formattedValue: String {
        let isWholeNumber = value.truncatingRemainder(dividingBy: 1) == 0
        let numStr = isWholeNumber ? String(Int(value)) : String(format: "%.1f", value)
        return "\(numStr) \(unit)"
    }
}
