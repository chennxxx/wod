import SwiftUI

struct CardView: View {
    let record: WODRecord
    let style: CardStyle
    let isPro: Bool
    var checkinImages: [UIImage] = []

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer(proxy: proxy)
                    .overlay(backgroundOverlay)

                switch style.layout {
                case .bottomCard:
                    bottomCardLayout(proxy: proxy)
                case .centerGlass:
                    centerGlassLayout(proxy: proxy)
                case .editorialTop:
                    editorialTopLayout(proxy: proxy)
                case .rightOverlayMono:
                    rightOverlayMonoLayout(proxy: proxy)
                }


            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }

    @ViewBuilder private func backgroundLayer(proxy: GeometryProxy) -> some View {
        if checkinImages.isEmpty {
            LinearGradient(colors: [Color.wtSurface2, Color.black], startPoint: .top, endPoint: .bottom)
                .frame(width: proxy.size.width, height: proxy.size.height)
        } else if let image = checkinImages.first {
            imageBackground(image: image)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
    }

    @ViewBuilder private func imageBackground(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private var backgroundOverlay: some View {
        switch style.overlay {
        case .plain:
            Color.clear
        case .glass:
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.black.opacity(0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .dark:
            LinearGradient(
                colors: [Color.black.opacity(0.08), Color.black.opacity(0.52)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .soft:
            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.08), Color.black.opacity(0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.48)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }

    private func bottomCardLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 6)
        let panelWidth = overlayPanelWidth(proxy: proxy, horizontalInset: 48)

        return VStack(alignment: .leading, spacing: 10) {
            metaChips(darkDifficulty: true)
            contentLines(fontSize: textSize, lineSpacing: lineSpacing, weight: .bold)
            dateLine(accented: false)
        }
        .padding(16)
        .frame(width: panelWidth, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.55))
        )
        .padding(.horizontal, 24)
        .padding(.vertical, verticalMargin)
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: trailingCardAlignment)
    }

    private func centerGlassLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 6)
        let panelWidth = overlayPanelWidth(proxy: proxy, horizontalInset: 56)

        return VStack(alignment: .leading, spacing: 12) {
            metaChips(darkDifficulty: false)
            contentLines(fontSize: textSize, lineSpacing: lineSpacing, weight: .semibold)
            dateLine(accented: false)
        }
        .padding(20)
        .frame(width: panelWidth, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .padding(.horizontal, 28)
        .padding(.vertical, verticalMargin)
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: trailingCardAlignment)
    }

    private func editorialTopLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 6)

        return VStack(alignment: .leading, spacing: 14) {
            dateLine(accented: true)
            metaChips(darkDifficulty: false)
            contentLines(fontSize: textSize, lineSpacing: lineSpacing, weight: .bold)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, verticalMargin)
        .frame(width: proxy.size.width - 52, alignment: .leading)
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: leadingCardAlignment)
    }

    private func rightOverlayMonoLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 8)

        return VStack(alignment: .trailing, spacing: 14) {
            Text(record.wodDate.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(font(for: min(16, textSize + 2), weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(textColor)
                .shadow(color: .black.opacity(0.85), radius: 5, x: 0, y: 2)

            VStack(alignment: .trailing, spacing: lineSpacing) {
                ForEach(Array(record.wodContent.enumerated()), id: \.offset) { index, line in
                    Text(formattedMonoLine(line, index: index))
                        .font(font(for: textSize, weight: index == 0 ? .semibold : .regular))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(textColor.opacity(record.textLayout.textOpacity))
                        .shadow(color: .black.opacity(0.9), radius: 5, x: 0, y: 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

            HStack(spacing: 8) {
                if let difficultyRating = record.difficultyRating {
                    Text("RPE \(difficultyRating)/5")
                        .font(font(for: min(14, textSize + 1), weight: .semibold))
                        .foregroundStyle(textColor)
                        .shadow(color: .black.opacity(0.9), radius: 5, x: 0, y: 2)
                }

                Text(record.completionStatus == .completed ? "🏆 已完成" : "未完成")
                    .font(font(for: min(16, textSize + 2), weight: .bold))
                    .foregroundStyle(record.completionStatus == .completed ? Color.wtPrimary : textColor)
                    .shadow(color: .black.opacity(0.9), radius: 5, x: 0, y: 2)
            }
        }
        .padding(.trailing, 24)
        .padding(.vertical, verticalMargin)
        .frame(width: proxy.size.width * 0.72, alignment: .trailing)
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: trailingCardAlignment)
    }

    private func metaChips(darkDifficulty: Bool) -> some View {
        HStack(spacing: WTSpacing.sm) {
            Text(record.completionStatus.label)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.wtPrimary)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            if let difficultyRating = record.difficultyRating {
                Text("难度 \(difficultyRating)/5")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(darkDifficulty ? Color.black.opacity(0.4) : Color.white.opacity(0.16))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    private func contentLines(fontSize: CGFloat, lineSpacing: CGFloat, weight: Font.Weight) -> some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(record.wodContent, id: \.self) { line in
                Text(line)
                    .font(font(for: fontSize, weight: weight))
                    .multilineTextAlignment(style.layout == .rightOverlayMono ? .trailing : .leading)
                    .foregroundStyle(textColor.opacity(record.textLayout.textOpacity))
                    .shadow(color: style.layout == .rightOverlayMono ? .black.opacity(0.42) : .clear, radius: 3, x: 0, y: 2)
                    .frame(maxWidth: .infinity, alignment: style.layout == .rightOverlayMono ? .trailing : .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: style.layout == .rightOverlayMono ? .trailing : .leading)
    }

    private func dateLine(accented: Bool) -> some View {
        Text(record.wodDate.formatted(.dateTime.year().month().day()))
            .font(accented ? .system(size: 14, weight: .bold, design: .monospaced) : WTFont.caption)
            .foregroundStyle(accented ? Color.wtPrimary : Color.wtTextSecondary)
    }

    private var watermark: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("WODTrack")
                    .font(WTFont.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
            }
        }
    }

    private var textColor: Color {
        Color(hex: record.textLayout.textColor)
    }

    private var cardAlignment: Alignment {
        switch record.textLayout.verticalPosition {
        case .top: .top
        case .center: .center
        case .bottom: .bottom
        }
    }

    private var trailingCardAlignment: Alignment {
        switch record.textLayout.verticalPosition {
        case .top: .topTrailing
        case .center: .trailing
        case .bottom: .bottomTrailing
        }
    }

    private var leadingCardAlignment: Alignment {
        switch record.textLayout.verticalPosition {
        case .top: .topLeading
        case .center: .leading
        case .bottom: .bottomLeading
        }
    }

    private func formattedMonoLine(_ line: String, index: Int) -> String {
        guard style.layout == .rightOverlayMono else { return line }
        if index == 0 {
            return line.uppercased()
        }
        return line
    }

    private func adaptiveLineSpacing(for fontSize: CGFloat, defaultSpacing: CGFloat) -> CGFloat {
        min(defaultSpacing, max(0.5, fontSize * 0.24))
    }

    private func overlayVerticalMargin(proxy: GeometryProxy) -> CGFloat {
        min(36, max(8, proxy.size.height * 0.08))
    }

    private func overlayPanelWidth(proxy: GeometryProxy, horizontalInset: CGFloat) -> CGFloat {
        let maxWidth = max(proxy.size.width - horizontalInset, 1)
        guard proxy.size.width > proxy.size.height else {
            return maxWidth
        }
        return min(maxWidth, max(120, proxy.size.width * 0.5))
    }

    private func font(for size: CGFloat, weight: Font.Weight) -> Font {
        switch record.textLayout.fontPreset {
        case .display:
            return .system(size: size, weight: weight, design: .default)
        case .rounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .serif:
            return .system(size: size, weight: weight, design: .serif)
        case .mono:
            return .system(size: size, weight: weight, design: .monospaced)
        }
    }
}
