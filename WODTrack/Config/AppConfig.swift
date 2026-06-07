import Foundation

enum AppConfig {
    // Legacy OCR (unused)
    static let apiBaseURL = URL(string: "https://api.wodtrack.app/v1")!
    static let ocrPath = "ocr"
    static let appToken = "REPLACE_WITH_SERVER_ISSUED_APP_TOKEN"
    static let requestTimeout: TimeInterval = 30

    // Doubao LLM
    static let doubaoAPIURL = URL(string: "https://ark.cn-beijing.volces.com/api/v3/chat/completions")!
    static let doubaoAPIKey = "YOUR_ARK_API_KEY"
    static let doubaoModel = "doubao-seed-2-0-mini-260428"

    static let useMockOCR = false
}
