import Foundation
import RevenueCat

/// 订阅态唯一真相源（RevenueCat）。
/// 权益绑 Apple ID、由 RC 跨设备/换机自动收敛——不经 CloudKit，不涉及本地 store 风险。
/// 算出 isSubscribed 后回写 AppState.applyEntitlement，保持全站 `appState.isPro` 读取 API 不变。
/// 购买 UI 交给 RevenueCatUI 的 PaywallView，本类只负责配置、观察权益、恢复。
@MainActor
@Observable
final class SubscriptionManager {
    /// 当前是否有有效订阅（任一 active entitlement）。
    private(set) var isSubscribed = false
    /// 当前权益到期日（用于 Profile 展示）。
    private(set) var expiresAt: Date?

    /// AppState 弱引用，权益变化时回写。
    @ObservationIgnored weak var appState: AppState?

    @ObservationIgnored private var streamTask: Task<Void, Never>?
    @ObservationIgnored private var didConfigure = false

    /// App 启动时调用一次：配置 RC + 开始监听 customerInfo。
    func configure() {
        guard !didConfigure else { return }
        didConfigure = true

        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)

        // 全生命周期监听权益变化（购买、续期、退款、换机、家庭共享）。
        streamTask = Task { [weak self] in
            guard let self else { return }
            for await info in Purchases.shared.customerInfoStream {
                self.apply(info)
            }
        }

        // 首次立即拉一次，避免等到 stream 首帧。
        Task { await refreshEntitlement() }
    }

    deinit {
        streamTask?.cancel()
    }

    /// 启动 / 回前台重算权益。
    func refreshEntitlement() async {
        guard didConfigure else { return }
        if let info = try? await Purchases.shared.customerInfo() {
            apply(info)
        }
    }

    /// 恢复购买（Customer Center 也内置，此处留兜底入口）。
    @discardableResult
    func restore() async -> Bool {
        guard didConfigure else { return false }
        if let info = try? await Purchases.shared.restorePurchases() {
            apply(info)
        }
        return isSubscribed
    }

    // MARK: - 权益写穿

    private func apply(_ info: CustomerInfo) {
        let active = info.entitlements.active
        isSubscribed = !active.isEmpty
        // 取最晚到期日（多档时更稳）；无到期日（如买断）则为 nil。
        expiresAt = active.values.compactMap(\.expirationDate).max()
        appState?.applyEntitlement(isPro: isSubscribed, expiresAt: expiresAt)
    }
}
