import Foundation

struct UserProfile: Codable {
    var userId: String
    var wechatOpenId: String?
    var nickname: String
    var avatarURL: String?
    var subscriptionStatus: SubscriptionStatus
    var subscriptionExpiresAt: Date?
    var isLoggedIn: Bool
    var boxId: String?

    enum SubscriptionStatus: String, Codable {
        case free
        case pro
    }
}

