import Foundation
import SwiftData
import SwiftUI

// CloudKit 约束：不得用 @Attribute(.unique)（唯一性由 SyncDedupService 应用层保证）；
// 非可选属性必须有声明处完全限定默认值（不能写前导点简写）。
@Model
final class WODRecord {
    var id: UUID = UUID()
    var userId: String?
    var createdAt: Date = Date.now
    var wodDate: Date = Date.now
    var wodContent: [String] = []
    var difficultyRating: Int?
    var checkinPhotoURLs: [String] = []
    var cardStyleId: String = "style_mono_overlay"
    var textLayout: TextLayout = TextLayout()
    var cardImagePath: String?
    var boxId: String?
    var wodName: String?
    var completionMinutes: Int?
    /// WOD 类型（WODType.rawValue：for_time / amrap / emom / max_load）
    var scoreType: String?
    /// 已格式化的成绩展示串，如 "04:32"、"135 reps"、"12 轮 +6 reps"、"100 kg"
    var scoreValue: String?
    /// 成绩标准：ScoreScaling.rawValue（rx / sc），nil 表示未标记
    var scoreScaling: String?
    /// 自由备注
    var note: String?
    /// 卡片上已开启的内容模块（CardModule.rawValue 集合）。非可选，CloudKit 增量字段。
    var enabledModules: [String] = ["date", "score", "difficulty", "wodContent"]
    /// 配色主题（CardColorTheme.rawValue）。决定文字色 + 卡底/留白色 + 强调色。
    /// 顶层非可选 + 默认值 → SwiftData 轻量迁移安全（同 enabledModules）；不放进 TextLayout 内，
    /// 否则会被展开成 WODRecord 的复合属性、缺省值不被迁移识别而报 134110。
    var colorThemeId: String = "dark"
    /// 合成卡片图字节，随 iCloud 同步；本地读取仍优先走 cardImagePath 文件
    @Attribute(.externalStorage) var cardImageData: Data?

    init(wodDate: Date = .now) {
        self.id = UUID()
        self.userId = nil
        self.createdAt = .now
        self.wodDate = wodDate
        self.wodContent = []
        self.difficultyRating = nil
        self.checkinPhotoURLs = []
        self.cardStyleId = "style_mono_overlay"
        self.textLayout = TextLayout()
        self.cardImagePath = nil
        self.boxId = nil
        self.wodName = nil
        self.completionMinutes = nil
        self.scoreType = nil
        self.scoreValue = nil
        self.scoreScaling = nil
        self.note = nil
        self.enabledModules = ["date", "score", "difficulty", "wodContent"]
        self.colorThemeId = "dark"
    }
}

/// 训练强度（4 级抽象，对应 RPE 每 25% 一档）。底层复用 WODRecord.difficultyRating 存 1–4。
enum DifficultyLevel: Int, CaseIterable, Identifiable {
    case easy = 1
    case moderate = 2
    case hard = 3
    case challenge = 4

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .easy: "轻松"
        case .moderate: "适中"
        case .hard: "困难"
        case .challenge: "挑战"
        }
    }

    var emoji: String {
        switch self {
        case .easy: "😌"
        case .moderate: "🙂"
        case .hard: "😤"
        case .challenge: "🔥"
        }
    }

    /// 强度配色（同时作为技能难度 L1–L5 的统一配色来源，见 `SkillTier.color`）。
    var color: Color {
        switch self {
        case .easy: Color(red: 0.30, green: 0.74, blue: 0.46)
        case .moderate: Color(red: 0.27, green: 0.62, blue: 0.86)
        case .hard: Color(red: 0.93, green: 0.60, blue: 0.20)
        case .challenge: Color(red: 0.90, green: 0.33, blue: 0.30)
        }
    }

    /// 大致对应的 RPE 区间文案
    var rpeHint: String {
        switch self {
        case .easy: "RPE 1–3"
        case .moderate: "RPE 4–5"
        case .hard: "RPE 6–8"
        case .challenge: "RPE 9–10"
        }
    }

    /// 把任意已存值（含历史 1–5 星）映射到 4 级展示。
    static func from(stored rating: Int) -> DifficultyLevel {
        switch rating {
        case ..<2: return .easy
        case 2: return .moderate
        case 3: return .hard
        default: return .challenge
        }
    }
}

/// 成绩标准：RX（标准）/ SC（降级）。未标记用 nil 表示。
enum ScoreScaling: String, CaseIterable, Identifiable {
    case rx
    case sc

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rx: "RX"
        case .sc: "SC"
        }
    }
}

