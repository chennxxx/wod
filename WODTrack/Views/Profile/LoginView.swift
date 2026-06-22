import AuthenticationServices
import SwiftUI

/// 全屏登录页：仅 Sign in with Apple，协议勾选为前置条件。
struct LoginView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var agreed = false
    @State private var localToast: String?
    @State private var legalDocument: LegalDocument?

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                topBar
                Spacer()
                brandLock
                // 下方双 Spacer 让品牌区整体上移，避免视觉重心偏低
                Spacer()
                Spacer()
                footer
            }
        }
        .wtToast(message: $localToast)
        .sheet(item: $legalDocument) { document in
            LegalDocumentSheet(document: document)
            .preferredColorScheme(.dark)
        }
    }

    private var background: some View {
        ZStack {
            Color.wtBackground.ignoresSafeArea()
            RadialGradient(
                colors: [Color.wtPrimary.opacity(0.15), .clear],
                center: .init(x: 0.5, y: 0.05),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("暂不登录")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.wtTextSecondary)
                    .padding(.horizontal, WTSpacing.md - 2)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, WTSpacing.md + 2)
        .padding(.top, WTSpacing.sm)
    }

    private var brandLock: some View {
        VStack(spacing: WTSpacing.lg) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: Color.wtPrimary.opacity(0.32), radius: 20, y: 14)

            VStack(spacing: WTSpacing.md - 4) {
                HStack(spacing: 6) {
                    Text("迹录")
                        .foregroundStyle(Color.wtTextPrimary)
                    Text("WOD")
                        .foregroundStyle(Color.wtPrimary)
                }
                .font(.system(size: 30, weight: .heavy))

                Text("每一次进步，都有迹可循")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.wtTextSecondary)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: WTSpacing.md) {
            appleButton
            agreementRow
        }
        .padding(.horizontal, WTSpacing.lg)
        .padding(.bottom, WTSpacing.lg + 4)
    }

    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName]
        } onCompletion: { result in
            handleAppleResult(result)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 50)
        .overlay {
            // 未勾选协议时拦截点击，不唤起系统授权
            if !agreed {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        localToast = String(localized: "请先阅读并同意用户协议与隐私政策")
                    }
            }
        }
    }

    private var agreementRow: some View {
        HStack(alignment: .top, spacing: WTSpacing.sm + 1) {
            Button {
                agreed.toggle()
            } label: {
                Image(systemName: agreed ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(agreed ? Color.wtPrimary : Color.wtTextSecondary)
            }

            HStack(spacing: 0) {
                Text("我已阅读并同意 ")
                    .foregroundStyle(Color.wtTextSecondary)
                Text("《用户协议》")
                    .foregroundStyle(Color.wtPrimary)
                    .onTapGesture { legalDocument = .userAgreement }
                Text(" 与 ")
                    .foregroundStyle(Color.wtTextSecondary)
                Text("《隐私政策》")
                    .foregroundStyle(Color.wtPrimary)
                    .onTapGesture { legalDocument = .privacyPolicy }
            }
            .font(.system(size: 12.5))
        }
        .padding(.horizontal, WTSpacing.xs)
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                localToast = String(localized: "登录失败，请重试")
                return
            }
            appState.completeSignIn(userID: credential.user, fullName: credential.fullName)
            dismiss()

        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            localToast = "登录失败，请重试"
        }
    }
}
