import SwiftUI

/// 分享卡配色主题。一键换肤：决定文字色 + 卡底/留白色 + 强调色，不改模板布局。
/// 「配色主题为主、手动微调为辅」——「文字」面板仍可改字体 / 字号 / 透明度。
enum CardColorTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case neon
    case film
    case ocean
    case contrast

    var id: String { rawValue }

    /// 免费：浅色 / 深色 / 荧光绿；Pro：胶片 / 海蓝 / 高对比。
    var isPro: Bool {
        switch self {
        case .light, .dark, .neon: false
        case .film, .ocean, .contrast: true
        }
    }

    var label: String {
        switch self {
        case .light: String(localized: "浅色")
        case .dark: String(localized: "深色")
        case .neon: String(localized: "荧光绿")
        case .film: String(localized: "胶片")
        case .ocean: String(localized: "海蓝")
        case .contrast: String(localized: "高对比")
        }
    }

    /// 满铺照片布局上的文字色。
    var textColorHex: String {
        switch self {
        case .light: "#1A1A1A"
        case .dark: "#FFFFFF"
        case .neon: "#EAFFF1"
        case .film: "#F0E6C8"
        case .ocean: "#EAF2FF"
        case .contrast: "#FFFFFF"
        }
    }

    /// 边框版色框 / 留白底色。
    var matteColorHex: String {
        switch self {
        case .light: "#F4F1EA"
        case .dark: "#161616"
        case .neon: "#2FAA63"
        case .film: "#E7DCC4"
        case .ocean: "#1D3C63"
        case .contrast: "#2A2A2A"
        }
    }

    /// 印在色框留白上的文字色（与 matte 底色对比）。
    var matteTextColorHex: String {
        switch self {
        case .light: "#1A1A1A"
        case .dark: "#F4F1EA"
        case .neon: "#08351D"
        case .film: "#3A2F18"
        case .ocean: "#EAF2FF"
        case .contrast: "#F4F1EA"
        }
    }

    /// 强调色：成绩类型标签 / 难度条等。默认沿用品牌绿。
    var accentColorHex: String {
        switch self {
        case .light: "#1C7A45"
        case .dark: "#5BE88F"
        case .neon: "#5BE88F"
        case .film: "#B8862F"
        case .ocean: "#7FB2FF"
        case .contrast: "#5BE88F"
        }
    }

    /// 「配色」tab 样块渐变（参考线框 .sc.* 取色）。
    var swatchColors: [Color] {
        switch self {
        case .light: [Color(hex: "#F4F1EA"), Color(hex: "#CFCABF")]
        case .dark: [Color(hex: "#3A3A3A"), Color(hex: "#111111")]
        case .neon: [Color(hex: "#3ECB7B"), Color(hex: "#177A44")]
        case .film: [Color(hex: "#CAA15A"), Color(hex: "#5A3D18")]
        case .ocean: [Color(hex: "#5A8FD1"), Color(hex: "#1D3C63")]
        case .contrast: [Color(hex: "#8A8A8A"), Color(hex: "#2A2A2A")]
        }
    }

    var textColor: Color { Color(hex: textColorHex) }
    var matteColor: Color { Color(hex: matteColorHex) }
    var matteTextColor: Color { Color(hex: matteTextColorHex) }
    var accentColor: Color { Color(hex: accentColorHex) }

    static func theme(for id: String) -> CardColorTheme {
        CardColorTheme(rawValue: id) ?? .dark
    }
}
