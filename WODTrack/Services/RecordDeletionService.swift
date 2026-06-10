import Foundation
import SwiftData

enum RecordDeletionService {
    /// 删除记录及其关联的图片文件（合成卡片 + 旧版本遗留的训练原图）。
    static func delete(_ record: WODRecord, context: ModelContext) {
        if let cardPath = record.cardImagePath {
            removeFile(cardPath)
        }
        for photoPath in record.checkinPhotoURLs {
            removeFile(photoPath)
        }
        context.delete(record)
        try? context.save()
    }

    private static func removeFile(_ stored: String) {
        let path = ImagePathResolver.resolve(stored)
        try? FileManager.default.removeItem(atPath: path)
    }
}
