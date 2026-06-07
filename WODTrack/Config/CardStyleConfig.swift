import SwiftUI

struct CardStyle: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let overlay: OverlayStyle
    let layout: LayoutStyle
    let isPro: Bool

    enum OverlayStyle: String, Hashable {
        case plain
        case glass
        case dark
        case soft
    }

    enum LayoutStyle: String, Hashable {
        case bottomCard
        case centerGlass
        case editorialTop
        case rightOverlayMono
    }
}

enum CardStyleConfig {
    static let freeStyles: [CardStyle] = [
        .init(
            id: "style_basic_dark",
            name: "夜训卡片",
            summary: "底部信息卡，适合内容多的 WOD",
            overlay: .dark,
            layout: .bottomCard,
            isPro: false
        ),
        .init(
            id: "style_glass_light",
            name: "玻璃海报",
            summary: "居中毛玻璃，适合单张训练照",
            overlay: .glass,
            layout: .centerGlass,
            isPro: false
        ),
        .init(
            id: "style_mono_overlay",
            name: "训练日志",
            summary: "直接压字到图片上，参考你发的样式",
            overlay: .soft,
            layout: .rightOverlayMono,
            isPro: false
        )
    ]

    static let proStyles: [CardStyle] = [
        .init(
            id: "style_plain_pro",
            name: "杂志封面",
            summary: "顶部排版，适合更强的海报感",
            overlay: .plain,
            layout: .editorialTop,
            isPro: true
        )
    ]

    static let all = freeStyles + proStyles

    static func style(for id: String) -> CardStyle {
        all.first(where: { $0.id == id }) ?? freeStyles[0]
    }
}
