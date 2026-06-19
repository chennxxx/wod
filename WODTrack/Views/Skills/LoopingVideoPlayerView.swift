import AVFoundation
import SwiftUI

/// 动作详情页顶部的示范视频：静音、自动无缝循环播放。
///
/// 状态：加载中显示占位符 + 转圈；拿到本地文件后用 `AVQueuePlayer` + `AVPlayerLooper`
/// 无缝循环；下载失败 / 无视频时回退到静态占位符（与未上线动作保持一致观感）。
struct LoopingVideoPlayerView: View {
    let skillId: String

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper? // 须持有，否则循环会被释放
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            if let player {
                LoopingPlayerLayerView(player: player)
            } else if loadFailed {
                SkillVideoPlaceholder()
            } else {
                SkillVideoPlaceholder(state: .loading)
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        .task(id: skillId) { await load() }
        .onAppear { player?.play() }
        .onDisappear { player?.pause() }
    }

    private func load() async {
        player = nil
        looper = nil
        loadFailed = false

        guard let url = await MovementVideoCache.shared.localURL(for: skillId) else {
            loadFailed = true
            return
        }

        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        queue.isMuted = true
        looper = AVPlayerLooper(player: queue, templateItem: item)
        player = queue
        queue.play()
    }
}

// MARK: - 占位符（加载中 / 即将上线，复用同一视觉）

struct SkillVideoPlaceholder: View {
    enum State { case comingSoon, loading }
    var state: State = .comingSoon

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: WTRadius.lg)
                .fill(Color.wtSurface)

            if state == .loading {
                ProgressView()
                    .tint(Color.wtPrimary)
            } else {
                ZStack {
                    Circle()
                        .strokeBorder(Color.wtPrimary, lineWidth: 2)
                        .frame(width: 52, height: 52)
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.wtPrimary)
                        .offset(x: 2)
                }
            }

            VStack {
                Spacer()
                HStack {
                    Text(state == .loading ? "视频 · 加载中" : "视频 · 即将上线")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.wtTextSecondary)
                    Spacer()
                }
            }
            .padding(WTSpacing.md)
        }
        .frame(height: 200)
    }
}

// MARK: - AVPlayerLayer 包装（铺满圆角容器）

private struct LoopingPlayerLayerView: UIViewRepresentable {
    let player: AVQueuePlayer

    func makeUIView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerLayerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

final class PlayerLayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
