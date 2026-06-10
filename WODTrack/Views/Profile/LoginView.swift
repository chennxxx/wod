import AuthenticationServices
import SwiftUI

/// 全屏登录页：仅 Sign in with Apple，协议勾选为前置条件。
struct LoginView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var agreed = false
    @State private var localToast: String?
    @State private var agreementKind: AgreementKind?

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                closeBar
                Spacer()
                brandLock
                Spacer()
                footer
            }
        }
        .wtToast(message: $localToast)
        .sheet(item: $agreementKind) { kind in
            NavigationStack {
                AgreementView(kind: kind)
            }
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

    private var closeBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.wtTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
            }
            Spacer()
        }
        .padding(.horizontal, WTSpacing.md + 2)
        .padding(.top, WTSpacing.sm)
    }

    private var brandLock: some View {
        VStack(spacing: WTSpacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: 26)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#6CF09C"), Color(hex: "#2FB866")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: Color.wtPrimary.opacity(0.32), radius: 20, y: 14)

                Text("迹")
                    .font(.system(size: 50, weight: .black))
                    .foregroundStyle(Color(hex: "#07301C"))
            }

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

            Button {
                dismiss()
            } label: {
                Text("暂不登录")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.wtTextSecondary)
                    .padding(WTSpacing.xs)
            }
        }
        .padding(.horizontal, WTSpacing.lg)
        .padding(.bottom, WTSpacing.lg)
    }

    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName]
        } onCompletion: { result in
            handleAppleResult(result)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
        .overlay {
            // 未勾选协议时拦截点击，不唤起系统授权
            if !agreed {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        localToast = "请先阅读并同意用户协议与隐私政策"
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
                    .onTapGesture { agreementKind = .userAgreement }
                Text(" 与 ")
                    .foregroundStyle(Color.wtTextSecondary)
                Text("《隐私政策》")
                    .foregroundStyle(Color.wtPrimary)
                    .onTapGesture { agreementKind = .privacyPolicy }
            }
            .font(.system(size: 12.5))
        }
        .padding(.horizontal, WTSpacing.xs)
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                localToast = "登录失败，请重试"
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
