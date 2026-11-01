//
//  DecodingHelpers.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation

/// 宽容解码工具
///
/// 后端部分字段类型不稳定：bigint 主键 / `total` 之类可能返回数字，也可能返回字符串
/// （例如歌曲接口的 `authorId` 返回 "948359"）。这里统一提供兼容方法，
/// 供 `Music` / `MusicCategory` / `MusicAuthor` 等模型复用，避免每处手写 try? 判断。
extension KeyedDecodingContainer {
    /// 兼容 Int / Double / String 三种返回形式
    func flexibleInt(_ key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return Int(value) }
        if let value = try? decodeIfPresent(String.self, forKey: key) { return Int(value) }
        return nil
    }

    /// 兼容 String / Int 两种返回形式
    func flexibleString(_ key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return String(value) }
        return nil
    }
}
