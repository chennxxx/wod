import Foundation
import Observation

@Observable
final class AppState {
    var profile = UserProfile(
        userId: UUID().uuidString,
        wechatOpenId: nil,
        nickname: "Box Athlete",
        avatarURL: nil,
        subscriptionStatus: .free,
        subscriptionExpiresAt: nil,
        isLoggedIn: false,
        boxId: nil
    )

    var showLoginPrompt = false

    var isPro: Bool {
        profile.subscriptionStatus == .pro
    }

    func triggerLoginPromptAfterSave() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            if !profile.isLoggedIn {
                showLoginPrompt = true
            }
        }
    }
}
