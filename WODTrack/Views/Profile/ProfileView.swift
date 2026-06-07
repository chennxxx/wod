import Observation
import SwiftUI

struct ProfileView: View {
    @Bindable var appState: AppState

    var body: some View {
        List {
            Section {
                HStack(spacing: WTSpacing.md) {
                    Circle()
                        .fill(Color.wtSurface2)
                        .frame(width: 56, height: 56)
                        .overlay(Text(String(appState.profile.nickname.prefix(1))).font(WTFont.title))

                    VStack(alignment: .leading) {
                        Text(appState.profile.nickname)
                            .font(WTFont.bodyBold)
                        Text(appState.profile.isLoggedIn ? "已登录" : "未登录")
                            .font(WTFont.caption)
                            .foregroundStyle(Color.wtTextSecondary)
                    }
                }
            }

            Section("账户") {
                if appState.profile.isLoggedIn {
                    Text("订阅状态：\(appState.profile.subscriptionStatus.rawValue)")
                } else {
                    Button("微信登录") {
                        appState.showLoginPrompt = true
                    }
                    .foregroundStyle(Color.wtWechatGreen)
                }
            }

            Section("记录") {
                NavigationLink("历史记录") {
                    HistoryListView()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.wtBackground)
        .navigationTitle("我的")
        .sheet(isPresented: $appState.showLoginPrompt) {
            LoginPromptSheet(appState: appState)
        }
    }
}

struct LoginPromptSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: WTSpacing.lg) {
            Text("登录后可同步记录")
                .font(WTFont.title)
            Text("未登录也可以完成拍照、OCR、生成与保存。")
                .font(WTFont.body)
                .foregroundStyle(Color.wtTextSecondary)
                .multilineTextAlignment(.center)

            WTButton(title: "微信登录") {
                appState.profile.isLoggedIn = true
                dismiss()
            }

            WTButton(title: "暂不", style: .ghost) {
                dismiss()
            }
        }
        .padding(WTSpacing.xl)
        .presentationDetents([.medium])
        .background(Color.wtBackground)
    }
}
