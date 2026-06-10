import CloudKit
import SwiftData
import SwiftUI

/// iCloud 同步详情页：开关 + 系统账号状态 + 本地数据概览。
/// 状态展示走"诚实降级"：SwiftData 镜像不暴露进度/设备数，不做伪进度。
struct ICloudSyncSettingsView: View {
    @Bindable var appState: AppState
    @Bindable var syncManager: CloudSyncManager
    @Query private var records: [WODRecord]

    @State private var showDisableConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WTSpacing.lg) {
                toggleCard

                Text(explanation)
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 6)

                statusGroup
                localDataGroup
            }
            .padding(WTSpacing.md)
            .padding(.bottom, 40)
        }
        .background(Color.wtBackground)
        .navigationTitle("iCloud 同步")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await syncManager.refreshAccountStatus()
        }
        .alert("关闭 iCloud 同步？", isPresented: $showDisableConfirm) {
            Button("关闭同步", role: .destructive) {
                syncManager.isSyncEnabled = false
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("已上传到 iCloud 的数据不会删除，本机记录也完整保留。重新开启即可继续同步。")
        }
    }

    // MARK: - 开关

    private var toggleCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: WTSpacing.md - 3) {
                Image(systemName: "icloud")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "#6EA2FF"))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: "#6EA2FF").opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 9))

                Text("iCloud 同步")
                    .font(WTFont.body)
                    .foregroundStyle(Color.wtTextPrimary)

                Spacer()

                Toggle("", isOn: toggleBinding)
                    .labelsHidden()
                    .tint(Color.wtPrimary)
                    .disabled(toggleDisabled)
            }
            .padding(.horizontal, WTSpacing.md - 1)
            .padding(.vertical, 12)
        }
        .background(Color.wtSurface)
        .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
    }

    private var toggleDisabled: Bool {
        syncManager.isSwapping || (!syncManager.isSyncEnabled && syncManager.accountStatus != .available)
    }

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { syncManager.isSyncEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        let ok = await syncManager.requestEnableSync()
                        if !ok {
                            appState.showToast("请先在系统设置中登录 iCloud")
                        }
                    }
                } else {
                    showDisableConfirm = true
                }
            }
        )
    }

    private var explanation: String {
        if syncManager.isSyncEnabled {
            return "同步在后台自动进行，无需手动操作。数据通过你的私人 iCloud 在多台设备间同步，不经过我们的服务器。iCloud 空间不足时，系统会自动暂停同步。"
        }
        return "开启后，训练记录通过你的 iCloud 在多台设备间同步、换机不丢。数据存于你的 iCloud 私人空间，不经过我们的服务器。关闭后本机与云端数据均会保留。"
    }

    // MARK: - 账号状态

    private var statusGroup: some View {
        group(label: "同步状态") {
            infoRow(title: "系统 iCloud 账户", value: accountStatusText, valueColor: accountStatusColor)
        }
    }

    private var accountStatusText: String {
        switch syncManager.accountStatus {
        case .available: "已登录"
        case .noAccount: "未登录"
        case .restricted: "受限"
        case .temporarilyUnavailable: "暂不可用"
        case .couldNotDetermine: "检查中…"
        @unknown default: "未知"
        }
    }

    private var accountStatusColor: Color {
        syncManager.accountStatus == .available ? .wtPrimary : .wtTextSecondary
    }

    // MARK: - 本地数据

    private var localDataGroup: some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm + 1) {
            group(label: "本地数据") {
                infoRow(title: "记录条目", value: "\(records.count) 条")
                divider
                infoRow(title: "占用空间", value: storageSizeText)
                divider
                Button {
                    appState.showToast("即将推出")
                } label: {
                    HStack {
                        Text("导出全部数据")
                            .font(WTFont.body)
                            .foregroundStyle(Color.wtTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.wtTextDisabled)
                    }
                    .padding(.horizontal, WTSpacing.md - 1)
                    .padding(.vertical, 13)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if syncManager.accountStatus != .available && !syncManager.isSyncEnabled {
                Text("本设备尚未登录 iCloud。请前往 系统设置 → Apple ID → iCloud 登录后再开启同步。")
                    .font(WTFont.caption)
                    .foregroundStyle(Color.wtTextSecondary)
                    .padding(.horizontal, 6)
            }
        }
    }

    private var storageSizeText: String {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WODTrackRecords", isDirectory: true)
        let bytes = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey]))?
            .compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }
            .reduce(0, +) ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    // MARK: - 通用小组件

    @ViewBuilder
    private func group(label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: WTSpacing.sm + 1) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.wtTextSecondary)
                .padding(.horizontal, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.wtSurface)
            .clipShape(RoundedRectangle(cornerRadius: WTRadius.lg))
        }
    }

    private func infoRow(title: String, value: String, valueColor: Color = .wtTextSecondary) -> some View {
        HStack {
            Text(title)
                .font(WTFont.body)
                .foregroundStyle(Color.wtTextPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, WTSpacing.md - 1)
        .padding(.vertical, 13)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, WTSpacing.md - 1)
    }
}
