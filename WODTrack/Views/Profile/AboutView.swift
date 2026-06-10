import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: WTSpacing.lg) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#6CF09C"), Color(hex: "#2FB866")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 84, height: 84)
                    .shadow(color: Color.wtPrimary.opacity(0.3), radius: 16, y: 10)

                Text("迹")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(Color(hex: "#07301C"))
            }

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

// MARK: - 用户协议 / 隐私政策

enum AgreementKind: String, Identifiable {
    case userAgreement
    case privacyPolicy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .userAgreement: "用户协议"
        case .privacyPolicy: "隐私政策"
        }
    }
}

struct AgreementView: View {
    let kind: AgreementKind

    var body: some View {
        ScrollView {
            Text(content)
                .font(.system(size: 14))
                .foregroundStyle(Color.wtTextSecondary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(WTSpacing.lg)
        }
        .background(Color.wtBackground)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: String {
        switch kind {
        case .userAgreement: Self.userAgreementText
        case .privacyPolicy: Self.privacyPolicyText
        }
    }

    private static let userAgreementText = """
    欢迎使用迹录 WOD（以下简称"本应用"）。在使用本应用前，请仔细阅读本用户协议。使用本应用即表示你同意以下条款。

    一、服务说明
    本应用为 CrossFit 训练记录工具，提供 WOD 拍照识别、训练打卡卡片生成、训练历史管理与技能成长追踪等功能。

    二、账号
    1. 本应用支持通过 Apple 账号登录。登录为可选项，未登录状态下核心记录功能仍可正常使用。
    2. 你可随时在「我的」页面退出登录。退出登录不会删除你存储在本机的训练数据。

    三、用户内容
    1. 你通过本应用拍摄或选取的照片、生成的卡片及训练数据均存储在你的设备本地。
    2. 你对自己记录的内容负责，请勿录入违反法律法规的内容。

    四、知识产权
    本应用的界面设计、图标、文案等知识产权归开发者所有。未经许可，不得复制、修改或用于商业用途。

    五、免责声明
    1. 训练数据仅供个人参考，不构成任何专业训练或医疗建议。
    2. 因设备故障、系统升级或卸载应用导致的本地数据丢失，开发者不承担责任。建议定期备份重要数据。

    六、协议变更
    开发者可能适时更新本协议，更新后的协议将在本页面公布，继续使用本应用视为接受更新后的条款。

    更新日期：2026 年 6 月
    """

    private static let privacyPolicyText = """
    迹录 WOD（以下简称"本应用"）尊重并保护你的隐私。本政策说明我们如何收集、使用与存储你的信息。

    一、我们收集的信息
    1. Apple 登录信息：当你选择通过 Apple 登录时，我们仅获取 Apple 提供的用户标识符与姓名（首次授权时）。你可以选择对本应用隐藏真实邮箱；本应用不收集、不存储你的邮箱地址。
    2. 相机与相册：用于拍摄白板 WOD 内容、选取训练照片及保存生成的卡片。照片仅在你主动操作时被访问。
    3. 训练数据：你记录的 WOD 内容、打卡信息与技能进度。

    二、信息的存储
    1. 你的训练数据、昵称、头像均存储在你的设备本地，不会上传至任何服务器。
    2. Apple 登录标识符存储在设备的钥匙串（Keychain）中，仅用于维持登录状态。
    3. WOD 图像识别功能会将你拍摄的白板照片发送至第三方识别服务以提取文字内容，识别结果不与你的身份关联。

    三、信息的使用
    我们收集的信息仅用于实现本应用功能，不会用于广告追踪，不会出售或共享给第三方。

    四、你的权利
    1. 你可随时退出登录，本应用将删除设备上保存的登录标识。
    2. 你可在系统设置中随时撤销对本应用的 Apple 登录授权、相机与相册权限。
    3. 卸载本应用将删除全部本地数据。

    五、未成年人保护
    本应用不面向 14 周岁以下儿童。若你是未成年人，请在监护人指导下使用。

    六、政策变更
    本政策更新后将在本页面公布。如有疑问，可通过「我的 - 反馈」与我们联系。

    更新日期：2026 年 6 月
    """
}
