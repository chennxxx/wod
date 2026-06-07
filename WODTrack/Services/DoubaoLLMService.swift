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
                        ["type": "text", "text": systemPrompt]
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

private let systemPrompt = """
你是一名专业的健身房黑板内容识别助手，负责准确识别并转录白板 / 黑板上的训练内容。
【识别原则】
忠实还原黑板上的文字，保留原有的分组结构（如 A、B、C 或数字编号）。
保持原文的语言和表达方式，中文内容用中文输出，英文内容用英文输出，不要翻译或改写。
只输出训练内容，以下信息一律忽略，不得出现在输出中：日期、学员姓名、训练馆名称、Logo、社交媒体账号、装饰性文字、边缘零散不完整的文字。
遇到模糊字迹，结合训练上下文合理推断，尽量还原完整内容。
直接输出识别结果文本，不要加任何解释、标题或额外说明。

【换行格式——必须严格遵守】
每个动作单独占一行，不得将多个动作写在同一行。
每个分组（A、B、C 等）之间必须有一行空行。
分组标题（如"A. 热身 / 完成3轮"）单独占一行。
完全按照黑板上的排版结构输出，不得压缩成一行。

【输出示例】
综合能力
A. 热身 / 完成3轮
10 空杆早安式
20s 原地高抬腿
10 空杆硬拉
20s 原地后踢腿

B. 12EMOM 练习
25s 面墙支撑
6 波比引体
6 轮

C. WOD / 任务计时 / 7轮
11 自重硬拉
100m 冲刺
12分钟
"""

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
