import AuthenticationServices
import Foundation
import Observation
import UIKit

@Observable
final class AppState {
    private enum DefaultsKey {
        static let nickname = "wt.nickname"
        static let avatarChoice = "wt.avatarChoice"
        static let lastLoginPromptDate = "wt.lastLoginPromptDate"
    }

    /// 保存记录后自动弹登录页的冷却期
    private static let loginPromptCooldown: TimeInterval = 7 * 24 * 3600

    private static let defaultNickname = "迹录用户"

    var profile: UserProfile
    var showLoginPage = false
    var toastMessage: String?
    /// 放在 AppState 而非 ContentView：iCloud 容器切换会整树重建，tab 位置需跨重建保留
    var selectedTab = 1

    @ObservationIgnored private var revokeObserver: NSObjectProtocol?

    init() {
        let defaults = UserDefaults.standard
        let appleUserID = KeychainHelper.readAppleUserID()
        let avatar = defaults.string(forKey: DefaultsKey.avatarChoice)
            .flatMap(AvatarChoice.init(rawValue:)) ?? .default1

        profile = UserProfile(
            userId: appleUserID ?? UUID().uuidString,
            appleUserID: appleUserID,
            nickname: defaults.string(forKey: DefaultsKey.nickname) ?? Self.defaultNickname,
            avatar: avatar,
            subscriptionStatus: .free,
            subscriptionExpiresAt: nil,
            isLoggedIn: appleUserID != nil,
            boxId: nil
        )

        revokeObserver = NotificationCenter.default.addObserver(
            forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.signOut()
        }
    }

    var isPro: Bool {
        profile.subscriptionStatus == .pro
    }

    // MARK: - 登录

    func completeSignIn(userID: String, fullName: PersonNameComponents?) {
        KeychainHelper.saveAppleUserID(userID)

        // fullName 仅首次授权返回；再登录沿用本地昵称
        if let fullName {
            let formatted = PersonNameComponentsFormatter().string(from: fullName)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !formatted.isEmpty {
                UserDefaults.standard.set(formatted, forKey: DefaultsKey.nickname)
                profile.nickname = formatted
            }
        }

        profile.appleUserID = userID
        profile.userId = userID
        profile.isLoggedIn = true
        showToast("登录成功")
    }

    func signOut() {
        KeychainHelper.deleteAppleUserID()
        profile.appleUserID = nil
        profile.isLoggedIn = false
    }

    /// 启动时校验 Apple 凭证。仅 .revoked 登出（模拟器 .notFound 不可靠）。
    func verifyCredentialOnLaunch() async {
        guard let userID = profile.appleUserID else { return }
        let state = await AuthService.credentialState(for: userID)
        if state == .revoked {
            await MainActor.run { signOut() }
        }
    }

    // MARK: - 昵称与头像（本地存储，仅登录后可编辑）

    func updateNickname(_ nickname: String) {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UserDefaults.standard.set(trimmed, forKey: DefaultsKey.nickname)
        profile.nickname = trimmed
    }

    func updateAvatar(_ choice: AvatarChoice) {
        guard choice != .custom else { return }
        UserDefaults.standard.set(choice.rawValue, forKey: DefaultsKey.avatarChoice)
        profile.avatar = choice
    }

    func setCustomAvatar(imageData: Data) {
        guard let image = UIImage(data: imageData),
              let jpegData = Self.squareThumbnail(from: image)?.jpegData(compressionQuality: 0.85) else {
            showToast("头像设置失败，请重试")
            return
        }

        do {
            let directory = Self.customAvatarURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try jpegData.write(to: Self.customAvatarURL, options: .atomic)
            UserDefaults.standard.set(AvatarChoice.custom.rawValue, forKey: DefaultsKey.avatarChoice)
            profile.avatar = .custom
        } catch {
            showToast("头像设置失败，请重试")
        }
    }

    static func loadCustomAvatar() -> UIImage? {
        UIImage(contentsOfFile: customAvatarURL.path)
    }

    private static var customAvatarURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar.jpg")
    }

    private static func squareThumbnail(from image: UIImage, side: CGFloat = 400) -> UIImage? {
        let shortest = min(image.size.width, image.size.height)
        guard shortest > 0 else { return nil }

        let scale = side / shortest
        let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(x: (side - scaledSize.width) / 2, y: (side - scaledSize.height) / 2)

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.image { _ in
            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }
    }

    // MARK: - Toast 与登录引导

    func showToast(_ message: String) {
        toastMessage = message
    }

    func triggerLoginPromptAfterSave() {
        guard !profile.isLoggedIn else { return }

        let defaults = UserDefaults.standard
        if let lastPrompt = defaults.object(forKey: DefaultsKey.lastLoginPromptDate) as? Date,
           Date.now.timeIntervalSince(lastPrompt) < Self.loginPromptCooldown {
            return
        }

        defaults.set(Date.now, forKey: DefaultsKey.lastLoginPromptDate)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            if !profile.isLoggedIn {
                showLoginPage = true
            }
        }
    }
}
