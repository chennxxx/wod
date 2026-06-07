import SwiftUI

struct CardView: View {
    let record: WODRecord
    let style: CardStyle
    let isPro: Bool
    var checkinImages: [UIImage] = []

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer
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

                if !isPro {
                    watermark
                }
            }
            .clipped()
        }
    }

    @ViewBuilder private var backgroundLayer: some View {
        if checkinImages.isEmpty {
            LinearGradient(colors: [Color.wtSurface2, Color.black], startPoint: .top, endPoint: .bottom)
        } else if checkinImages.count == 1, let image = checkinImages.first {
            imageBackground(image: image)
        } else {
            // 多张图片：始终使用 fill 模式，上下各占一半
            VStack(spacing: 0) {
                if let first = checkinImages.first {
                    Image(uiImage: first)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
                if checkinImages.count > 1 {
                    Image(uiImage: checkinImages[1])
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
            }
        }
    }

    /// 单张图片背景：根据 imageDisplayMode 决定渲染方式
    @ViewBuilder private func imageBackground(image: UIImage) -> some View {
        switch record.textLayout.imageDisplayMode {
        case .fill:
            // 原行为：铺满整个卡片，超出部分裁切
            Image(uiImage: image)
                .resizable()
                .scaledToFill()

        case .fit:
            // 完整显示：模糊背景 + 居中原图，横版/竖版照片都能完整呈现
            ZStack {
                // 底层：放大版模糊图，填满背景
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 28, opaque: true)
                    .overlay(Color.black.opacity(0.35))

                // 上层：原图完整居中
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
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
            LinearGradient(
                colors: [Color.black.opacity(0.04), Color.black.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func bottomCardLayout(proxy: GeometryProxy) -> some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                metaChips(darkDifficulty: true)
                contentLines(weight: .bold)
                dateLine(accented: false)
            }
            .padding(16)
            .frame(width: proxy.size.width - 48, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.55))
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
    }

    private func centerGlassLayout(proxy: GeometryProxy) -> some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                metaChips(darkDifficulty: false)
                contentLines(weight: .semibold)
                dateLine(accented: false)
            }
            .padding(20)
            .frame(width: proxy.size.width - 56, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private func editorialTopLayout(proxy: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            dateLine(accented: true)
            metaChips(darkDifficulty: false)
            contentLines(weight: .bold)
        }
        .padding(.horizontal, 26)
        .padding(.top, 36)
        .frame(width: proxy.size.width - 52, height: proxy.size.height, alignment: .topLeading)
    }

    private func rightOverlayMonoLayout(proxy: GeometryProxy) -> some View {
        VStack(alignment: .trailing, spacing: 14) {
            Text(record.wodDate.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .textCase(.uppercase)
                .foregroundStyle(textColor)
                .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 2)

            VStack(alignment: .trailing, spacing: 8) {
                ForEach(Array(record.wodContent.enumerated()), id: \.offset) { index, line in
                    Text(formattedMonoLine(line, index: index))
                        .font(.system(size: max(CGFloat(record.textLayout.fontSize), 13), weight: index == 0 ? .semibold : .regular, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(textColor.opacity(record.textLayout.textOpacity))
                        .shadow(color: .black.opacity(0.42), radius: 3, x: 0, y: 2)
                }
            }

            HStack(spacing: 8) {
                if let difficultyRating = record.difficultyRating {
                    Text("RPE \(difficultyRating)/5")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(textColor)
                        .shadow(color: .black.opacity(0.42), radius: 3, x: 0, y: 2)
                }

                Text(record.completionStatus == .completed ? "🏆 已完成" : "未完成")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(record.completionStatus == .completed ? Color.wtPrimary : textColor)
                    .shadow(color: .black.opacity(0.42), radius: 3, x: 0, y: 2)
            }
        }
        .padding(.top, 42)
        .padding(.trailing, 24)
        .frame(width: proxy.size.width * 0.58, height: proxy.size.height, alignment: .topTrailing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
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

    private func contentLines(weight: Font.Weight) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(record.wodContent, id: \.self) { line in
                Text(line)
                    .font(font(for: CGFloat(record.textLayout.fontSize), weight: weight))
                    .multilineTextAlignment(style.layout == .rightOverlayMono ? .trailing : .leading)
                    .foregroundStyle(textColor.opacity(record.textLayout.textOpacity))
                    .shadow(color: style.layout == .rightOverlayMono ? .black.opacity(0.42) : .clear, radius: 3, x: 0, y: 2)
                    .frame(maxWidth: .infinity, alignment: style.layout == .rightOverlayMono ? .trailing : .leading)
                    .fixedSize(horizontal: false, vertical: true)
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

    private func formattedMonoLine(_ line: String, index: Int) -> String {
        guard style.layout == .rightOverlayMono else { return line }
        if index == 0 {
            return line.uppercased()
        }
        return line
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
