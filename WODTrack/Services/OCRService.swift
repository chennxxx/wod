import Foundation
import UIKit

enum OCRError: LocalizedError {
    case networkTimeout
    case invalidImage
    case serviceUnavailable
    case parseError

    var errorDescription: String? {
        switch self {
        case .networkTimeout: "识别超时，请检查网络连接"
        case .invalidImage: "图片无效，请重新选择"
        case .serviceUnavailable: "识别服务暂不可用"
        case .parseError: "识别结果解析失败"
        }
    }
}

struct OCRResult: Codable, Equatable {
    var wodType: WODType
    var wodContent: [String]
    var confidence: Double
}

protocol OCRServicing {
    func recognize(image: UIImage) async throws -> OCRResult
}

actor OCRService: OCRServicing {
    static let shared = OCRService()

    func recognize(image: UIImage) async throws -> OCRResult {
        guard let payload = image.compressedJPEGBase64() else {
            throw OCRError.invalidImage
        }

        var request = URLRequest(url: AppConfig.apiBaseURL.appending(path: AppConfig.ocrPath))
        request.httpMethod = "POST"
        request.timeoutInterval = AppConfig.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !AppConfig.appToken.isEmpty {
            request.setValue(AppConfig.appToken, forHTTPHeaderField: "X-App-Secret")
        }
        request.httpBody = try JSONEncoder().encode(["image_base64": payload])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OCRError.serviceUnavailable
            }
            guard (200 ..< 300).contains(httpResponse.statusCode) else {
                throw OCRError.serviceUnavailable
            }

            let decoded = try JSONDecoder().decode(OCRAPIResponse.self, from: data)
            return OCRResult(
                wodType: WODType(rawValue: decoded.wodType) ?? .other,
                wodContent: decoded.wodContent,
                confidence: decoded.confidence
            )
        } catch is DecodingError {
            throw OCRError.parseError
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw OCRError.networkTimeout
            }
            throw OCRError.serviceUnavailable
        }
    }
}

struct PreviewOCRService: OCRServicing {
    func recognize(image: UIImage) async throws -> OCRResult {
        try await Task.sleep(for: .seconds(2))
        return OCRResult(
            wodType: .forTime,
            wodContent: ["21-15-9", "Thruster 43kg", "Pull-up"],
            confidence: 0.92
        )
    }
}

private struct OCRAPIResponse: Codable {
    let wodType: String
    let wodContent: [String]
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case wodType = "wod_type"
        case wodContent = "wod_content"
        case confidence
    }
}

private extension UIImage {
    func compressedJPEGBase64() -> String? {
        let maxEdge: CGFloat = 1024
        let scale = min(1, maxEdge / max(size.width, size.height))
        let resized = UIGraphicsImageRenderer(size: CGSize(width: size.width * scale, height: size.height * scale)).image { _ in
            draw(in: CGRect(origin: .zero, size: CGSize(width: size.width * scale, height: size.height * scale)))
        }
        return resized.jpegData(compressionQuality: 0.8)?.base64EncodedString()
    }
}
