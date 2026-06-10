import Foundation

enum AppConfig {
    // OCR 代理（自建 Serverless，服务端持有火山方舟 Key 与 prompt）
    static let apiBaseURL = URL(string: "https://sd8khut1pqtoq9lj35dcg.apigateway-cn-beijing.volceapi.com")!
    static let ocrPath = "ocr"
    // 代理当前未设置 APP_SHARED_SECRET，暂无校验；开启后填入同一 secret，OCRService 会以 X-App-Secret 发送
    static let appToken = ""
    static let requestTimeout: TimeInterval = 30

    static let useMockOCR = false
}
