# 技术实施方案：相机拍摄 + OCR 识别接入

> 目标读者：Codex / 开发同学  
> 对应功能：`WhiteboardStep` 中"立即拍摄"按钮的完整实现  
> 状态：**待开发**

---

## 1. 背景与现状

### 已完成
- `OCRService.recognize(image:)` 已实现：将图片压缩为 base64，POST 到后端 `/ocr` 接口，解析返回的 `OCRAPIResponse`
- `RecordFlowViewModel.startFlow(with:)` 已实现：接收 `UIImage`，触发 OCR，更新 UI 状态
- "从相册选取"已通过 `PhotosPicker` 实现并正常工作
- `PreviewOCRService` mock 已就绪，可用于 Xcode Preview 调试

### 待完成
`WhiteboardStep` 中"立即拍摄"按钮当前只弹出 `.alert("拍摄入口待接入", ...)`，**需要替换为真实的相机拍摄流程**。

---

## 2. 技术选型

使用 **`UIImagePickerController` + `UIViewControllerRepresentable`** 方案，原因：

| 方案 | 优点 | 缺点 |
|------|------|------|
| `UIImagePickerController` | 集成简单，系统 UI，自动处理权限提示 | 定制化程度有限 |
| `AVCaptureSession` | 完全自定义取景框、快门动画 | 实现复杂，约需 400+ 行代码 |

当前阶段优先选 `UIImagePickerController`，后续如有品牌化相机 UI 需求再迁移至 `AVFoundation`。

---

## 3. 实现步骤

### 3.1 添加相机权限声明

在 `WODTrack/Resources/Info.plist` 中添加：

```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机来拍摄白板内容，识别今日 WOD</string>
```

> ⚠️ 缺少此 key 会导致运行时 crash，必须先添加。

---

### 3.2 新建 `CameraPickerView.swift`

在 `WODTrack/Views/Common/` 目录下创建：

```swift
// CameraPickerView.swift
import SwiftUI
import UIKit

/// 包装 UIImagePickerController，仅用于相机拍摄（sourceType = .camera）
struct CameraPickerView: UIViewControllerRepresentable {
    /// 拍摄完成后回调，返回 UIImage；用户取消时回调 nil
    var onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var onCapture: (UIImage?) -> Void

        init(onCapture: @escaping (UIImage?) -> Void) {
            self.onCapture = onCapture
        }

        // 用户拍摄并确认
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true) { [weak self] in
                self?.onCapture(image)
            }
        }

        // 用户点击"取消"
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) { [weak self] in
                self?.onCapture(nil)
            }
        }
    }
}
```

---

### 3.3 添加相机可用性检查工具函数

在同一文件（或 `AppConfig.swift`）中添加：

```swift
extension UIImagePickerController {
    /// 判断当前设备相机是否可用（模拟器上为 false）
    static var isCameraAvailable: Bool {
        isSourceTypeAvailable(.camera)
    }
}
```

---

### 3.4 修改 `WhiteboardStep`

定位文件：`WODTrack/Views/Record/RecordFlowCoordinator.swift`

**需要改动的部分**：

#### 3.4.1 新增状态变量

```swift
// 现有状态：
@State private var showCameraNotice = false   // ← 删除这个

// 新增：
@State private var showCamera = false
@State private var cameraUnavailableAlert = false
```

#### 3.4.2 替换"立即拍摄"按钮的 action

```swift
// 原代码（删除）：
Button("立即拍摄") {
    showCameraNotice = true
}

// 替换为：
Button("立即拍摄") {
    if UIImagePickerController.isCameraAvailable {
        showCamera = true
    } else {
        cameraUnavailableAlert = true
    }
}
```

#### 3.4.3 添加 sheet 和 alert

在 `.photosPicker(...)` 修饰符之后、`.task(id:)` 之前追加：

```swift
.sheet(isPresented: $showCamera) {
    CameraPickerView { image in
        showCamera = false
        guard let image else { return }
        viewModel.startFlow(with: image)
    }
    .ignoresSafeArea()
}
.alert("相机不可用", isPresented: $cameraUnavailableAlert) {
    Button("知道了", role: .cancel) {}
} message: {
    Text("当前设备不支持相机，请使用「从相册选取」功能。")
}
```

