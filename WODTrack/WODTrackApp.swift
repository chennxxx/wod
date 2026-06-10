import SwiftData
import SwiftUI

@main
struct WODTrackApp: App {
    @State private var appState: AppState
    @State private var syncManager: CloudSyncManager
    @State private var container: ModelContainer

    init() {
        let appState = AppState()
        let syncManager = CloudSyncManager()
        let syncActive = syncManager.isSyncEnabled && appState.profile.isLoggedIn
        _appState = State(initialValue: appState)
        _syncManager = State(initialValue: syncManager)
        _container = State(initialValue: Self.makeContainer(syncEnabled: syncActive))
    }

    /// 有效同步态：开关开 且 App 已登录（退出登录 = 同步暂停，意图保留）。
    private var syncActive: Bool {
        syncManager.isSyncEnabled && appState.profile.isLoggedIn
    }

    /// 同一存储文件在 .none ↔ .private 间交替创建受支持（CloudKit 镜像元数据存于 store）。
    static func makeContainer(syncEnabled: Bool) -> ModelContainer {
        let schema = Schema([WODRecord.self, SkillStatus.self, SkillTrainingEntry.self])
        do {
            let configuration = ModelConfiguration(
                "WODTrackStore_v3",
                schema: schema,
                cloudKitDatabase: syncEnabled ? .private(CloudSyncManager.containerIdentifier) : .none
            )
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // 同步模式创建失败：关闭开关回退纯本地，保证可用
            UserDefaults.standard.set(false, forKey: "wt.iCloudSyncEnabled")
            let fallback = ModelConfiguration("WODTrackStore_v3", schema: schema, cloudKitDatabase: .none)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState, syncManager: syncManager)
                .id(syncManager.containerGeneration)
                .preferredColorScheme(.dark)
                .onChange(of: syncActive) {
                    rebuildContainer()
                }
                .onAppear {
                    syncManager.onContainerRebuilt(container, syncActive: syncActive)
                }
        }
        .modelContainer(container)
    }

    private func rebuildContainer() {
        syncManager.prepareForContainerSwap()
        container = Self.makeContainer(syncEnabled: syncActive)
        syncManager.containerGeneration += 1
        syncManager.onContainerRebuilt(container, syncActive: syncActive)
    }
}
