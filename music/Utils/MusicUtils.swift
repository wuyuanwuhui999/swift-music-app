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
            let resolved = cover.replacingOccurrences(of: "{size}", with: "480")
            return upgradeToHTTPS(resolved)
        }
        return Constants.baseURL + cover
    }

    /// 外链图片统一升级成 https
    ///
    /// iOS 的 ATS 默认禁止 http 明文请求（本地 127.0.0.1 / localhost 例外），
    /// 而后端返回的第三方封面、歌手头像经常是 `http://`（如 singerimg.kugou.com），
    /// 不升级会加载失败、只能落到默认图。
    private static func upgradeToHTTPS(_ url: String) -> String {
        guard url.hasPrefix("http://") else { return url }
        // 本地后端保持 http，避免 https 握手失败
        if url.hasPrefix("http://127.0.0.1") || url.hasPrefix("http://localhost") {
            return url
        }
        return "https://" + url.dropFirst("http://".count)
    }

    /// 时长（秒）格式化成 mm:ss
    static func formatDuration(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }
        let total = Int(seconds.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
