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
                case .editorialTop:
                    editorialTopLayout(proxy: proxy)
                case .rightOverlayMono:
                    rightOverlayMonoLayout(proxy: proxy)
                case .bottomCardLight:
                    bottomCardLightLayout(proxy: proxy)
                case .heroTitle:
                    heroTitleLayout(proxy: proxy)
                case .dataDashboard:
                    dataDashboardLayout(proxy: proxy)
                case .retroFilm:
                    retroFilmLayout(proxy: proxy)
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
        case .light:
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.38)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .grain:
            ZStack {
                Color.black.opacity(0.3)
                LinearGradient(
                    colors: [Color(red: 0.25, green: 0.18, blue: 0.08).opacity(0.55), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    // MARK: - Layouts

    private func bottomCardLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 6)

        return anchoredPanel(verticalMargin: verticalMargin, proxy: proxy) {
            VStack(alignment: panelTextAlignment, spacing: 10) {
                contentLines(fontSize: textSize, lineSpacing: lineSpacing, weight: .bold, fillWidth: false)
                dateLine(accented: false)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.55))
            )
        }
    }

    private func bottomCardLightLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 6)

        return anchoredPanel(verticalMargin: verticalMargin, proxy: proxy) {
            VStack(alignment: panelTextAlignment, spacing: 10) {
                contentLines(fontSize: textSize, lineSpacing: lineSpacing, weight: .bold, fillWidth: false)
                dateLine(accented: false)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.9))
            )
        }
    }

    private func heroTitleLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let heroSize = min(CGFloat(record.textLayout.fontSize) * 2.2, 58)
        let subSize = CGFloat(record.textLayout.fontSize) * 0.85
        let firstLine = record.wodContent.first ?? ""
        let remainingLines = Array(record.wodContent.dropFirst())

        return VStack(alignment: .leading, spacing: 12) {
            Text(firstLine.uppercased())
                .font(font(for: heroSize, weight: .black))
                .foregroundStyle(textColor)
                .shadow(color: .black.opacity(0.75), radius: 8, x: 0, y: 3)
                .lineLimit(2)
                .minimumScaleFactor(0.45)

            if !remainingLines.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(remainingLines, id: \.self) { line in
                        Text(line)
                            .font(font(for: subSize, weight: .medium))
                            .foregroundStyle(textColor.opacity(0.8))
                            .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }

            dateLine(accented: false)
                .foregroundStyle(textColor.opacity(0.65))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, verticalMargin)
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: leadingCardAlignment)
    }

    private func dataDashboardLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 6)

        return anchoredPanel(verticalMargin: verticalMargin, proxy: proxy) {
            VStack(alignment: panelTextAlignment, spacing: 10) {
                Text(record.wodDate.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(textColor.opacity(0.55))

                contentLines(fontSize: textSize, lineSpacing: lineSpacing, weight: .semibold, fillWidth: false)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(textColor.opacity(0.22), lineWidth: 1)
                    )
            )
        }
    }

    private func retroFilmLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 8)

        return ZStack {
            Rectangle()
                .strokeBorder(Color(red: 0.94, green: 0.9, blue: 0.78).opacity(0.72), lineWidth: 14)

            VStack(alignment: .leading, spacing: 8) {
                contentLines(fontSize: textSize, lineSpacing: lineSpacing, weight: .regular, fillWidth: false)

                Text(record.wodDate.formatted(
                    .dateTime.year(.defaultDigits).month(.twoDigits).day(.twoDigits)
                ))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.9))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, verticalMargin + 16)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
    }

    private func editorialTopLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 6)

        return VStack(alignment: .leading, spacing: 14) {
            dateLine(accented: true)
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
        }
        .padding(.trailing, 24)
        .padding(.vertical, verticalMargin)
        .frame(width: proxy.size.width * 0.72, alignment: .trailing)
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: trailingCardAlignment)
    }

    // MARK: - Shared helpers

    private func contentLines(
        fontSize: CGFloat,
        lineSpacing: CGFloat,
        weight: Font.Weight,
        fillWidth: Bool = true
    ) -> some View {
        let isTrailing: Bool
        switch style.layout {
        case .rightOverlayMono:
            isTrailing = true
        case .bottomCard, .bottomCardLight, .dataDashboard:
            isTrailing = record.textLayout.horizontalPosition == .trailing
        default:
            isTrailing = false
        }
        return VStack(alignment: isTrailing ? .trailing : .leading, spacing: lineSpacing) {
            ForEach(record.wodContent, id: \.self) { line in
                Text(line)
                    .font(font(for: fontSize, weight: weight))
                    .multilineTextAlignment(isTrailing ? .trailing : .leading)
                    .foregroundStyle(textColor.opacity(record.textLayout.textOpacity))
                    .shadow(color: isTrailing ? .black.opacity(0.42) : .clear, radius: 3, x: 0, y: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .if(fillWidth) { $0.frame(maxWidth: .infinity, alignment: isTrailing ? .trailing : .leading) }
            }
        }
        .if(fillWidth) { $0.frame(maxWidth: .infinity, alignment: isTrailing ? .trailing : .leading) }
    }

    private func dateLine(accented: Bool) -> some View {
        Text(record.wodDate.formatted(.dateTime.year().month().day()))
            .font(accented ? .system(size: 14, weight: .bold, design: .monospaced) : WTFont.caption)
            .foregroundStyle(accented ? Color.wtPrimary : Color.wtTextSecondary)
    }

    /// HStack + Spacer 显式锚定面板到选定的左/右侧，保证两侧 padding 完全对称。
    @ViewBuilder private func anchoredPanel<Content: View>(
        verticalMargin: CGFloat,
        proxy: GeometryProxy,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 0) {
            if record.textLayout.horizontalPosition == .trailing {
                Spacer(minLength: 0)
            }
            content()
            if record.textLayout.horizontalPosition == .leading {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, verticalMargin)
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: cardVerticalAlignment)
    }

    private var panelTextAlignment: HorizontalAlignment {
        switch style.layout {
        case .bottomCard, .bottomCardLight, .dataDashboard:
            return record.textLayout.horizontalPosition == .trailing ? .trailing : .leading
        default:
            return .leading
        }
    }

    private var textColor: Color {
        Color(hex: record.textLayout.textColor)
    }

    private var cardVerticalAlignment: Alignment {
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
        return index == 0 ? line.uppercased() : line
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

// MARK: - View extension for conditional modifier
private extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
