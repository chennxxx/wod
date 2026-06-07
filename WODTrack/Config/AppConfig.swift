import Foundation

enum AppConfig {
    static let apiBaseURL = URL(string: "https://api.wodtrack.app/v1")!
    static let ocrPath = "ocr"
    static let appToken = "REPLACE_WITH_SERVER_ISSUED_APP_TOKEN"
    static let requestTimeout: TimeInterval = 30
    static let useMockOCR = true
}
