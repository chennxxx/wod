import Foundation

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
