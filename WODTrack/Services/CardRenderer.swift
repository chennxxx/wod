import SwiftUI
import UIKit

enum CardRenderError: Error {
    case renderFailed
}

struct CardRenderer {
    static let fallbackPixelSize = CGSize(width: 1080, height: 1350)
    static let fallbackAspectRatio: CGFloat = 1080.0 / 1350.0
    private static let logicalWidth: CGFloat = 360

    @MainActor
    static func render(record: WODRecord, style: CardStyle, isPro: Bool, checkinImages: [UIImage]) async throws -> UIImage {
        let pixelSize = outputPixelSize(for: checkinImages)
        let logicalSize = logicalCanvasSize(for: checkinImages)
        let renderScale = pixelSize.width / logicalSize.width
        let cardView = CardView(record: record, style: style, isPro: isPro, checkinImages: checkinImages)
            .frame(width: logicalSize.width, height: logicalSize.height)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = renderScale

        guard let image = renderer.uiImage else {
            throw CardRenderError.renderFailed
        }
        return image
    }

    static func aspectRatio(for images: [UIImage]) -> CGFloat {
        let size = outputPixelSize(for: images)
        return size.width / max(size.height, 1)
    }

    /// `extraLineEquivalents`：除 WOD 文本行外，已开启的内容模块（成绩 / 难度 / 完成时间）
    /// 折算成的「等效文本行数」，让自适应字号把这些块的高度也算进去，避免文字超出图片。
    static func suggestedFontSize(
        for lines: [String],
        images: [UIImage],
        style: CardStyle,
        preferredSize: Double,
        extraLineEquivalents: Double = 0
    ) -> Double {
        let logicalSize = logicalCanvasSize(for: images)
        let verticalMargin = min(36, max(8, logicalSize.height * 0.08))
        let lineCount = CGFloat(max(lines.count, 1)) + CGFloat(max(0, extraLineEquivalents))
        let availableHeight = max(
            logicalSize.height - chromeHeight(for: style.layout) - verticalMargins(for: style.layout, verticalMargin: verticalMargin),
            24
        )
        let candidate = availableHeight / max(lineCount * 1.16, 1)
        return Double(min(CGFloat(preferredSize), max(5, candidate)))
    }

    static func outputPixelSize(for images: [UIImage]) -> CGSize {
        guard let firstImage = images.first else {
            return fallbackPixelSize
        }
        let size = pixelSize(for: firstImage)
        return size.width > 0 && size.height > 0 ? size : fallbackPixelSize
    }

    private static func logicalCanvasSize(for images: [UIImage]) -> CGSize {
        let pixelSize = outputPixelSize(for: images)
        return CGSize(width: logicalWidth, height: logicalWidth / max(pixelSize.width / max(pixelSize.height, 1), 0.01))
    }

    private static func chromeHeight(for layout: CardStyle.LayoutStyle) -> CGFloat {
        switch layout {
        case .bottomCard, .bottomCardLight:
            return 54
        case .editorialTop:
            return 50
        case .rightOverlayMono:
            return 82
        case .heroTitle:
            return 64
        case .dataDashboard:
            return 100
        case .retroFilm:
            return 32
        case .framedBottom, .framedPolaroid:
            // 文字压在照片上（非留白），可用区≈整张照片；边框只占少量高度
            return 84
        }
    }

    private static func verticalMargins(for layout: CardStyle.LayoutStyle, verticalMargin: CGFloat) -> CGFloat {
        switch layout {
        case .bottomCard, .bottomCardLight:
            return 32 + verticalMargin * 2
        case .editorialTop, .rightOverlayMono, .heroTitle, .dataDashboard, .retroFilm, .framedBottom, .framedPolaroid:
            return verticalMargin * 2
        }
    }

    private static func pixelSize(for image: UIImage) -> CGSize {
        CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    }
}
