import SwiftUI

/// T2 触发卡（OCR 每日额度用尽时半屏弹出，利益前置直奔订阅）。
/// 视觉钩子：白板照片 →（绿箭头）→ 发光成绩卡，一眼说清「拍了能变成什么」。
/// 还原 `flow.jsx` 的 TriggerSheet；作为 `.sheet` 内容，由调用方设 detents。
struct TriggerSheet: View {
    /// 点主 CTA：进 Paywall。
    let onTrial: () -> Void
    /// 点「先手动记录这条」：关闭，回表单继续手动输入。
    let onManual: () -> Void

    var body: some View {
        VStack(spacing: WTSpacing.md) {
            hook
                .padding(.top, WTSpacing.sm)

            VStack(spacing: WTSpacing.sm) {
                Text("白板一拍，自动成卡")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.wtTextPrimary)
                Text("升级 Pro 享无限次白板拍照识别（免费版每天仅限 \(AppConfig.freeOCRDailyLimit) 次）")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, WTSpacing.md)

            WTButton(title: "升级到专业版", action: onTrial)

            Button(action: onManual) {
                Text("先手动记录这条")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
            }
            .padding(.top, WTSpacing.xs)
        }
        .padding(WTSpacing.lg)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 白板 →（箭头）→ 成绩卡

    private var hook: some View {
        HStack(spacing: WTSpacing.md) {
            whiteboardTile
            Image(systemName: "arrow.right")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.wtPrimary)
            resultCard
        }
    }

    private var whiteboardTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .fill(Color.wtSurface2)
            VStack(spacing: WTSpacing.xs) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.wtTextDisabled)
                Text("白板照片")
                    .font(WTFont.micro)
                    .foregroundStyle(Color.wtTextDisabled)
            }
        }
        .frame(width: 80, height: 106)
    }

    /// 发光的迷你成绩卡（呼应产品自己的分享卡输出）。
    private var resultCard: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#2B2F2C"), Color(hex: "#16201A")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .center, endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 3) {
                Text("迹录")
                    .font(WTFont.mono(8))
                    .foregroundStyle(.white.opacity(0.32))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text("3:48")
                    .font(WTFont.mono(24, weight: .black))
                    .foregroundStyle(.white)
                HStack {
                    Text("06.22 · FRAN")
                        .font(WTFont.mono(8))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("RX")
                        .font(WTFont.mono(8, weight: .bold))
                        .foregroundStyle(Color(hex: "#07301C"))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color.wtPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(9)
        }
        .frame(width: 92, height: 115)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.wtPrimary.opacity(0.25), lineWidth: 1))
        .shadow(color: Color.wtPrimary.opacity(0.28), radius: 14, y: 8)
    }
}
