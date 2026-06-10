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

    /// 卡片图读取：优先本地文件；文件缺失（如 iCloud 同步到新设备）时用 cardImageData
    /// 重建图片并落地回文件，下次直接走文件。
    static func loadCardImage(for record: WODRecord) -> UIImage? {
        if let path = record.cardImagePath, let image = loadImage(from: path) {
            return image
        }
        guard let data = record.cardImageData, let image = UIImage(data: data) else { return nil }

        let filename: String
        if let path = record.cardImagePath {
            filename = URL(fileURLWithPath: resolve(path)).lastPathComponent
        } else {
            filename = "card-\(record.id.uuidString).jpg"
            record.cardImagePath = filename
        }
        try? FileManager.default.createDirectory(at: recordsDirectory, withIntermediateDirectories: true)
        try? data.write(to: recordsDirectory.appendingPathComponent(filename), options: .atomic)
        return image
    }

    static var recordsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WODTrackRecords", isDirectory: true)
    }
}
