import SwiftUI
import UIKit

/// 删除账号确认页。无后端，删除请求经表单提交到运营侧人工处理。
private let accountDeletionFormURL = URL(string: "https://docs.qq.com/form/page/DUmxDdW5xWkhESXFm")!

struct AccountDeletionView: View {
    @Bindable var appState: AppState
    @Environment(\.openURL) private var openURL

    @State private var showConfirmDialog = false

    private var accountIdentifier: String {
        appState.profile.appleUserID ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WTSpacing.lg) {
                header
                processCard
                identifierCard

                Text("提交后我们将在服务端移除你的全部数据。该操作不可逆，请谨慎确认。")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                    .lineSpacing(3)
                    .padding(.horizontal, 4)

                deleteButton
            }
            .padding(WTSpacing.md)
            .padding(.bottom, 40)
        }
        .background(Color.wtBackground)
        .navigationTitle("删除账号")
        .navigationBarTitleDisplayMode(.inline)
        .alert("确定删除账号？", isPresented: $showConfirmDialog) {
            Button("确定删除", role: .destructive) { submitDeletion() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("我们会打开删除申请表单。你的账号标识已复制到剪贴板，请在表单中粘贴提交。")
        }
    }

    // MARK: - 区块

    private var header: some View {
        VStack(spacing: WTSpacing.md - 4) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 40))
                .foregroundStyle(Color.wtDanger)
                .frame(width: 76, height: 76)
                .background(Color.wtDanger.opacity(0.12))
                .clipShape(Circle())

            Text("删除你的账号")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.wtTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, WTSpacing.md)
    }

    private var processCard: some View {
        VStack(alignment: .leading, spacing: WTSpacing.md - 2) {
            processRow(index: 1, text: "提交申请后，我们会在服务端移除与该账号关联的全部数据。")
            processRow(index: 2, text: "30 天内你可以发送邮件向我们申请撤回，账号与数据将予以恢复。")
            processRow(index: 3, text: "若 30 天内没有任何撤回操作，账号将被正式注销，且无法再恢复。")
        }
        .padding(WTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
    }

    private func processRow(index: Int, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: WTSpacing.md - 4) {
            Text("\(index)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.wtPrimary)
                .frame(width: 24, height: 24)
                .background(Color.wtPrimary.opacity(0.14))
                .clipShape(Circle())

            Text(text)
                .font(WTFont.body)
                .foregroundStyle(Color.wtTextPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var identifierCard: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm) {
            Text("你的账号标识")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.wtTextSecondary)

            HStack(spacing: WTSpacing.sm) {
                Text(accountIdentifier)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color.wtTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button {
                    copyIdentifier()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                        Text("复制")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Color.wtPrimary)
                    .padding(.horizontal, WTSpacing.sm + 2)
                    .padding(.vertical, 7)
                    .background(Color.wtPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(WTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
    }

    private var deleteButton: some View {
        Button {
            showConfirmDialog = true
        } label: {
            Text("确定删除")
                .font(WTFont.bodyBold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.wtDanger)
                .clipShape(RoundedRectangle(cornerRadius: WTRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 动作

    private func copyIdentifier() {
        UIPasteboard.general.string = accountIdentifier
        appState.showToast(String(localized: "已复制账号标识"))
    }

    private func submitDeletion() {
        UIPasteboard.general.string = accountIdentifier
        openURL(accountDeletionFormURL)
        appState.showToast(String(localized: "已复制账号标识，请在表单中粘贴"))
    }
}
