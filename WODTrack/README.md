# WODTrack iOS App

CrossFit 训练记录工具，支持白板 OCR 识别、训练卡片生成与历史记录管理。

当前版本：`1.7.1`

工程入口：

- Xcode 工程：`WODTrack.xcodeproj`
- App target：`WODTrack`
- 最低系统版本：iOS 17.0

## 主要功能

- **白板 OCR**：拍摄训练白板，接入 Doubao 多模态大模型自动识别 WOD 内容
- **训练卡片**：多套模板（训练日志、夜训卡片、大字报、数据仪表盘、胶片复古、极简白底、杂志封面），支持字体、字号、位置、透明度自定义，保存后自动写入系统相册
- **历史记录**：SwiftData 持久化，支持打卡照片与成图预览，热力图按日期可视化训练频率
- **技能树**：体操、举重、有氧三大类动作，按 T0/T1/T2 难度分组展示
- **系统分享**：通过 Share Sheet 分享到微信、朋友圈、小红书等渠道

## 工程结构

```
WODTrack/
├── Models/          # SwiftData 数据模型（WODRecord 等）
├── ViewModels/      # 业务逻辑（RecordFlowViewModel 等）
├── Views/           # SwiftUI 视图（History、Preview、SkillTree 等）
├── Services/        # 外部服务（DoubaoLLMService、ImagePathResolver 等）
├── Config/          # 模板配置（CardStyleConfig、AppConfig 等）
└── Resources/       # 资源文件（Assets、Info.plist）
```

## 数据存储

- **训练记录**：SwiftData（SQLite），数据库名 `WODTrackStore_v3`
- **图片文件**：`Documents/WODTrackRecords/`，以文件名存储路径引用，兼容 App 版本更新
