import SwiftUI

/// 彩蛋：训练时刻缩略图从屏幕顶部自由落体、触底弹起后散落堆叠，停留几秒后自动淡出。
/// 触发方式见 ContentView（记录 tab 连点 5 次）。纯娱乐，不影响任何数据。
struct PhotoDropEasterEggView: View {
    let records: [WODRecord]
    let onFinished: () -> Void

    /// 数量保护：太多缩略图渲染压力大，取前若干条已足够铺满。
    private static let maxCards = 80
    static let cardWidth: CGFloat = 90
    static let cardHeight: CGFloat = 120
    /// 每张卡片的错峰下落间隔（秒）。
    static let stagger: Double = 0.07
    /// 堆叠完成后停留时长（秒）。
    private static let lingerAfterLast: Double = 2.5

    @State private var visible = true

    private var cards: [WODRecord] {
        Array(records.prefix(Self.maxCards))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 半透明遮罩：压暗但仍能看到底下的记录页
                Color.black.opacity(0.75).ignoresSafeArea()

                ForEach(Array(cards.enumerated()), id: \.element.id) { index, record in
                    FallingCard(record: record, size: geo.size, index: index)
                        .zIndex(Double(index))
                }
            }
            .opacity(visible ? 1 : 0)
            .onAppear { scheduleDismiss(count: cards.count) }
        }
        .presentationBackground(.clear)
    }

    private func scheduleDismiss(count: Int) {
        let total = Double(count) * Self.stagger + Self.lingerAfterLast
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(total))
            withAnimation(.easeOut(duration: 0.4)) { visible = false }
            try? await Task.sleep(for: .milliseconds(420))
            onFinished()
        }
    }
}

/// 单张掉落卡：自由落体 → 触底弹起 → 二次小弹 → 落定，伴随翻转。
private struct FallingCard: View {
    let record: WODRecord
    let size: CGSize
    let index: Int

    @State private var play = false

    struct DropState {
        var y: CGFloat
        var angle: Double
    }

    var body: some View {
        let w = PhotoDropEasterEggView.cardWidth
        let h = PhotoDropEasterEggView.cardHeight
        let delay = Double(index) * PhotoDropEasterEggView.stagger

        // 终点（基于 index 的确定性、充分打散的伪随机）
        let targetX = size.width * 0.06 + rand(7) * size.width * 0.88
        let floorY = size.height - h / 2 - 40 - rand(19) * 170      // 底部 40~210 区间散开
        let startY = -h - rand(11) * 120                            // 出场高度也错落
        let startAngle = rand(41) * 50 - 25                         // 出场角度 ±25°
        let finalAngle = rand(31) * 60 - 30                         // 落定角度 ±30°
        let wobble = rand(23) * 18 - 9                              // 弹起摇摆 ±9°
        let fall = 0.45 + rand(53) * 0.3                            // 下落时长 0.45~0.75s
        let bounce = 55 + rand(67) * 95                             // 首次弹起高度 55~150pt

        card(w: w, h: h)
            .keyframeAnimator(
                initialValue: DropState(y: startY, angle: startAngle),
                trigger: play
            ) { view, state in
                view
                    .rotationEffect(.degrees(state.angle))
                    .position(x: targetX, y: state.y)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    LinearKeyframe(startY, duration: delay)               // 错峰：先在屏外等待
                    CubicKeyframe(floorY, duration: fall)                 // 自由落体加速触底
                    CubicKeyframe(floorY - bounce, duration: 0.24)        // 弹起
                    CubicKeyframe(floorY, duration: 0.20)                 // 落回
                    CubicKeyframe(floorY - bounce * 0.32, duration: 0.15) // 二次小弹
                    CubicKeyframe(floorY, duration: 0.13)                 // 落定
                }
                KeyframeTrack(\.angle) {
                    LinearKeyframe(startAngle, duration: delay)
                    CubicKeyframe(finalAngle, duration: fall)
                    CubicKeyframe(finalAngle + wobble, duration: 0.24)    // 触底带点摇摆
                    CubicKeyframe(finalAngle, duration: 0.48)
                }
            }
            .onAppear { play = true }
    }

    private func card(w: CGFloat, h: CGFloat) -> some View {
        HistoryThumbnail(record: record)
            .frame(width: w, height: h)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: WTRadius.md)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
    }

    /// 0...1 的确定性伪随机：整数 hash + 位混合，避免顺序 index 产生线性等差。
    private func rand(_ salt: Int) -> CGFloat {
        var x = UInt32(truncatingIfNeeded: index &* 73856093 ^ salt &* 19349663 &+ 0x9E3779B1)
        x ^= x >> 16; x &*= 0x7FEB352D
        x ^= x >> 15; x &*= 0x846CA68B
        x ^= x >> 16
        return CGFloat(x & 0xFFFF) / CGFloat(0xFFFF)
    }
}
