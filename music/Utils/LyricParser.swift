//
//  LyricParser.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation

/// 一行歌词
struct LyricLine: Identifiable, Equatable {
    /// 行号（解析顺序，作为列表 id）
    let id: Int
    /// 该行开始时间（秒）
    let time: Double
    /// 歌词文本
    let text: String
}

/// LRC 歌词解析
///
/// 后端返回的歌词是 LRC 文本（`[mm:ss.xx]内容`），开头常带 `[ti:]`、`[ar:]`、`[id:]` 等标签，
/// 且行尾是 `\r\n`。对应 uniapp 的 `lyric-parser`、flutter 的 `LyricsReader`。
enum LyricParser {

    /// 解析 LRC 文本
    /// - Parameter lrc: 歌词原文
    /// - Returns: 按时间升序排好的歌词行；没有有效歌词时返回空数组
    static func parse(_ lrc: String?) -> [LyricLine] {
        guard let lrc = lrc, !lrc.isEmpty else { return [] }

        var lines: [(time: Double, text: String)] = []

        for rawLine in lrc.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            // 一行可能有多个时间标签：[00:12.34][01:20.00]歌词
            var times: [Double] = []
            var rest = line
            while rest.hasPrefix("["), let end = rest.firstIndex(of: "]") {
                let tag = String(rest[rest.index(after: rest.startIndex)..<end])
                if let seconds = parseTimeTag(tag) {
                    times.append(seconds)
                }
                rest = String(rest[rest.index(after: end)...])
            }

            let text = rest.trimmingCharacters(in: .whitespaces)
            guard !times.isEmpty, !text.isEmpty else { continue }
            for time in times {
                lines.append((time, text))
            }
        }

        return lines
            .sorted { $0.time < $1.time }
            .enumerated()
            .map { LyricLine(id: $0.offset, time: $0.element.time, text: $0.element.text) }
    }

    /// 当前播放位置对应的歌词行下标
    /// - Parameters:
    ///   - lines: 歌词行
    ///   - position: 当前播放秒数
    /// - Returns: 命中的行下标；还没有到第一行时返回 nil
    static func currentIndex(in lines: [LyricLine], position: Double) -> Int? {
        guard !lines.isEmpty else { return nil }
        var result: Int?
        for (index, line) in lines.enumerated() {
            if line.time <= position {
                result = index
            } else {
                break
            }
        }
        return result
    }

    /// 解析 `mm:ss` / `mm:ss.xx` / `mm:ss.xxx` 时间标签，非法标签（如 `ti`、`ar`）返回 nil
    private static func parseTimeTag(_ tag: String) -> Double? {
        let parts = tag.split(separator: ":")
        guard parts.count == 2,
              let minutes = Double(parts[0]) else { return nil }

        let secondPart = parts[1].replacingOccurrences(of: "：", with: ":")
        let segments = secondPart.split(separator: ".")
        guard let seconds = Double(segments[0]) else { return nil }

        var milliseconds: Double = 0
        if segments.count > 1 {
            // 两位是厘秒（0.01 秒），三位是毫秒
            let fraction = String(segments[1])
            if let value = Double(fraction) {
                milliseconds = value / pow(10, Double(fraction.count))
            }
        }
        return minutes * 60 + seconds + milliseconds
    }
}
