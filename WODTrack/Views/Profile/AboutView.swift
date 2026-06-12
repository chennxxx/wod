import SafariServices
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: WTSpacing.lg) {
            Spacer()

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 19))
                .shadow(color: Color.wtPrimary.opacity(0.3), radius: 16, y: 10)

            VStack(spacing: WTSpacing.sm) {
                HStack(spacing: 6) {
                    Text("迹录")
                        .foregroundStyle(Color.wtTextPrimary)
                    Text("WOD")
                        .foregroundStyle(Color.wtPrimary)
                }
                .font(.system(size: 24, weight: .heavy))

                Text("版本 \(appVersion)")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
            }

            Text("每一次进步，都有迹可循")
                .font(WTFont.body)
                .foregroundStyle(Color.wtTextSecondary)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.wtBackground)
        .navigationTitle("关于我们")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}

// MARK: - 合规文档

enum LegalDocument: String, CaseIterable, Identifiable {
    case userAgreement
    case privacyPolicy
    case supportFAQ
    case accountDeletion
    case feedback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .userAgreement: "用户协议"
        case .privacyPolicy: "隐私政策"
        case .supportFAQ: "技术支持与常见问题"
        case .accountDeletion: "账号注销说明"
        case .feedback: "反馈"
        }
    }

    var icon: String {
        switch self {
        case .userAgreement: "doc.text"
        case .privacyPolicy: "shield"
        case .supportFAQ: "questionmark.circle"
        case .accountDeletion: "person.crop.circle.badge.xmark"
        case .feedback: "bubble.left"
        }
    }

    var url: URL {
        switch self {
        case .userAgreement:
            URL(string: "https://docs.qq.com/doc/DUk5pRVREYWVqeUNn")!
        case .privacyPolicy:
            URL(string: "https://docs.qq.com/doc/DUklUeGFVdGFQVm9a")!
        case .supportFAQ:
            URL(string: "https://docs.qq.com/doc/DUkVISGZTcW1sT3Bz")!
        case .accountDeletion:
            URL(string: "https://docs.qq.com/doc/DUmhtT0RIUHZDU1hC")!
        case .feedback:
            URL(string: "https://docs.qq.com/form/page/DUmh6S25LcFNZZXBS")!
        }
    }
}

struct LegalDocumentSheet: View {
    let document: LegalDocument

    var body: some View {
        SafariWebView(url: document.url)
            .ignoresSafeArea()
    }
}

private struct SafariWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredBarTintColor = UIColor(Color.wtSurface)
        controller.preferredControlTintColor = UIColor(Color.wtPrimary)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
