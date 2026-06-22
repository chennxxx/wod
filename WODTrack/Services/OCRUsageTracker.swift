import Foundation

/// 免费用户 OCR 拍照识别的每日额度计数器。
/// 免费每**自然日**最多 `freeDailyLimit` 次；Pro 不受限（闸门在调用方按 isPro 短路，不进入本计数）。
/// 真相源是本机 UserDefaults——额度按设备计，跨自然日自动归零。
@Observable
final class OCRUsageTracker {
    /// 免费用户每自然日可识别次数。
    static let freeDailyLimit = 2

    private enum DefaultsKey {
        static let day = "wt.ocr.usageDay"     // yyyy-MM-dd
        static let count = "wt.ocr.usageCount"
    }

    private let defaults: UserDefaults
    private let calendar = Calendar.current

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 今日（自然日）已用次数；跨天自动视为 0。
    var usedToday: Int {
        guard let stored = defaults.string(forKey: DefaultsKey.day),
              stored == Self.todayKey() else {
            return 0
        }
        return defaults.integer(forKey: DefaultsKey.count)
    }

    /// 免费用户今日是否还能识别。
    func canRecognize() -> Bool {
        usedToday < Self.freeDailyLimit
    }

    /// 记一次免费识别（仅在用户主动发起、且非 Pro 时调用；重试不计）。
    func recordUsage() {
        let today = Self.todayKey()
        if defaults.string(forKey: DefaultsKey.day) != today {
            defaults.set(today, forKey: DefaultsKey.day)
            defaults.set(0, forKey: DefaultsKey.count)
        }
        defaults.set(defaults.integer(forKey: DefaultsKey.count) + 1, forKey: DefaultsKey.count)
    }

    private static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
