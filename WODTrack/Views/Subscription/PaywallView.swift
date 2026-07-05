import RevenueCat
import RevenueCatUI
import SwiftUI

/// Pro 付费墙：薄封装 RevenueCatUI 的 `PaywallView`（样式在 RC 后台 Paywalls 编辑器里配置、远程渲染）。
/// 各门控入口（OCR 触发卡、去水印、Pro 主题/模板、历史、Profile 升级）统一 present 这一个。
/// 购买 / 恢复成功后由 RC 的 `customerInfoStream` 自动刷新 `appState.isPro`，此处仅回调关闭 + 提示。
struct ProPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// 购买或恢复到有效权益后回调（一般用于 toast）。
    var onEntitled: () -> Void = {}

    var body: some View {
        PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { _ in
                onEntitled()
                dismiss()
            }
            .onRestoreCompleted { customerInfo in
                if !customerInfo.entitlements.active.isEmpty {
                    onEntitled()
                }
                dismiss()
            }
    }
}
