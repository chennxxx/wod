import Foundation
import UIKit

actor DoubaoLLMService: OCRServicing {
    static let shared = DoubaoLLMService()

    func recognize(image: UIImage) async throws -> OCRResult {
        guard let base64 = image.compressedBase64() else {
            throw OCRError.invalidImage
        }

        let dataURL = "data:image/jpeg;base64,\(base64)"

        let body: [String: Any] = [
            "model": AppConfig.doubaoModel,
            "stream": true,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "image_url", "image_url": ["url": dataURL]],
                        ["type": "text", "text": "请识别图片中的训练内容，直接输出原文，不要添加任何解释。"]
                    ]
                ]
            ],
            "max_output_tokens": 4096,
            "temperature": 0.2,
            "top_p": 0.95,
            "reasoning": ["effort": "minimal"]
        ]

        var request = URLRequest(url: AppConfig.doubaoAPIURL)
        request.httpMethod = "POST"
        request.timeoutInterval = AppConfig.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppConfig.doubaoAPIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ..< 300).contains(httpResponse.statusCode) else {
            throw OCRError.serviceUnavailable
        }

        var fullText = ""
        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let json = String(line.dropFirst(6))
            guard json != "[DONE]" else { break }
            guard let data = json.data(using: .utf8),
                  let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data),
                  let delta = chunk.choices.first?.delta.content else { continue }
            fullText += delta
        }

        guard !fullText.isEmpty else {
            throw OCRError.parseError
        }

        let lines = fullText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return OCRResult(wodType: .other, wodContent: lines, confidence: 1.0)
    }
}

private struct StreamChunk: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let delta: Delta
    }

    struct Delta: Decodable {
        let content: String?
    }
}

private extension UIImage {
    func compressedBase64() -> String? {
        let maxEdge: CGFloat = 1024
        let scale = min(1, maxEdge / max(size.width, size.height))
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let resized = UIGraphicsImageRenderer(size: targetSize).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.8)?.base64EncodedString()
    }
}
