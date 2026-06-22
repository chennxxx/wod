import AuthenticationServices
import Foundation
import Observation
import SwiftData
import UIKit

@Observable
final class AppState {
    private enum DefaultsKey {
        static let nickname = "wt.nickname"
        static let avatarChoice = "wt.avatarChoice"
        static let lastLoginPromptDate = "wt.lastLoginPromptDate"
        static let profileUpdatedAt = "wt.profileUpdatedAt"
        static let legalTermsAccepted = "wt.legalTermsAccepted"
    }

    /// 保存记录后自动弹登录页的冷却期
    private static let loginPromptCooldown: TimeInterval = 7 * 24 * 3600

    private static let defaultNickname = String(localized: "迹录用户")

    var profile: UserProfile
    var showLoginPage = false
    var toastMessage: String?
    var hasAcceptedLegalTerms: Bool
    /// 放在 AppState 而非 ContentView：iCloud 容器切换会整树重建，tab 位置需跨重建保留
    var selectedTab = 1

    /// 资料写穿到 SwiftData 用（iCloud 容器切换时由 WODTrackApp 更新）
    @ObservationIgnored weak var modelContainer: ModelContainer?

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
        hasAcceptedLegalTerms = defaults.bool(forKey: DefaultsKey.legalTermsAccepted)

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

    // MARK: - 订阅权益

    /// 由 SubscriptionManager 在算出 StoreKit 权益后调用。纯内存：不持久化、不写 SwiftData/CloudKit，
    /// 每次启动由 StoreKit（Transaction.currentEntitlements）重算，权益真相源始终在 Apple ID。
    func applyEntitlement(isPro: Bool) {
        let status: UserProfile.SubscriptionStatus = isPro ? .pro : .free
        guard profile.subscriptionStatus != status else { return }
        profile.subscriptionStatus = status
    }

    // MARK: - 合规同意

    func acceptLegalTerms() {
        UserDefaults.standard.set(true, forKey: DefaultsKey.legalTermsAccepted)
        hasAcceptedLegalTerms = true
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
                touchProfileEdited()
            }
        }

        profile.appleUserID = userID
        profile.userId = userID
        profile.isLoggedIn = true
        showToast(String(localized: "登录成功"))
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
        touchProfileEdited()
    }

    func updateAvatar(_ choice: AvatarChoice) {
        guard choice != .custom else { return }
        UserDefaults.standard.set(choice.rawValue, forKey: DefaultsKey.avatarChoice)
        profile.avatar = choice
        touchProfileEdited()
    }

    func setCustomAvatar(imageData: Data) {
        guard let image = UIImage(data: imageData),
              let jpegData = Self.squareThumbnail(from: image)?.jpegData(compressionQuality: 0.85) else {
            showToast(String(localized: "头像设置失败，请重试"))
            return
        }

        do {
            let directory = Self.customAvatarURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try jpegData.write(to: Self.customAvatarURL, options: .atomic)
            UserDefaults.standard.set(AvatarChoice.custom.rawValue, forKey: DefaultsKey.avatarChoice)
            profile.avatar = .custom
            touchProfileEdited()
        } catch {
            showToast(String(localized: "头像设置失败，请重试"))
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

    // MARK: - 资料 iCloud 同步（SyncedProfile 镜像）

    /// 资料编辑后记录本地时间戳并写穿到 SwiftData（与同步开关无关；开关开启时由 CloudKit 自动上传）。
    private func touchProfileEdited() {
        let now = Date.now
        UserDefaults.standard.set(now, forKey: DefaultsKey.profileUpdatedAt)
        Task { @MainActor [weak self] in
            guard let self, let context = self.modelContainer?.mainContext else { return }
            self.persistProfileToStore(updatedAt: now, context: context)
        }
    }

    /// 启动、回前台、容器重建后调和：云端行更新时间晚于本地 → 应用云端资料；本地更新 → 写回云端行。
    @MainActor
    func reconcileProfile(context: ModelContext) {
        let defaults = UserDefaults.standard
        let localUpdatedAt = defaults.object(forKey: DefaultsKey.profileUpdatedAt) as? Date

        guard let remote = newestStoredProfile(context: context) else {
            // 店内尚无资料行：首次迁移，把本地资料灌入（无时间戳则以当前时间起记）
            let stamp = localUpdatedAt ?? .now
            if localUpdatedAt == nil {
                defaults.set(stamp, forKey: DefaultsKey.profileUpdatedAt)
            }
            persistProfileToStore(updatedAt: stamp, context: context)
            return
        }

        let local = localUpdatedAt ?? .distantPast
        if remote.updatedAt > local {
            applyRemoteProfile(remote)
        } else if local > remote.updatedAt {
            persistProfileToStore(updatedAt: local, context: context)
        }
    }

    @MainActor
    private func persistProfileToStore(updatedAt: Date, context: ModelContext) {
        let record: SyncedProfile
        if let existing = newestStoredProfile(context: context) {
            record = existing
        } else {
            record = SyncedProfile()
            context.insert(record)
        }
        record.nickname = profile.nickname
        record.avatarChoiceRaw = profile.avatar.rawValue
        record.avatarImageData = profile.avatar == .custom
            ? try? Data(contentsOf: Self.customAvatarURL)
            : nil
        record.updatedAt = updatedAt
        try? context.save()
    }

    @MainActor
    private func applyRemoteProfile(_ remote: SyncedProfile) {
        let defaults = UserDefaults.standard

        let trimmed = remote.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            defaults.set(trimmed, forKey: DefaultsKey.nickname)
            profile.nickname = trimmed
        }

        var choice = AvatarChoice(rawValue: remote.avatarChoiceRaw) ?? .default1
        if choice == .custom {
            if let data = remote.avatarImageData {
                let directory = Self.customAvatarURL.deletingLastPathComponent()
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try? data.write(to: Self.customAvatarURL, options: .atomic)
            } else if Self.loadCustomAvatar() == nil {
                // 自定义头像字节未到且本地无文件：先降级默认头像，等下次调和补上
                choice = .default1
            }
        }
        defaults.set(choice.rawValue, forKey: DefaultsKey.avatarChoice)
        profile.avatar = choice

        defaults.set(remote.updatedAt, forKey: DefaultsKey.profileUpdatedAt)
    }

    /// 多设备合并可能出现多行，取 updatedAt 最新（其余由 SyncDedupService 清理）。
    @MainActor
    private func newestStoredProfile(context: ModelContext) -> SyncedProfile? {
        (try? context.fetch(FetchDescriptor<SyncedProfile>()))?
            .max { $0.updatedAt < $1.updatedAt }
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
