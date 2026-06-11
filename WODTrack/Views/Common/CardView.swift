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
            moduleStack(textSize: textSize, lineSpacing: lineSpacing, alignment: horizontalTextAlignment)
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
            moduleStack(textSize: textSize, lineSpacing: lineSpacing, alignment: horizontalTextAlignment)
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
        let modules = activeModules

        return VStack(alignment: horizontalTextAlignment, spacing: 12) {
            if modules.contains(.wodContent) {
                Text(firstLine.uppercased())
                    .font(font(for: heroSize, weight: .black))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(textAlignmentValue)
                    .shadow(color: .black.opacity(0.75), radius: 8, x: 0, y: 3)
                    .lineLimit(2)
                    .minimumScaleFactor(0.45)

                if !remainingLines.isEmpty {
                    VStack(alignment: horizontalTextAlignment, spacing: 4) {
                        ForEach(remainingLines, id: \.self) { line in
                            Text(line)
                                .font(font(for: subSize, weight: .medium))
                                .foregroundStyle(textColor.opacity(0.8))
                                .multilineTextAlignment(textAlignmentValue)
                                .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
            }

            if modules.contains(.score) {
                scoreBlockView(size: CGFloat(record.textLayout.fontSize), alignment: horizontalTextAlignment)
            }
            if modules.contains(.difficulty) {
                difficultyBlockView(size: CGFloat(record.textLayout.fontSize), alignment: horizontalTextAlignment)
            }
            if modules.contains(.note) {
                noteBlockView(size: CGFloat(record.textLayout.fontSize))
            }
            if modules.contains(.date) {
                dateLine(accented: false)
                    .foregroundStyle(textColor.opacity(0.65))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, verticalMargin)
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: cardAlignment)
    }

    private func dataDashboardLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 6)

        return anchoredPanel(verticalMargin: verticalMargin, proxy: proxy) {
            moduleStack(textSize: textSize, lineSpacing: lineSpacing, alignment: horizontalTextAlignment)
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

            VStack(alignment: horizontalTextAlignment, spacing: 8) {
                ForEach(activeModules.filter { $0 != .date }) { module in
                    switch module {
                    case .score:
                        scoreBlockView(size: textSize, alignment: horizontalTextAlignment)
                    case .wodContent:
                        contentLines(fontSize: textSize, lineSpacing: lineSpacing, weight: .regular, fillWidth: false)
                    default:
                        EmptyView()
                    }
                }

                if activeModules.contains(.date) {
                    Text(record.wodDate.formatted(
                        .dateTime.year(.defaultDigits).month(.twoDigits).day(.twoDigits)
                    ))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.9))
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, verticalMargin + 16)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: Alignment(horizontal: isTrailing ? .trailing : .leading, vertical: .bottom))
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
    }

    private func editorialTopLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 6)

        return moduleStack(textSize: textSize, lineSpacing: lineSpacing, alignment: horizontalTextAlignment, dateAccented: true)
            .padding(.horizontal, 26)
            .padding(.vertical, verticalMargin)
            .frame(width: proxy.size.width - 52, alignment: Alignment(horizontal: horizontalTextAlignment, vertical: .center))
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: cardAlignment)
    }

    private func rightOverlayMonoLayout(proxy: GeometryProxy) -> some View {
        let verticalMargin = overlayVerticalMargin(proxy: proxy)
        let textSize = CGFloat(record.textLayout.fontSize)
        let lineSpacing = adaptiveLineSpacing(for: textSize, defaultSpacing: 8)

        return VStack(alignment: horizontalTextAlignment, spacing: 14) {
            ForEach(activeModules) { module in
                switch module {
                case .date:
                    Text(record.wodDate.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(font(for: min(16, textSize + 2), weight: .bold))
                        .textCase(.uppercase)
                        .foregroundStyle(textColor)
                        .shadow(color: .black.opacity(0.85), radius: 5, x: 0, y: 2)
                case .wodContent:
                    VStack(alignment: horizontalTextAlignment, spacing: lineSpacing) {
                        ForEach(Array(record.wodContent.enumerated()), id: \.offset) { index, line in
                            Text(formattedMonoLine(line, index: index))
                                .font(font(for: textSize, weight: index == 0 ? .semibold : .regular))
                                .multilineTextAlignment(textAlignmentValue)
                                .foregroundStyle(textColor.opacity(record.textLayout.textOpacity))
                                .shadow(color: .black.opacity(0.9), radius: 5, x: 0, y: 2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                case .score:
                    scoreBlockView(size: textSize, alignment: horizontalTextAlignment)
                case .difficulty:
                    difficultyBlockView(size: textSize, alignment: horizontalTextAlignment)
                case .note:
                    noteBlockView(size: textSize)
                }
            }
        }
        .padding(isTrailing ? .trailing : .leading, 24)
        .padding(.vertical, verticalMargin)
        .frame(width: proxy.size.width * 0.72, alignment: Alignment(horizontal: horizontalTextAlignment, vertical: .center))
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: cardAlignment)
    }

    // MARK: - Shared helpers

    private func contentLines(
        fontSize: CGFloat,
        lineSpacing: CGFloat,
        weight: Font.Weight,
        fillWidth: Bool = true
    ) -> some View {
        let isTrailing = self.isTrailing
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

    // MARK: - 内容模块（成绩 / 难度 / 完成时间）

    /// 当前实际渲染的模块：已开启 ∩ 模板支持 ∩ 有数据，按 CardModule.allCases 固定顺序。
    private var activeModules: [CardModule] {
        CardModule.allCases.filter { module in
            record.enabledModules.contains(module.rawValue)
                && style.supportedModules.contains(module)
                && hasData(module)
        }
    }

    private func hasData(_ module: CardModule) -> Bool {
        switch module {
        case .date: return true
        case .score: return !(record.scoreValue ?? "").isEmpty
        case .difficulty: return record.difficultyRating != nil
        case .note: return !(record.note ?? "").isEmpty
        case .wodContent: return !record.wodContent.isEmpty
        }
    }

    /// 按 activeModules 固定顺序竖排各模块块；空则兜底渲染日期，避免空卡。
    @ViewBuilder private func moduleStack(
        textSize: CGFloat,
        lineSpacing: CGFloat,
        alignment: HorizontalAlignment,
        dateAccented: Bool = false
    ) -> some View {
        let modules = activeModules
        VStack(alignment: alignment, spacing: 9) {
            if modules.isEmpty {
                dateLine(accented: dateAccented)
            } else {
                ForEach(modules) { module in
                    moduleBlock(module, textSize: textSize, lineSpacing: lineSpacing, alignment: alignment, dateAccented: dateAccented)
                }
            }
        }
    }

    @ViewBuilder private func moduleBlock(
        _ module: CardModule,
        textSize: CGFloat,
        lineSpacing: CGFloat,
        alignment: HorizontalAlignment,
        dateAccented: Bool = false
    ) -> some View {
        switch module {
        case .date:
            dateLine(accented: dateAccented)
        case .score:
            scoreBlockView(size: textSize, alignment: alignment)
        case .difficulty:
            difficultyBlockView(size: textSize, alignment: alignment)
        case .note:
            noteBlockView(size: textSize)
        case .wodContent:
            contentLines(fontSize: textSize, lineSpacing: lineSpacing, weight: .bold, fillWidth: false)
        }
    }

    @ViewBuilder private func scoreBlockView(size: CGFloat, alignment: HorizontalAlignment) -> some View {
        if let value = record.scoreValue, !value.isEmpty {
            VStack(alignment: alignment, spacing: 2) {
                HStack(spacing: 6) {
                    if let typeName = scoreTypeLabel {
                        Text(typeName.uppercased())
                            .font(.system(size: max(9, size * 0.5), weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.wtPrimary)
                    }
                    if let scaling = scoreScalingLabel {
                        Text(scaling)
                            .font(.system(size: max(8, size * 0.42), weight: .heavy))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.wtPrimary.opacity(0.9))
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                }
                Text(value)
                    .font(.system(size: size * 1.55, weight: .black, design: .monospaced))
                    .foregroundStyle(textColor)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }

    @ViewBuilder private func difficultyBlockView(size: CGFloat, alignment: HorizontalAlignment) -> some View {
        if let rating = record.difficultyRating {
            let level = DifficultyLevel.from(stored: rating)
            HStack(spacing: 6) {
                HStack(spacing: 3) {
                    ForEach(1 ... 4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(index <= level.rawValue ? Color.wtPrimary : textColor.opacity(0.25))
                            .frame(width: max(8, size * 0.5), height: max(4, size * 0.28))
                    }
                }
                Text(level.label)
                    .font(font(for: size * 0.78, weight: .semibold))
                    .foregroundStyle(textColor.opacity(0.9))
            }
        }
    }

    @ViewBuilder private func noteBlockView(size: CGFloat) -> some View {
        if let note = record.note, !note.isEmpty {
            Text(note)
                .font(font(for: size * 0.82, weight: .regular))
                .italic()
                .foregroundStyle(textColor.opacity(0.82))
                .multilineTextAlignment(textAlignmentValue)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }

    private var scoreTypeLabel: String? {
        guard let raw = record.scoreType, let type = WODType(rawValue: raw), type != .other else { return nil }
        return type.displayName
    }

    private var scoreScalingLabel: String? {
        guard let raw = record.scoreScaling else { return nil }
        return ScoreScaling(rawValue: raw)?.label
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

    /// 左右位置：所有模板通用，跟随 textLayout.horizontalPosition。
    private var isTrailing: Bool { record.textLayout.horizontalPosition == .trailing }

    private var horizontalTextAlignment: HorizontalAlignment { isTrailing ? .trailing : .leading }

    private var textAlignmentValue: TextAlignment { isTrailing ? .trailing : .leading }

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

    /// 垂直 + 水平 合成的整卡锚点（非面板型布局用）。
    private var cardAlignment: Alignment {
        let horizontal: HorizontalAlignment = isTrailing ? .trailing : .leading
        switch record.textLayout.verticalPosition {
        case .top: return Alignment(horizontal: horizontal, vertical: .top)
        case .center: return Alignment(horizontal: horizontal, vertical: .center)
        case .bottom: return Alignment(horizontal: horizontal, vertical: .bottom)
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
