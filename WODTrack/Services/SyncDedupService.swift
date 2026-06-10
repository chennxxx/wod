import Foundation
import SwiftData

/// CloudKit 不支持 unique 约束，多设备合并后可能出现重复行，由这里做应用层去重。
@MainActor
enum SyncDedupService {
    static func dedupAll(context: ModelContext) {
        dedupSkillStatuses(context: context)
        dedupWODRecords(context: context)
        dedupTrainingEntries(context: context)
        dedupSyncedProfiles(context: context)
        try? context.save()
    }

    /// 资料行是 singleton：两台设备各建过一行时留 updatedAt 最新。
    private static func dedupSyncedProfiles(context: ModelContext) {
        guard let profiles = try? context.fetch(FetchDescriptor<SyncedProfile>()), profiles.count > 1 else { return }
        let sorted = profiles.sorted { $0.updatedAt > $1.updatedAt }
        for duplicate in sorted.dropFirst() {
            context.delete(duplicate)
        }
    }

    /// 同一技能两台设备各建过一条状态：留 updatedAt 最新。
    private static func dedupSkillStatuses(context: ModelContext) {
        guard let statuses = try? context.fetch(FetchDescriptor<SkillStatus>()) else { return }
        let grouped = Dictionary(grouping: statuses, by: \.skillId)
        for (_, group) in grouped where group.count > 1 {
            let sorted = group.sorted { $0.updatedAt > $1.updatedAt }
            for duplicate in sorted.dropFirst() {
                context.delete(duplicate)
            }
        }
    }

    /// 按逻辑 id 去重：留 createdAt 最早，优先保有图的实例。
    /// 注意：直接 context.delete，不走 RecordDeletionService——不能删幸存者引用的图片文件。
    private static func dedupWODRecords(context: ModelContext) {
        guard let records = try? context.fetch(FetchDescriptor<WODRecord>()) else { return }
        let grouped = Dictionary(grouping: records, by: \.id)
        for (_, group) in grouped where group.count > 1 {
            let sorted = group.sorted { lhs, rhs in
                let lhsHasImage = lhs.cardImageData != nil || lhs.cardImagePath != nil
                let rhsHasImage = rhs.cardImageData != nil || rhs.cardImagePath != nil
                if lhsHasImage != rhsHasImage { return lhsHasImage }
                return lhs.createdAt < rhs.createdAt
            }
            for duplicate in sorted.dropFirst() {
                context.delete(duplicate)
            }
        }
    }

    private static func dedupTrainingEntries(context: ModelContext) {
        guard let entries = try? context.fetch(FetchDescriptor<SkillTrainingEntry>()) else { return }
        let grouped = Dictionary(grouping: entries, by: \.entryId)
        for (_, group) in grouped where group.count > 1 {
            for duplicate in group.dropFirst() {
                context.delete(duplicate)
            }
        }
    }
}
