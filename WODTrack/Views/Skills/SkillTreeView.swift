import SwiftUI

struct SkillTreeView: View {
    var body: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()
            VStack(spacing: WTSpacing.lg) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.wtPrimary)
                Text("即将上线")
                    .font(WTFont.largeTitle)
                Text("技能树将在后续版本开放。")
                    .font(WTFont.body)
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
    }
}
