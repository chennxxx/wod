import SwiftData
import SwiftUI
import UIKit

@main
struct WODTrackApp: App {
    @State private var appState: AppState
    @State private var syncManager: CloudSyncManager
    @State private var subscriptions: SubscriptionManager
    @State private var container: ModelContainer

    init() {
        let appState = AppState()
        let syncManager = CloudSyncManager()
        let subscriptions = SubscriptionManager()
        // 订阅态真相源在 RevenueCat；管理器建在 App 层并持 appState 弱引用回写权益。
        // 必须建在 App 层：ContentView 因 .id(containerGeneration) 会随 iCloud 开关整树重建，
        // 管理器若建在视图内会被销毁、丢失 customerInfo 长监听。
        subscriptions.appState = appState
        subscriptions.configure()
        let syncActive = syncManager.isSyncEnabled && appState.profile.isLoggedIn
        let container = Self.makeContainer(syncEnabled: syncActive)
        appState.modelContainer = container
        _appState = State(initialValue: appState)
        _syncManager = State(initialValue: syncManager)
        _subscriptions = State(initialValue: subscriptions)
        _container = State(initialValue: container)
    }

    /// 有效同步态：开关开 且 App 已登录（退出登录 = 同步暂停，意图保留）。
    private var syncActive: Bool {
        syncManager.isSyncEnabled && appState.profile.isLoggedIn
    }

    /// 同一存储文件在 .none ↔ .private 间交替创建受支持（CloudKit 镜像元数据存于 store）。
    static func makeContainer(syncEnabled: Bool) -> ModelContainer {
        let schema = Schema([WODRecord.self, SkillStatus.self, SkillTrainingEntry.self, SyncedProfile.self])
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
            ContentView(appState: appState, syncManager: syncManager, subscriptions: subscriptions)
                .id(syncManager.containerGeneration)
                .preferredColorScheme(.dark)
                .onChange(of: syncActive) {
                    rebuildContainer()
                }
                .task {
                    await subscriptions.refreshEntitlement()
                }
                .onAppear {
                    syncManager.onContainerRebuilt(container, syncActive: syncActive)
                    DispatchQueue.main.async {
                        UIApplication.shared.installKeyboardDismissTapIfNeeded()
                    }
                }
        }
        .modelContainer(container)
    }

    @MainActor
    private func rebuildContainer() {
        syncManager.prepareForContainerSwap()
        container = Self.makeContainer(syncEnabled: syncActive)
        appState.modelContainer = container
        syncManager.containerGeneration += 1
        syncManager.onContainerRebuilt(container, syncActive: syncActive)
        appState.reconcileProfile(context: container.mainContext)
    }
}