#### 3.4.4 删除旧 alert

删除下面这段（已被新逻辑替代）：

```swift
// 删除以下代码块：
.alert("拍摄入口待接入", isPresented: $showCameraNotice) {
    Button("知道了", role: .cancel) {}
} message: {
    Text("当前版本先保留相册导入和手动输入，系统拍摄入口我下一步接入。")
}
```

---

## 4. 完整数据流

```
用户点击"立即拍摄"
        │
        ▼
UIImagePickerController.isCameraAvailable?
   是 ──▶ showCamera = true
   否 ──▶ 弹出"相机不可用" alert
        │
        ▼ (系统相机 UI 显示)
用户拍摄 / 确认
        │
        ▼
CameraPickerView.Coordinator.didFinishPickingMedia
        │
        ▼
onCapture(image) 回调
        │
        ▼
viewModel.startFlow(with: image)
  ├── selectedWhiteboardImage = image
  ├── ocrState = .processing
  ├── step = .ocrResult (UI 跳转到 OCR loading 界面)
  └── Task { ocrService.recognize(image:) }
            │
            ├── 成功 → ocrState = .success(result)，自动填入 WOD 内容
            └── 失败 → ocrState = .failure(message)，用户可手动输入或重试
```

---

## 5. OCR 服务接入说明

`OCRService.recognize(image:)` 已经完整实现，调用方只需传入 `UIImage`。

当前接口配置（`AppConfig.swift`）：

| 配置项 | Key |
|--------|-----|
| 后端地址 | `AppConfig.apiBaseURL` + `AppConfig.ocrPath` |
| 鉴权 | `Bearer AppConfig.appToken` |
| 超时 | `AppConfig.requestTimeout` |
| 图片压缩 | 最大边 1024px，JPEG 0.8 质量，转 base64 |

后端返回格式：

```json
{
  "wod_type": "for_time",
  "wod_content": ["21-15-9", "Thruster 43kg", "Pull-up"],
  "confidence": 0.92
}
```

---

## 6. 测试要点

| 场景 | 预期行为 |
|------|---------|
| 真机 - 拍摄并确认 | 进入 OCR 识别流程，显示 loading，识别完成后跳转 OCRResultStep |
| 真机 - 点取消 | sheet 关闭，停留在 WhiteboardStep |
| 模拟器 | 弹出"相机不可用" alert |
| 无相机权限（首次） | 系统自动弹出权限请求弹窗（iOS 原生行为） |
| 无相机权限（已拒绝） | 系统弹窗引导用户去设置页开启权限 |
| OCR 识别失败 | 进入 OCRResultStep 失败状态，显示手动输入框和"重试"按钮 |
| 图片为空/无效 | OCRService 抛出 `OCRError.invalidImage`，显示失败提示 |

---

## 7. 后续可选增强（不阻塞当前开发）

- **拍摄引导框**：在相机 UI 上叠加一个半透明矩形框，引导用户对准白板（需改用 `AVCaptureSession`）
- **自动对焦白板**：检测到矩形轮廓时自动触发拍摄（Vision framework `VNDetectRectanglesRequest`）
- **图片预处理**：拍摄后做透视矫正、对比度增强，提升 OCR 准确率（`CIFilter` / `CoreImage`）
- **离线 OCR 备用**：使用 `VNRecognizeTextRequest`（Vision）在本地识别，网络不可用时兜底

---

## 8. 涉及文件清单

| 文件 | 操作 |
|------|------|
| `WODTrack/Resources/Info.plist` | 新增 `NSCameraUsageDescription` |
| `WODTrack/Views/Common/CameraPickerView.swift` | **新建** |
| `WODTrack/Views/Record/RecordFlowCoordinator.swift` | 修改 `WhiteboardStep`（见 3.4 节） |

无需改动：`OCRService.swift`、`RecordFlowViewModel.swift`、`AppConfig.swift`
