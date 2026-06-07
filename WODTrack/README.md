# WODTrack iOS MVP Scaffold

这个目录是按需求文档新增的 SwiftUI iOS MVP 源码骨架，和现有微信小程序目录并存，不互相覆盖。

当前版本：`1.0版本`

工程入口：

- Xcode 工程：[WODTrack.xcodeproj](/Users/chen/Desktop/wod/WODTrack.xcodeproj)
- App target：`WODTrack`
- Test target：`WODTrackTests`

已落地内容：

- `TabView` 三个页签：技能树、记录、我的
- `RecordFlowViewModel` 多步骤录入状态机
- 白板 OCR 服务协议与 URLSession 实现骨架
- 卡片预览与 `ImageRenderer` 导出入口
- `SwiftData` 模型、历史列表、个人页、登录引导占位
- 深色主题、主按钮、输入框、Loading 组件
- `Info.plist`、`Assets.xcassets`、shared scheme、单元测试 target
- 最低系统版本已统一为 `iOS 17.0`

当前限制：

- 工作区里没有完整 Xcode 工程文件，且本机只有 Command Line Tools，没有完整 Xcode，所以这里先交付源码目录，未做本地编译验证
- `WODTrack.xcodeproj/project.pbxproj` 已通过 `plutil -lint` 语法校验
- 微信登录、CloudKit、相册写入、真实图片权限流仍是占位实现
- OCR API 需要服务端可用后再填 `AppConfig`
