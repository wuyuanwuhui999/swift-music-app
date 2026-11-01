//
//  MusicUtils.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation

/// 音乐相关的工具方法（与 uniapp 版本 `src/utils/util.ts` 对齐）
enum MusicUtils {
    /// 把后端返回的封面地址拼成可直接加载的完整 URL
    /// - 已经是 http/https 全地址：把 `{size}` 占位符替换成 480 后返回（支持 CDN 图片尺寸协议）
    /// - 相对路径：拼上 `Constants.baseURL`
    static func coverURL(_ cover: String?) -> String? {
        guard let cover = cover, !cover.isEmpty else { return nil }
        if cover.hasPrefix("http://") || cover.hasPrefix("https://") {
            return cover.replacingOccurrences(of: "{size}", with: "480")
        }
        return Constants.baseURL + cover
    }

    /// 时长（秒）格式化成 mm:ss
    static func formatDuration(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }
        let total = Int(seconds.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
