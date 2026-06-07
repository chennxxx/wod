# 维护更新记录

## 1.0版本 - 2026-06-07

- 初始化 `WODTrack` SwiftUI iOS App 工程结构。
- 完成技能树、记录、我的三个基础页签入口。
- 完成训练记录多步骤录入状态机与手动输入流程骨架。
- 接入 SwiftData 数据模型、历史记录列表、个人页与登录引导占位。
- 新增白板 OCR 服务协议、URLSession 实现骨架与拍照/OCR 技术方案文档。
- 新增卡片预览与 `ImageRenderer` 导出入口。
- 配置深色主题、主按钮、输入框、Loading 组件、`Info.plist`、资源目录、shared scheme 与单元测试 target。
- 最低系统版本统一为 `iOS 17.0`。

### 当前限制

- 本地环境只有 Command Line Tools，没有完整 Xcode，暂未进行 Xcode 编译验证。
- 微信登录、CloudKit、相册写入、真实图片权限流仍为占位实现。
- OCR API 需要服务端可用后再配置 `AppConfig`。
