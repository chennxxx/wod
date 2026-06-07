import SwiftUI

extension Color {
    static let wtPrimary = Color(hex: "#F5C518")
    static let wtBackground = Color(hex: "#0D0D0D")
    static let wtSurface = Color(hex: "#1A1A1A")
    static let wtSurface2 = Color(hex: "#2A2A2A")
    static let wtTextPrimary = Color(hex: "#FFFFFF")
    static let wtTextSecondary = Color(hex: "#8A8A8A")
    static let wtTextDisabled = Color(hex: "#444444")
    static let wtSuccess = Color(hex: "#34C759")
    static let wtDanger = Color(hex: "#FF3B30")
    static let wtWechatGreen = Color(hex: "#07C160")
}

enum WTFont {
    static let largeTitle = Font.system(size: 28, weight: .bold)
    static let title = Font.system(size: 20, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let bodyBold = Font.system(size: 16, weight: .semibold)
    static let caption = Font.system(size: 13, weight: .regular)
    static let micro = Font.system(size: 11, weight: .regular)
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

struct WTButton: View {
    enum Style {
        case primary
        case secondary
        case ghost
    }

    let title: String
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
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .background(background)
        .overlay(border)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
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
    let title: String
    let placeholder: String
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
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 220

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
                        .padding(.vertical, 14)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .font(WTFont.body)
                    .foregroundStyle(Color.wtTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
            }
            .frame(minHeight: minHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.wtSurface2, lineWidth: 1)
            )
        }
    }
}

struct LoadingOverlay: View {
    let title: String
    let subtitle: String?

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

