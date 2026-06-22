import StoreKit
import SwiftUI

/// 付费墙触发场景，决定顶部标题文案。
enum PaywallContext {
    case watermark   // 去水印
    case proStyle    // Pro 卡片模板
    case ocrLimit    // OCR 每日限额
    case general     // 「我的」主动升级入口

    var headline: LocalizedStringKey {
        switch self {
        case .watermark: "去除卡片水印"
        case .proStyle: "解锁 Pro 卡片模板"
        case .ocrLimit: "今日免费识别已用完"
        case .general: "升级 WOD Trace Pro"
        }
    }

    var subheadline: LocalizedStringKey {
        switch self {
        case .watermark: "订阅 Pro，分享无「@迹录 WOD」水印的纯净卡片。"
        case .proStyle: "订阅 Pro，解锁全部高级卡片模板。"
        case .ocrLimit: "免费版每天可识别 2 次。升级 Pro 后拍照识别不限次数。"
        case .general: "解锁全部 Pro 权益，专注训练记录。"
        }
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    let context: PaywallContext
    var subscriptions: SubscriptionManager

    @State private var selectedProductID: String?
    @State private var legalDocument: LegalDocument?
    @State private var errorMessage: String?
    @State private var isRestoring = false

    private static let benefits: [(icon: String, text: LocalizedStringKey)] = [
        ("drop.fill", "去除卡片「@迹录 WOD」水印"),
        ("camera.viewfinder", "拍照识别不限次数"),
        ("sparkles", "Pro 高级卡片模板（陆续上线）"),
        ("chart.bar.fill", "高级数据统计（陆续上线）")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WTSpacing.lg) {
                    header
                    benefitsList
                    productCards
                    subscribeButton
                    restoreAndLegal
                }
                .padding(WTSpacing.lg)
            }
            .background(Color.wtBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.wtTextSecondary)
                    }
                }
            }
        }
        .task {
            await subscriptions.loadProducts()
            if selectedProductID == nil {
                selectedProductID = subscriptions.yearlyProduct?.id ?? subscriptions.products.first?.id
            }
        }
        .sheet(item: $legalDocument) { LegalDocumentSheet(document: $0) }
        .alert("提示", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - 区块

    private var header: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Image(systemName: "crown.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.wtPrimary)
                .padding(.bottom, WTSpacing.xs)
            Text(context.headline)
                .font(WTFont.largeTitle)
                .foregroundStyle(Color.wtTextPrimary)
            Text(context.subheadline)
                .font(WTFont.body)
                .foregroundStyle(Color.wtTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md) {
            ForEach(Self.benefits, id: \.icon) { benefit in
                HStack(spacing: WTSpacing.md) {
                    Image(systemName: benefit.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.wtPrimary)
                        .frame(width: 24)
                    Text(benefit.text)
                        .font(WTFont.body)
                        .foregroundStyle(Color.wtTextPrimary)
                }
            }
        }
    }

    @ViewBuilder private var productCards: some View {
        if subscriptions.isLoadingProducts && subscriptions.products.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, WTSpacing.lg)
        } else if subscriptions.products.isEmpty {
            Text("商品暂时无法加载，请检查网络后重试。")
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, WTSpacing.lg)
        } else {
            VStack(spacing: WTSpacing.sm) {
                ForEach(subscriptions.products, id: \.id) { product in
                    productCard(product)
                }
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        let isYearly = product.id == SubscriptionManager.ProductID.yearly
        return Button {
            selectedProductID = product.id
        } label: {
            HStack(spacing: WTSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(periodTitle(for: product))
                        .font(WTFont.bodyBold)
                        .foregroundStyle(Color.wtTextPrimary)
                    if isYearly {
                        Text("最划算")
                            .font(WTFont.micro)
                            .foregroundStyle(Color.wtPrimary)
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(WTFont.bodyBold)
                    .foregroundStyle(Color.wtTextPrimary)
            }
            .padding(WTSpacing.md)
            .selectableChip(isOn: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var subscribeButton: some View {
        let purchasing = subscriptions.purchasingProductID != nil
        return WTButton(
            title: purchasing ? "处理中…" : "订阅",
            isEnabled: selectedProductID != nil && !purchasing
        ) {
            Task { await subscribe() }
        }
    }

    private var restoreAndLegal: some View {
        VStack(spacing: WTSpacing.md) {
            Button {
                Task { await restore() }
            } label: {
                Text(isRestoring ? "恢复中…" : "恢复购买")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
            }
            .disabled(isRestoring)

            HStack(spacing: WTSpacing.xs) {
                Button("用户协议") { legalDocument = .userAgreement }
                Text("·").foregroundStyle(Color.wtTextDisabled)
                Button("隐私政策") { legalDocument = .privacyPolicy }
            }
            .font(WTFont.micro)
            .foregroundStyle(Color.wtTextSecondary)

            Text("订阅会自动续期，可随时在系统「订阅」中取消。")
                .font(WTFont.micro)
                .foregroundStyle(Color.wtTextDisabled)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, WTSpacing.sm)
    }

    // MARK: - 动作

    private func subscribe() async {
        guard let id = selectedProductID,
              let product = subscriptions.products.first(where: { $0.id == id }) else { return }
        let outcome = await subscriptions.purchase(product)
        switch outcome {
        case .success:
            dismiss()
        case .userCancelled:
            break
        case .pending:
            errorMessage = String(localized: "购买待确认，完成后将自动解锁。")
        case .failed(let message):
            errorMessage = message
        }
    }

    private func restore() async {
        isRestoring = true
        let restored = await subscriptions.restore()
        isRestoring = false
        if restored {
            dismiss()
        } else {
            errorMessage = String(localized: "未找到可恢复的订阅。")
        }
    }

    /// 周期标题：优先用 StoreKit 订阅周期，缺失时退回商品名。
    private func periodTitle(for product: Product) -> LocalizedStringKey {
        switch product.subscription?.subscriptionPeriod.unit {
        case .year: "年订阅"
        case .month: "月订阅"
        default: LocalizedStringKey(product.displayName)
        }
    }
}