enum WODType: String, Codable, CaseIterable, Identifiable {
    case forTime = "for_time"
    case amrap = "amrap"
    case emom = "emom"
    case maxLoad = "max_load"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .forTime: "For Time"
        case .amrap: "AMRAP"
        case .emom: "EMOM"
        case .maxLoad: "Max Load"
        case .other: "其他"
        }
    }

    var scorePlaceholder: String {
        switch self {
        case .forTime: "MM:SS，例如 04:32"
        case .amrap: "例如 18 rounds + 7 reps"
        case .emom: "完成 / 第 X 组未完成"
        case .maxLoad: "例如 100 kg"
        case .other: "自由填写成绩"
        }
    }
}

struct TextLayout: Codable {
    var verticalPosition: VerticalPosition = .bottom
    var horizontalPosition: HorizontalPosition = .leading
    var fontSize: Double = 16
    var textColor: String = "#FFFFFF"
    var textOpacity: Double = 1
    var fontPreset: FontPreset = .display
    /// 背景图片显示方式：fill = 填充裁切（原行为），fit = 完整显示 + 模糊背景
    var imageDisplayMode: ImageDisplayMode = .fit

    init(
        verticalPosition: VerticalPosition = .bottom,
        horizontalPosition: HorizontalPosition = .leading,
        fontSize: Double = 16,
        textColor: String = "#FFFFFF",
        textOpacity: Double = 1,
        fontPreset: FontPreset = .display,
        imageDisplayMode: ImageDisplayMode = .fit
    ) {
        self.verticalPosition = verticalPosition
        self.horizontalPosition = horizontalPosition
        self.fontSize = fontSize
        self.textColor = textColor
        self.textOpacity = textOpacity
        self.fontPreset = fontPreset
        self.imageDisplayMode = imageDisplayMode
    }

    enum CodingKeys: String, CodingKey {
        case verticalPosition
        case horizontalPosition
        case fontSize
        case textColor
        case textOpacity
        case fontPreset
        case imageDisplayMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        verticalPosition = try container.decodeIfPresent(VerticalPosition.self, forKey: .verticalPosition) ?? .bottom
        horizontalPosition = try container.decodeIfPresent(HorizontalPosition.self, forKey: .horizontalPosition) ?? .leading
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? 16
        textColor = try container.decodeIfPresent(String.self, forKey: .textColor) ?? "#FFFFFF"
        textOpacity = try container.decodeIfPresent(Double.self, forKey: .textOpacity) ?? 1
        fontPreset = try container.decodeIfPresent(FontPreset.self, forKey: .fontPreset) ?? .display
        imageDisplayMode = try container.decodeIfPresent(ImageDisplayMode.self, forKey: .imageDisplayMode) ?? .fit
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(verticalPosition, forKey: .verticalPosition)
        try container.encode(horizontalPosition, forKey: .horizontalPosition)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(textColor, forKey: .textColor)
        try container.encode(textOpacity, forKey: .textOpacity)
        try container.encode(fontPreset, forKey: .fontPreset)
        try container.encode(imageDisplayMode, forKey: .imageDisplayMode)
    }

    /// 背景图片显示模式
    enum ImageDisplayMode: String, Codable, CaseIterable, Identifiable {
        /// 照片铺满整个卡片（填充裁切）
        case fill
        /// 照片完整居中，边缘用模糊背景补足
        case fit

        var id: String { rawValue }

        var label: String {
            switch self {
            case .fill: "填充裁切"
            case .fit: "完整显示"
            }
        }

        var icon: String {
            switch self {
            case .fill: "arrow.up.left.and.arrow.down.right"
            case .fit: "photo.fill"
            }
        }

        var description: String {
            switch self {
            case .fill: "照片铺满画布，边缘自动裁切"
            case .fit: "完整保留照片，边缘用模糊填充"
            }
        }
    }

    enum HorizontalPosition: String, Codable, CaseIterable, Identifiable {
        case leading
        case trailing

        var id: String { rawValue }

        var label: String {
            switch self {
            case .leading: "左侧"
            case .trailing: "右侧"
            }
        }

        var icon: String {
            switch self {
            case .leading: "text.alignleft"
            case .trailing: "text.alignright"
            }
        }
    }

    enum VerticalPosition: String, Codable, CaseIterable, Identifiable {
        case top
        case center
        case bottom

        var id: String { rawValue }

        var label: String {
            switch self {
            case .top: "顶部"
            case .center: "居中"
            case .bottom: "底部"
            }
        }
    }

    enum FontPreset: String, Codable, CaseIterable, Identifiable {
        case display
        case rounded
        case serif
        case mono

        var id: String { rawValue }

        var label: String {
            switch self {
            case .display: "标准"
            case .rounded: "圆角"
            case .serif: "衬线"
            case .mono: "等宽"
            }
        }
    }
}
