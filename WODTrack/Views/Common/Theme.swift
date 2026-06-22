import SwiftUI
import UIKit

extension Color {
    static let wtPrimary = Color(hex: "#5BE88F")
    static let wtBackground = Color(hex: "#0D0D0D")
    static let wtSurface = Color(hex: "#1A1A1A")
    static let wtSurface2 = Color(hex: "#2A2A2A")
    static let wtTextPrimary = Color(hex: "#FFFFFF")
    static let wtTextSecondary = Color(hex: "#8A8A8A")
    static let wtTextDisabled = Color(hex: "#444444")
    static let wtSuccess = Color(hex: "#34C759")
    static let wtDanger = Color(hex: "#FF3B30")
    /// 「进行中」状态强调色（蓝，与已掌握的绿区分）。
    static let wtInProgress = Color(hex: "#5E81F4")
}

enum WTFont {
    static let largeTitle = Font.system(size: 28, weight: .bold)
    static let title = Font.system(size: 20, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let bodyBold = Font.system(size: 16, weight: .semibold)
    static let caption = Font.system(size: 13, weight: .regular)
    static let micro = Font.system(size: 11, weight: .regular)

    /// 等宽数据字体（工程风读数：英文名、L1、日期、SKILL·INDEX 等标签）。
    /// iOS 无 Geist Mono，统一用系统 SF Mono（`.monospaced`）。
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

enum WTSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum WTRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let full: CGFloat = 9999
}

/// 统一的「选中=淡色填充+描边」样式，降低整页实心锚点，保持选中效果一致。
extension View {
    /// 圆角矩形版本。tint 默认主绿色，可传入状态色复用。
    func selectableChip(isOn: Bool, tint: Color = .wtPrimary, cornerRadius: CGFloat = WTRadius.md) -> some View {
        background(isOn ? tint.opacity(0.15) : Color.wtSurface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isOn ? tint : Color.clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// 胶囊版本，用于横向筛选 chip。
    func selectablePill(isOn: Bool, tint: Color = .wtPrimary) -> some View {
        background(isOn ? tint.opacity(0.15) : Color.wtSurface)
            .overlay(
                Capsule().stroke(isOn ? tint : Color.clear, lineWidth: 1.5)
            )
            .clipShape(Capsule())
            .contentShape(Capsule())
    }
}

struct WTButton: View {
    enum Style {
        case primary
        case secondary
        case ghost
    }

    let title: LocalizedStringKey
    var style: Style = .primary
    var isEnabled = true
    var maxWidth: CGFloat? = .infinity
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(WTFont.bodyBold)
                .frame(maxWidth: maxWidth)
                .frame(height: 50)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .background(background)
        .overlay(border)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
        .contentShape(RoundedRectangle(cornerRadius: WTRadius.md))
        .opacity(isEnabled ? 1 : 0.4)
        .disabled(!isEnabled)
    }

    private var foreground: Color {
        switch style {
        case .primary: .black
        case .secondary: .wtPrimary
        case .ghost: .wtTextSecondary
        }
    }

    @ViewBuilder private var background: some View {
        RoundedRectangle(cornerRadius: WTRadius.md)
            .fill(style == .primary ? Color.wtPrimary : .clear)
    }

    @ViewBuilder private var border: some View {
        RoundedRectangle(cornerRadius: WTRadius.md)
            .stroke(style == .secondary ? Color.wtPrimary : .clear, lineWidth: 1)
    }
}

struct WTTextField: View {
    let title: LocalizedStringKey
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.xs) {
            Text(title)
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            TextField(placeholder, text: $text, axis: axis)
                .font(WTFont.body)
                .foregroundStyle(Color.wtTextPrimary)
                .padding(12)
                .background(Color.wtSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.wtSurface2, lineWidth: 1)
                )
        }
    }
}

struct WTTextEditor: View {
    let title: LocalizedStringKey
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var minHeight: CGFloat = 220
    /// 输入框内部底部的附件（如「自动识别」按钮）
    var bottomAccessory: AnyView? = nil

    private var bottomInset: CGFloat { bottomAccessory == nil ? 8 : 62 }

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.xs) {
            Text(title)
                .font(WTFont.caption)
                .foregroundStyle(Color.wtTextSecondary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.wtSurface)

                if text.isEmpty {
                    Text(placeholder)
                        .font(WTFont.body)
                        .foregroundStyle(Color.wtTextDisabled)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .font(WTFont.body)
                    .foregroundStyle(Color.wtTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, bottomInset)
                    .background(Color.clear)
            }
            .frame(minHeight: minHeight)
            .overlay(alignment: .bottom) {
                bottomAccessory
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.wtSurface2, lineWidth: 1)
            )
        }
    }
}

struct WTToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    HStack(spacing: WTSpacing.sm) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(Color.wtPrimary)
                        Text(message)
                            .font(WTFont.bodyBold)
                            .foregroundStyle(Color.wtTextPrimary)
                    }
                    .padding(.horizontal, WTSpacing.md + 2)
                    .padding(.vertical, 11)
                    .background(Color.wtSurface2.opacity(0.96))
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: message)
            .task(id: message) {
                guard message != nil else { return }
                try? await Task.sleep(for: .seconds(2))
                message = nil
            }
    }
}

extension View {
    func wtToast(message: Binding<String?>) -> some View {
        modifier(WTToastModifier(message: message))
    }
}

struct LoadingOverlay: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?

    var body: some View {
        VStack(spacing: WTSpacing.md) {
            ProgressView()
                .tint(.wtPrimary)
                .scaleEffect(1.2)
            Text(title)
                .font(WTFont.title)
            if let subtitle {
                Text(subtitle)
                    .font(WTFont.body)
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
        .padding(WTSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.wtBackground)
    }
}

extension Color {
    init(hex: String) {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r, g, b, a: UInt64
        switch sanitized.count {
        case 6:
            (r, g, b, a) = ((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)
        default:
            (r, g, b, a) = (255, 255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

// MARK: - 点击空白处收起键盘（全局安装一次，不拦截按钮 / 滚动）

/// 收起键盘的动作目标 + 手势代理（单例，需被静态持有）。
final class KeyboardDismisser: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismisser()

    @objc func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // 与滚动 / 其它手势同时识别，避免吞掉滑动
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool { true }
}

/// 主页面全局背景：纯黑底 + 顶部柔和绿色光晕，呼应产品绿色调性。
/// 用法：`.background(WTScreenBackground())`，已自带 `ignoresSafeArea`。
struct WTScreenBackground: View {
    var body: some View {
        ZStack {
            Color.wtBackground
            RadialGradient(
                colors: [Color.wtPrimary.opacity(0.16), .clear],
                center: .init(x: 1.0, y: 0.0),
                startRadius: 0,
                endRadius: 720
            )
        }
        .ignoresSafeArea()
    }
}

extension UIApplication {
    /// 安装一次全局点击手势：点任意空白处收起键盘。
    /// `cancelsTouchesInView = false` 保证按钮 / 输入框 / 列表点击与滚动一切照常。
    func installKeyboardDismissTapIfNeeded() {
        let keyWindow = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        guard let window = keyWindow else { return }

        let recognizerName = "wt.keyboardDismissTap"
        if window.gestureRecognizers?.contains(where: { $0.name == recognizerName }) == true { return }

        let tap = UITapGestureRecognizer(target: KeyboardDismisser.shared, action: #selector(KeyboardDismisser.dismiss))
        tap.name = recognizerName
        tap.cancelsTouchesInView = false
        tap.delegate = KeyboardDismisser.shared
        window.addGestureRecognizer(tap)
    }
}

