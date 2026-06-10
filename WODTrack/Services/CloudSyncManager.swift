import CloudKit
import Foundation
import Observation
import SwiftData
import SwiftUI

/// iCloud 同步状态管理：开关持久化、系统 iCloud 账号状态、容器重建调度、卡片图回填与去重。
/// 身份相关状态在 AppState，这里只管同步。
@Observable
final class CloudSyncManager {
    static let containerIdentifier = "iCloud.com.chenxi.WODTrack"
    private static let syncEnabledKey = "wt.iCloudSyncEnabled"

    /// 用户的同步意图（开过即记住）。退出登录时不清除，重新登录后自动恢复同步。
    var isSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(isSyncEnabled, forKey: Self.syncEnabledKey) }
    }

    /// 每次重建 ModelContainer 递增，驱动 ContentView 整树重建（旧容器的 @Query 不可跨容器存活）。
    var containerGeneration = 0
    /// 容器切换进行中，开关 UI 禁用。
    var isSwapping = false
    var accountStatus: CKAccountStatus = .couldNotDetermine
    var inviteBannerDismissedThisSession = false

    @ObservationIgnored private var maintenanceTask: Task<Void, Never>?
    @ObservationIgnored private var lastSceneDedupAt: Date = .distantPast
    @ObservationIgnored private var accountObserver: NSObjectProtocol?
    @ObservationIgnored private weak var currentContainer: ModelContainer?

    init() {
        isSyncEnabled = UserDefaults.standard.bool(forKey: Self.syncEnabledKey)
        accountObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged, object: nil, queue: .main
        ) { [weak self] _ in
            Task { await self?.refreshAccountStatus() }
        }
    }

    // MARK: - 账号状态（崩溃陷阱总闸：无 entitlement 时 accountStatus 调用失败 → 开关永远开不了）

    @discardableResult
    func refreshAccountStatus() async -> CKAccountStatus {
        let status: CKAccountStatus
        do {
            status = try await CKContainer(identifier: Self.containerIdentifier).accountStatus()
        } catch {
            status = .couldNotDetermine
        }
        await MainActor.run { accountStatus = status }
        return status
    }

    /// 仅系统 iCloud 账号可用时才允许开启同步。
    func requestEnableSync() async -> Bool {
        let status = await refreshAccountStatus()
        guard status == .available else { return false }
        await MainActor.run { isSyncEnabled = true }
        return true
    }

    // MARK: - 容器重建配合

    /// 重建容器前调用：取消还在跑的回填/去重任务。
    func prepareForContainerSwap() {
        maintenanceTask?.cancel()
        maintenanceTask = nil
        isSwapping = true
    }

    /// 重建完成后调用。syncActive = 新容器是否处于 CloudKit 镜像模式。
    func onContainerRebuilt(_ container: ModelContainer, syncActive: Bool) {
        currentContainer = container
        isSwapping = false
        if syncActive {
            startMaintenance(on: container)
        }
    }

    /// scenePhase 变 active 时调用（同步开启时 30s 防抖跑一次去重）。
    func sceneBecameActive(syncActive: Bool) {
        guard syncActive, let container = currentContainer else { return }
        guard Date.now.timeIntervalSince(lastSceneDedupAt) > 30 else { return }
        lastSceneDedupAt = .now
        Task { @MainActor in
            SyncDedupService.dedupAll(context: container.mainContext)
        }
    }

    // MARK: - 回填 + 去重

    /// 卡片图回填（旧记录把文件字节补进 cardImageData，幂等可中断），随后去重。
    private func startMaintenance(on container: ModelContainer) {
        maintenanceTask = Task { @MainActor in
            let context = container.mainContext

            let descriptor = FetchDescriptor<WODRecord>(
                predicate: #Predicate { $0.cardImageData == nil && $0.cardImagePath != nil }
            )
            if let pending = try? context.fetch(descriptor) {
                var processed = 0
                for record in pending {
                    if Task.isCancelled { return }
                    guard let path = record.cardImagePath,
                          let data = try? Data(contentsOf: URL(fileURLWithPath: ImagePathResolver.resolve(path))) else {
                        continue
                    }
                    record.cardImageData = data
                    processed += 1
                    if processed % 10 == 0 {
                        try? context.save()
                    }
                }
                try? context.save()
            }

            if Task.isCancelled { return }
            SyncDedupService.dedupAll(context: context)
        }
    }
}
