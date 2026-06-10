import Foundation
import SwiftData

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
