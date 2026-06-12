import PhotosUI
import SwiftUI

struct ProfileView: View {
    @Bindable var appState: AppState
    @Bindable var syncManager: CloudSyncManager

    @State private var showEditSheet = false
    @State private var showSignOutDialog = false
    @State private var navigateToSyncSettings = false
    @State private var legalDocument: LegalDocument?
    /// 从 iCloud 行进登录页的意图：登录成功后直接进同步详情页，不回「我的」根
    @State private var pendingSyncNavigation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WTSpacing.lg) {
                if appState.profile.isLoggedIn {
                    loggedInCard
                } else {
                    loginEntryCard
                }

                if showsInviteBanner {
                    syncInviteBanner
                }

                rowGroup(label: "数据") {
                    if appState.profile.isLoggedIn {
                        NavigationLink {
                            ICloudSyncSettingsView(appState: appState, syncManager: syncManager)
                        } label: {
                            ProfileRowLabel(
                                icon: "icloud",
                                iconTint: Color(hex: "#6EA2FF"),
                                title: "iCloud 同步",
                                value: syncManager.isSyncEnabled ? "已开启" : "未开启"
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        ProfileRow(
                            icon: "icloud",
                            iconTint: Color(hex: "#6EA2FF"),
                            title: "iCloud 同步",
                            value: "未登录"
                        ) {
                            pendingSyncNavigation = true
                            appState.showLoginPage = true
                        }
                    }
                    rowDivider
                    ProfileRow(icon: "arrow.down.circle", title: "本地数据备份") {
                        appState.showToast("即将推出")
                    }
                }

                rowGroup(label: "其他") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        ProfileRowLabel(icon: "info.circle", title: "关于我们")
                    }
                    .buttonStyle(.plain)
                    rowDivider
                    legalRow(.supportFAQ)
                    rowDivider
                    legalRow(.feedback)
                    rowDivider
                    legalRow(.accountDeletion)
                    rowDivider
                    legalRow(.userAgreement)
                    rowDivider
                    legalRow(.privacyPolicy)
                }

                if appState.profile.isLoggedIn {
                    signOutCard
                }
            }
            .padding(WTSpacing.md)
            .padding(.bottom, 60)
        }
        .background(Color.wtBackground)
        .navigationTitle("我的")
        .navigationDestination(isPresented: $navigateToSyncSettings) {
            ICloudSyncSettingsView(appState: appState, syncManager: syncManager)
        }
        .onChange(of: appState.profile.isLoggedIn) {
            if appState.profile.isLoggedIn, pendingSyncNavigation {
                pendingSyncNavigation = false
                navigateToSyncSettings = true
            } else if !appState.profile.isLoggedIn {
                pendingSyncNavigation = false
            }
        }
        .sheet(isPresented: $showEditSheet) {
            ProfileEditSheet(appState: appState)
                .preferredColorScheme(.dark)
        }
        .sheet(item: $legalDocument) { document in
            LegalDocumentSheet(document: document)
                .preferredColorScheme(.dark)
        }
        .alert("确定退出登录？", isPresented: $showSignOutDialog) {
            Button("退出登录", role: .destructive) {
                appState.signOut()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(syncManager.isSyncEnabled
                ? "iCloud 同步将暂停，本机与云端数据都保留，重新登录后可恢复同步。"
                : "退出后本机的训练数据仍会保留。")
        }
    }

    // MARK: - 顶部个人卡

    private var loginEntryCard: some View {
        Button {
            appState.showLoginPage = true
        } label: {
            HStack(spacing: WTSpacing.md - 2) {
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.wtPrimary)
                    .frame(width: 46, height: 46)
                    .background(Color.wtPrimary.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.wtPrimary.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 3) {
                    Text("登录迹录")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.wtTextPrimary)
                    Text("登录后可显示你的昵称和头像")
                        .font(WTFont.caption)
                        .foregroundStyle(Color.wtTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.wtTextDisabled)
            }
            .padding(WTSpacing.md + 2)
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private var loggedInCard: some View {
        HStack(spacing: WTSpacing.md) {
            Button {
                showEditSheet = true
            } label: {
                AvatarView(choice: appState.profile.avatar, size: 62)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "#07301C"))
                            .frame(width: 24, height: 24)
                            .background(Color.wtPrimary)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.wtSurface, lineWidth: 2.5))
                            .offset(x: 3, y: 3)
                    }
            }
            .buttonStyle(.plain)

            Text(appState.profile.nickname)
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(Color.wtTextPrimary)
                .lineLimit(1)

            Spacer()

            Button {
                showEditSheet = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.wtPrimary)
                    .padding(WTSpacing.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(WTSpacing.md + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - iCloud 同步邀请卡

    private var showsInviteBanner: Bool {
        appState.profile.isLoggedIn
            && !syncManager.isSyncEnabled
            && !syncManager.inviteBannerDismissedThisSession
    }

    private var syncInviteBanner: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md - 4) {
            HStack(alignment: .top, spacing: WTSpacing.md - 4) {
                Image(systemName: "icloud")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.wtPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.wtPrimary.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 11))

                VStack(alignment: .leading, spacing: 3) {
                    Text("开启 iCloud 同步")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.wtTextPrimary)
                    Text("让记录在你的 iPhone、iPad 间自动同步，换机也不丢。")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.wtTextSecondary)
                        .lineSpacing(2)
                }
            }

            HStack(spacing: WTSpacing.sm + 1) {
                Button {
                    navigateToSyncSettings = true
                } label: {
                    Text("立即开启")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "#07301C"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.wtPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    syncManager.inviteBannerDismissedThisSession = true
                } label: {
                    Text("以后再说")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.wtTextSecondary)
                        .padding(.horizontal, WTSpacing.md)
                        .frame(height: 38)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(15)
        .background(
            LinearGradient(
                colors: [Color.wtPrimary.opacity(0.16), Color.wtPrimary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: WTRadius.lg)
                .stroke(Color.wtPrimary.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
    }

    private var signOutCard: some View {
        Button {
            showSignOutDialog = true
        } label: {
            Text("退出登录")
                .font(WTFont.body)
                .foregroundStyle(Color.wtDanger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.wtSurface)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 行组

    @ViewBuilder
    private func rowGroup(label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm + 1) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.wtTextSecondary)
                .padding(.horizontal, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 50)
    }

    private func legalRow(_ document: LegalDocument) -> some View {
        ProfileRow(icon: document.icon, title: document.title) {
            legalDocument = document
        }
    }
}

// MARK: - 行组件

private struct ProfileRowLabel: View {
    let icon: String
    var iconTint: Color?
    let title: String
    var value: String?

    var body: some View {
        HStack(spacing: WTSpacing.md - 3) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(iconTint ?? Color.wtTextSecondary)
                .frame(width: 30, height: 30)
                .background((iconTint ?? Color.clear).opacity(iconTint == nil ? 0 : 0.16))
                .background(iconTint == nil ? Color.wtSurface2 : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 9))

            Text(title)
                .font(WTFont.body)
                .foregroundStyle(Color.wtTextPrimary)

            Spacer()

            if let value {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.wtTextSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.wtTextDisabled)
        }
        .padding(.horizontal, WTSpacing.md - 1)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct ProfileRow: View {
    let icon: String
    var iconTint: Color?
    let title: String
    var value: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ProfileRowLabel(icon: icon, iconTint: iconTint, title: title, value: value)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 头像

struct AvatarView: View {
    let choice: AvatarChoice
    let size: CGFloat

    var body: some View {
        Group {
            if choice == .custom, let image = AppState.loadCustomAvatar() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                // 自定义图丢失时回退默认头像图形
                Image(systemName: effectiveChoice.symbolName)
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(Color.wtPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.wtPrimary.opacity(0.12))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color.wtPrimary.opacity(0.45), lineWidth: 1.5)
        )
    }

    private var effectiveChoice: AvatarChoice {
        choice == .custom ? .default1 : choice
    }
}

// MARK: - 编辑资料

private struct ProfileEditSheet: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String = ""
    @State private var avatarChoice: AvatarChoice = .default1
    @State private var photoItem: PhotosPickerItem?
    @State private var pickedImageData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: WTSpacing.lg) {
            Text("编辑资料")
                .font(WTFont.title)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, WTSpacing.lg)

            VStack(alignment: .leading, spacing: WTSpacing.sm) {
                Text("头像")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)

                HStack(spacing: WTSpacing.md - 4) {
                    ForEach([AvatarChoice.default1, .default2], id: \.self) { option in
                        Button {
                            avatarChoice = option
                            pickedImageData = nil
                        } label: {
                            avatarOption(option, selected: avatarChoice == option)
                        }
                        .buttonStyle(.plain)
                    }

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        customAvatarOption
                    }

                    Spacer()
                }
            }

            WTTextField(title: "昵称", placeholder: "输入昵称", text: $nickname)

            HStack(spacing: WTSpacing.md) {
                WTButton(title: "取消", style: .ghost) {
                    dismiss()
                }
                WTButton(title: "保存", isEnabled: canSave) {
                    save()
                }
            }

            Spacer()
        }
        .padding(.horizontal, WTSpacing.lg)
        .background(Color.wtBackground)
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
        .onAppear {
            nickname = appState.profile.nickname
            avatarChoice = appState.profile.avatar
        }
        .onChange(of: photoItem) {
            Task {
                guard let data = try? await photoItem?.loadTransferable(type: Data.self) else { return }
                pickedImageData = data
                avatarChoice = .custom
            }
        }
    }

    private var canSave: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        appState.updateNickname(nickname)
        if let pickedImageData {
            appState.setCustomAvatar(imageData: pickedImageData)
        } else if avatarChoice != .custom {
            appState.updateAvatar(avatarChoice)
        }
        dismiss()
    }

    private func avatarOption(_ option: AvatarChoice, selected: Bool) -> some View {
        Image(systemName: option.symbolName)
            .font(.system(size: 20))
            .foregroundStyle(selected ? Color.wtPrimary : Color.wtTextSecondary)
            .frame(width: 52, height: 52)
            .background(selected ? Color.wtPrimary.opacity(0.12) : Color.wtSurface2)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(selected ? Color.wtPrimary : Color.white.opacity(0.08), lineWidth: 1.5)
            )
    }

    private var customAvatarOption: some View {
        Group {
            if let pickedImageData, let image = UIImage(data: pickedImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if avatarChoice == .custom, let image = AppState.loadCustomAvatar() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.wtPrimary)
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(
                    avatarChoice == .custom ? Color.wtPrimary : Color.wtPrimary.opacity(0.6),
                    style: StrokeStyle(lineWidth: 1.5, dash: avatarChoice == .custom ? [] : [4, 3])
                )
        )
    }
}
