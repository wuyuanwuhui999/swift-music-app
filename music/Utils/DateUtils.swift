//
//  DateUtils.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation

/// 时间格式化工具（对齐 uniapp `src/utils/util.ts` 的 `formatTime`）
enum DateUtils {

    /// 后端常见的时间格式（依次尝试）
    private static let inputFormats = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
        "yyyy-MM-dd"
    ]

    /// 把后端时间字符串转成「刚刚 / N分前 / N小时前 / N天前 / N个月前 / 完整时间」
    /// - Parameter value: 后端返回的时间字符串，为空时返回空字符串
    static func relativeTime(_ value: String?) -> String {
        guard let value = value, !value.isEmpty, let date = parse(value) else { return "" }

        let now = Date()
        let diff = now.timeIntervalSince(date)

        switch diff {
        case ..<60:
            return "刚刚"
        case 60..<3600:
            return "\(Int(ceil(diff / 60)))分前"
        case 3600..<86400:
            return "\(Int(ceil(diff / 3600)))小时前"
        case 86400..<(86400 * 30):
            return "\(Int(ceil(diff / 86400)))天前"
        case (86400 * 30)..<(86400 * 30 * 12):
            return "\(Int(ceil(diff / (86400 * 30))))个月前"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: date)
        }
    }

    /// 当前时间的后端格式字符串（发布动态后本地置顶展示用）
    static func nowString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }

    /// 解析后端时间字符串
    private static func parse(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        for format in inputFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }
}
