import SwiftUI

/// 卡片内容模块。卡片 = 背景（照片）+ 若干可开关的内容块。
/// `allCases` 的顺序即卡面固定渲染顺序（对齐线框 ACT3：日期 → 成绩 → 难度 → WOD 内容 → 完成时间）。
enum CardModule: String, CaseIterable, Identifiable {
    case date
    case score
    case difficulty
    case wodContent
    case note

    var id: String { rawValue }

    var label: String {
        switch self {
        case .date: String(localized: "日期")
        case .score: String(localized: "成绩")
        case .difficulty: String(localized: "难度")
        case .wodContent: String(localized: "WOD 内容")
        case .note: String(localized: "备注")
        }
    }

    var icon: String {
        switch self {
        case .date: "calendar"
        case .score: "trophy.fill"
        case .difficulty: "flame.fill"
        case .wodContent: "list.bullet"
        case .note: "text.quote"
        }
    }

    /// 默认开启的模块（线框「默认开 4 个」，完成时间默认关）。
    static let defaultEnabled: [CardModule] = [.date, .score, .difficulty, .wodContent]
    static let defaultEnabledRawValues: [String] = defaultEnabled.map(\.rawValue)
}

struct CardStyle: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let overlay: OverlayStyle
    let layout: LayoutStyle
    let isPro: Bool
    /// 该模板有版位的模块；其余模块在「模块」tab 中灰掉锁住、画布也不渲染。
    let supportedModules: Set<CardModule>

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
        /// 边框画布版（方向 C）：照片不满铺，装进有色画布，底部留白印数据。
        case framedBottom
        /// 拍立得：照片四周等宽留边 + 底部窄栏，经典宝丽来。
        case framedPolaroid
    }
}

enum CardStyleConfig {
    /// 面板型布局（bottomCard / bottomCardLight / dataDashboard）有完整版位，支持全部 5 个模块。
    private static let allModules: Set<CardModule> = Set(CardModule.allCases)

    static let freeStyles: [CardStyle] = [
        .init(
            id: "style_framed_bottom",
            name: String(localized: "边框留白"),
            summary: String(localized: "照片装进色框、四周留白，数据压在照片上"),
            overlay: .plain,
            layout: .framedBottom,
            isPro: false,
            supportedModules: [.date, .score, .difficulty, .wodContent]
        ),
        .init(
            id: "style_mono_overlay",
            name: String(localized: "训练日志"),
            summary: String(localized: "直接压字到图片上，参考你发的样式"),
            overlay: .soft,
            layout: .rightOverlayMono,
            isPro: false,
            supportedModules: allModules
        ),
        .init(
            id: "style_basic_dark",
            name: String(localized: "夜训卡片"),
            summary: String(localized: "底部信息卡，适合内容多的 WOD"),
            overlay: .dark,
            layout: .bottomCard,
            isPro: false,
            supportedModules: allModules
        ),
        .init(
            id: "style_minimal_white",
            name: String(localized: "极简白底"),
            summary: String(localized: "浅色信息卡，适合日间分享"),
            overlay: .light,
            layout: .bottomCardLight,
            isPro: false,
            supportedModules: allModules
        ),
        .init(
            id: "style_hero_title",
            name: String(localized: "大字报"),
            summary: String(localized: "超大标题字体，视觉冲击力强"),
            overlay: .dark,
            layout: .heroTitle,
            isPro: false,
            supportedModules: allModules
        ),
        .init(
            id: "style_data_dashboard",
            name: String(localized: "数据仪表盘"),
            summary: String(localized: "强调训练数字，数据卡片风格"),
            overlay: .dark,
            layout: .dataDashboard,
            isPro: false,
            supportedModules: allModules
        ),
        .init(
            id: "style_retro_film",
            name: String(localized: "胶片复古"),
            summary: String(localized: "胶片颗粒感，带日期戳，怀旧拍摄风"),
            overlay: .grain,
            layout: .retroFilm,
            isPro: false,
            supportedModules: [.date, .score, .wodContent]
        )
    ]

    static let proStyles: [CardStyle] = []

    static let all = freeStyles + proStyles

    static func style(for id: String) -> CardStyle {
        all.first(where: { $0.id == id }) ?? freeStyles.first(where: { $0.id == "style_mono_overlay" }) ?? freeStyles[0]
    }
}
