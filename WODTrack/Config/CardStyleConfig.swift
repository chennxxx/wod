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
        case dark
        case soft
        case light
        case grain
    }

    enum LayoutStyle: String, Hashable {
        case bottomCard
        case editorialTop
        case rightOverlayMono
        case bottomCardLight
        case heroTitle
        case dataDashboard
        case retroFilm
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
            id: "style_mono_overlay",
            name: "训练日志",
            summary: "直接压字到图片上，参考你发的样式",
            overlay: .soft,
            layout: .rightOverlayMono,
            isPro: false
        ),
        .init(
            id: "style_minimal_white",
            name: "极简白底",
            summary: "浅色信息卡，适合日间分享",
            overlay: .light,
            layout: .bottomCardLight,
            isPro: false
        ),
        .init(
            id: "style_hero_title",
            name: "大字报",
            summary: "超大标题字体，视觉冲击力强",
            overlay: .dark,
            layout: .heroTitle,
            isPro: false
        ),
        .init(
            id: "style_data_dashboard",
            name: "数据仪表盘",
            summary: "强调训练数字，数据卡片风格",
            overlay: .dark,
            layout: .dataDashboard,
            isPro: false
        ),
        .init(
            id: "style_retro_film",
            name: "胶片复古",
            summary: "胶片颗粒感，带日期戳，怀旧拍摄风",
            overlay: .grain,
            layout: .retroFilm,
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
        all.first(where: { $0.id == id }) ?? freeStyles.first(where: { $0.id == "style_mono_overlay" }) ?? freeStyles[0]
    }
}
