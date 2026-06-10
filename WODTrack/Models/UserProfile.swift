import Foundation
import SwiftData

struct UserProfile: Codable {
    var userId: String
    var appleUserID: String?
    var nickname: String
    var avatar: AvatarChoice
    var subscriptionStatus: SubscriptionStatus
    var subscriptionExpiresAt: Date?
    var isLoggedIn: Bool
    var boxId: String?

    enum SubscriptionStatus: String, Codable {
        case free
        case pro
    }
}

/// 昵称与头像的 iCloud 镜像（singleton，CloudKit 不支持 unique，多设备重复行由 SyncDedupService 保留 updatedAt 最新）。
/// 本地权威仍是 UserDefaults + avatar.jpg，本模型只做云端载体；调和逻辑见 AppState.reconcileProfile。
// CloudKit 约束：非可选需声明处默认值。
@Model final class SyncedProfile {
    var nickname: String = ""
    var avatarChoiceRaw: String = "default1"
    @Attribute(.externalStorage) var avatarImageData: Data? = nil
    var updatedAt: Date = Date.now

    init() {}
}

/// 头像选择：2 个内置默认头像 + 自定义上传（图片存本地固定路径）
enum AvatarChoice: String, Codable, Equatable, CaseIterable {
    case default1
    case default2
    case custom

    /// 默认头像对应的 SF Symbol（custom 不使用）
    var symbolName: String {
        switch self {
        case .default1: "dumbbell.fill"
        case .default2: "trophy.fill"
        case .custom: "camera.fill"
        }
    }
}
