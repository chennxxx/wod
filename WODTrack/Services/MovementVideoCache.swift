import Foundation

/// 动作示范视频的本地缓存与下载管理。
///
/// 设计：首次播放时从 CDN 下载整段 MP4 到 `Caches/MovementVideos/{id}.mp4`，
/// 之后直接返回本地文件 —— 再次进入秒开、且离线可用。短片（5~8 秒、约 1MB）
/// 下完整文件再播能保证循环顺滑；后期 1 分钟教学视频同样适用。
///
/// 缓存放在 `Caches` 目录：不进 iCloud 备份，系统空间紧张时可被自动回收；
/// 另设 LRU 容量上限，超限时按最近访问时间淘汰最旧文件。
actor MovementVideoCache {
    static let shared = MovementVideoCache()

    private let fileManager = FileManager.default
    /// 本地缓存容量上限（超出后淘汰最旧文件）。
    private let maxCacheBytes: Int64 = 800 * 1024 * 1024
    /// 合并同一动作的并发下载请求，避免重复下载。
    private var inFlight: [String: Task<URL?, Never>] = [:]

    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MovementVideos", isDirectory: true)
    }

    /// 返回可播放的本地文件 URL；本地无缓存时先下载。下载失败 / 无网时返回 `nil`，
    /// 由调用方回退到占位符。
    func localURL(for skillId: String) async -> URL? {
        let fileURL = cacheDirectory.appendingPathComponent("\(skillId).mp4")

        if fileManager.fileExists(atPath: fileURL.path) {
            touch(fileURL) // 更新访问时间，用于 LRU
            return fileURL
        }

        if let task = inFlight[skillId] {
            return await task.value
        }
        let task = Task<URL?, Never> { await download(skillId: skillId, to: fileURL) }
        inFlight[skillId] = task
        let result = await task.value
        inFlight[skillId] = nil
        return result
    }

    // MARK: - Private

    private func download(skillId: String, to fileURL: URL) async -> URL? {
        guard let remote = AppConfig.movementVideoURL(for: skillId) else { return nil }
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            let (tmpURL, response) = try await URLSession.shared.download(from: remote)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            if fileManager.fileExists(atPath: fileURL.path) {
                try? fileManager.removeItem(at: fileURL)
            }
            try fileManager.moveItem(at: tmpURL, to: fileURL)
            enforceCacheLimit()
            return fileURL
        } catch {
            return nil
        }
    }

    /// 把文件修改时间更新为现在，作为「最近访问时间」供 LRU 淘汰参考。
    private func touch(_ url: URL) {
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
    }

    /// 超过容量上限时，按最近访问时间从旧到新删除，直到回到上限以内。
    private func enforceCacheLimit() {
        let keys: Set<URLResourceKey> = [.fileSizeKey, .contentModificationDateKey]
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory, includingPropertiesForKeys: Array(keys)
        ) else { return }

        var infos: [(url: URL, size: Int64, date: Date)] = []
        var total: Int64 = 0
        for url in files {
            let v = try? url.resourceValues(forKeys: keys)
            let size = Int64(v?.fileSize ?? 0)
            let date = v?.contentModificationDate ?? .distantPast
            infos.append((url, size, date))
            total += size
        }

        guard total > maxCacheBytes else { return }
        for info in infos.sorted(by: { $0.date < $1.date }) {
            if total <= maxCacheBytes { break }
            try? fileManager.removeItem(at: info.url)
            total -= info.size
        }
    }
}
