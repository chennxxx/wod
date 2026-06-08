import UIKit

enum ImagePathResolver {
    /// 解析存储的路径字符串，兼容旧格式（绝对路径）和新格式（文件名）。
    static func resolve(_ stored: String) -> String {
        guard !stored.isEmpty else { return stored }

        // 新格式：只有文件名，直接拼接当前容器路径
        if !stored.hasPrefix("/") {
            return recordsDirectory.appendingPathComponent(stored).path
        }

        // 旧格式（绝对路径）：文件仍存在则直接使用
        if FileManager.default.fileExists(atPath: stored) {
            return stored
        }

        // 旧格式但容器 UUID 已变（Xcode 重装场景）：提取文件名重新定位
        let filename = URL(fileURLWithPath: stored).lastPathComponent
        return recordsDirectory.appendingPathComponent(filename).path
    }

    static func loadImage(from stored: String) -> UIImage? {
        UIImage(contentsOfFile: resolve(stored))
    }

    private static var recordsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WODTrackRecords", isDirectory: true)
    }
}
