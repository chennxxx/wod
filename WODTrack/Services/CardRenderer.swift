import SwiftUI
import UIKit

enum CardRenderError: Error {
    case renderFailed
}

struct CardRenderer {
    static let exportSize = CGSize(width: 1080, height: 1350)
    static let exportAspectRatio: CGFloat = 1080.0 / 1350.0

    @MainActor
    static func render(record: WODRecord, style: CardStyle, isPro: Bool, checkinImages: [UIImage]) async throws -> UIImage {
        let cardView = CardView(record: record, style: style, isPro: isPro, checkinImages: checkinImages)
            .frame(width: exportSize.width, height: exportSize.height)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 1

        guard let image = renderer.uiImage else {
            throw CardRenderError.renderFailed
        }
        return image
    }
}
