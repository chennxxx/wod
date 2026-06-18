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

extension Collection where Element == SkillStatus {
    /// 按 skillId 建索引。**必须用 uniquingKeysWith 而非 uniqueKeysWithValues**：CloudKit 无 unique 约束，
    /// 多设备合并 / 种子与云端拉取相撞会出现同一 skillId 的重复行，而去重（SyncDedupService）是异步的，
    /// 视图可能在去重完成前就渲染到重复行 —— 用 uniqueKeysWithValues 会直接 fatalError 崩溃。
    /// 重复时保留 updatedAt 最新，与 SyncDedupService.dedupSkillStatuses 的 LWW 策略一致。
    var indexedBySkillId: [String: SkillStatus] {
        Dictionary(map { ($0.skillId, $0) }) { $0.updatedAt >= $1.updatedAt ? $0 : $1 }
    }
}

// MARK: - 默认掌握动作（新用户首启种子）

/// 新用户首次启动时，把几个最基础的动作默认标记为「已掌握」，
/// 让仪表盘一打开就有进度、不空。仅执行一次（UserDefaults 标记）。
enum SkillStatusSeeder {
    static let defaultMasteredIds = ["sit_up", "bear_crawl", "row", "single_under", "farmers_walk"]
    static let defaultInProgressIds = ["push_up", "air_squat", "dumbbell_deadlift"]
    private static let seededKey = "wt.skillDefaultsSeeded.v2"

    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey) else { return }

        let existing = (try? context.fetch(FetchDescriptor<SkillStatus>())) ?? []
        let existingIds = Set(existing.map { $0.skillId })
        for id in defaultMasteredIds where !existingIds.contains(id) {
            context.insert(SkillStatus(skillId: id, status: .mastered))
        }
        for id in defaultInProgressIds where !existingIds.contains(id) {
            context.insert(SkillStatus(skillId: id, status: .inProgress))
        }
        try? context.save()
        defaults.set(true, forKey: seededKey)
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
