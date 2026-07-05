import Foundation

enum AppConfig {
    // OCR 代理（自建 Serverless，服务端持有火山方舟 Key 与 prompt）
    static let apiBaseURL = URL(string: "https://sd8khut1pqtoq9lj35dcg.apigateway-cn-beijing.volceapi.com")!
    static let ocrPath = "ocr"
    // 代理当前未设置 APP_SHARED_SECRET，暂无校验；开启后填入同一 secret，OCRService 会以 X-App-Secret 发送
    static let appToken = ""
    static let requestTimeout: TimeInterval = 30

    static let useMockOCR = false

    // MARK: - 订阅（RevenueCat）
    /// RevenueCat 公钥（Apple 平台公钥 `appl_…`）：走真实 App Store（开发/TestFlight 沙盒、上架正式）。
    static let revenueCatAPIKey = "appl_ZUFeLLliuuUCJULpAMRUwyeVixg"

    // MARK: - 免费额度门控
    /// 免费用户每自然日 OCR 识别次数上限。
    static let freeOCRDailyLimit = 2
    /// 免费用户可见的历史记录天数（更早灰显，需 Pro 解锁）。
    static let freeHistoryWindowDays = 30

    // MARK: - 动作示范视频（腾讯云 COS + CDN）
    /// 视频 CDN 域名。将来换域名只改这一行。
    /// 备用（CDN 异常时可临时切回 COS 源站直连）：
    /// "https://movements-1258129816.cos.ap-guangzhou.myqcloud.com"
    static let videoBaseURL = "https://offercall.site"

    /// 拼出某动作的示范视频地址：`{videoBaseURL}/movements/{skillId}.mp4`。
    /// 靠动作 id + 命名规则得出，无需后端、无需逐个配置。
    static func movementVideoURL(for skillId: String) -> URL? {
        URL(string: "\(videoBaseURL)/movements/\(skillId).mp4")
    }
}
