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

@Model final class SkillStatus {
    @Attribute(.unique) var skillId: String
    var statusRaw: String
    var updatedAt: Date

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
    var skillId: String
    var date: Date
    var value: Double
    var unit: String   // "kg" | "lb" | "reps" | "seconds"
    var notes: String?

    init(skillId: String, date: Date = Date(), value: Double, unit: String, notes: String? = nil) {
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
