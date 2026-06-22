import Foundation
import StoreKit

/// 订阅态唯一真相源（StoreKit 2）。
/// 权益绑 Apple ID、由系统自动跨设备同步——**不经 CloudKit**，故不涉及本地 store 清空/Production schema 风险。
/// 算出 isSubscribed 后回写 AppState.applyEntitlement，保持全站 `appState.isPro` 读取 API 不变。
@MainActor
@Observable
final class SubscriptionManager {
    /// 自动续期订阅商品 ID（需与 .storekit 配置 / App Store Connect 完全一致）。
    enum ProductID {
        static let yearly = "com.chenxi.WODTrack.pro.yearly"
        static let monthly = "com.chenxi.WODTrack.pro.monthly"
        static let all: [String] = [yearly, monthly]
    }

    /// 可售商品，按价格档展示用（年付优先排在前）。
    private(set) var products: [Product] = []
    /// 当前是否有有效订阅。
    private(set) var isSubscribed = false
    /// 商品是否已成功拉取（用于 Paywall loading 态）。
    private(set) var isLoadingProducts = false
    /// 进行中的购买商品 ID（按钮 loading 态）。
    private(set) var purchasingProductID: String?

    /// AppState 弱引用，权益变化时回写。
    @ObservationIgnored weak var appState: AppState?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        // 全生命周期监听交易更新（续期、退款、家庭共享、其他设备购买）。
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.handle(verificationResult: update)
                await self.refreshEntitlement()
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var yearlyProduct: Product? { products.first { $0.id == ProductID.yearly } }
    var monthlyProduct: Product? { products.first { $0.id == ProductID.monthly } }

    // MARK: - 商品

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let fetched = try await Product.products(for: ProductID.all)
            // 年付排前
            products = fetched.sorted { lhs, _ in lhs.id == ProductID.yearly }
        } catch {
            products = []
        }
    }

    // MARK: - 权益计算

    /// 重算当前权益（启动、回前台、购买/恢复后调用）。
    func refreshEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productType == .autoRenewable,
                  ProductID.all.contains(transaction.productID) else { continue }
            // 已撤销或已过期不算
            if transaction.revocationDate != nil { continue }
            if let expiration = transaction.expirationDate, expiration < Date() { continue }
            active = true
        }
        isSubscribed = active
        appState?.applyEntitlement(isPro: active)
    }

    // MARK: - 购买 / 恢复

    enum PurchaseOutcome {
        case success
        case userCancelled
        case pending
        case failed(String)
    }

    @discardableResult
    func purchase(_ product: Product) async -> PurchaseOutcome {
        purchasingProductID = product.id
        defer { purchasingProductID = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verificationResult: verification)
                await refreshEntitlement()
                return .success
            case .userCancelled:
                return .userCancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed(String(localized: "购买失败，请稍后重试"))
            }
        } catch {
            return .failed(String(localized: "购买失败，请稍后重试"))
        }
    }

    func restore() async -> Bool {
        try? await AppStore.sync()
        await refreshEntitlement()
        return isSubscribed
    }

    // MARK: - 交易核销

    private func handle(verificationResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verificationResult else { return }
        await transaction.finish()
    }
}
