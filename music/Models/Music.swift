//
//  Music.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation

/// 歌曲模型
/// 字段与 uniapp 版本的 `MusicType`、flutter 版本的 `MusicModel` 一一对应；
/// 后端返回的 snake_case 字段已由 `ResultUtil` 自动转成驼峰，这里直接用驼峰即可。
struct Music: Codable, Identifiable, Equatable {
    var id: Int                    // 主键
    var albumId: Int?              // 专辑 id
    var songName: String           // 歌曲名称
    var authorName: String         // 歌手名称
    var authorId: Int?             // 歌手 id
    var albumName: String?         // 专辑名称
    var version: String?           // 版本
    var language: String?          // 语言
    var publishDate: String?       // 发布时间
    var audioId: Int?              // 音频 id
    var albumAudioId: Int?         // 音频专辑 id
    var audioGroupId: Int?         // 歌曲组 id
    var isHot: Int?                // 是否热门
    var cover: String              // 歌曲图片
    var playUrl: String?           // 网络播放地址
    var localPlayUrl: String?      // 本地播放地址
    var sourceName: String?        // 歌曲来源
    var sourceUrl: String?         // 来源地址
    var createTime: String?        // 创建时间
    var updateTime: String?        // 更新时间
    var label: String?             // 标签
    var lyrics: String?            // 歌词
    var isLike: Int?               // 是否喜欢
    var isFavorite: Int?           // 是否收藏
    var times: Int?                // 听过的次数（播放记录接口才返回）

    /// 歌手展示名（为空时兜底为「未知歌手」）
    var displayAuthorName: String {
        authorName.isEmpty ? "未知歌手" : authorName
    }

    /// 专辑展示名（为空时兜底为「未知专辑」）
    var displayAlbumName: String {
        guard let albumName = albumName, !albumName.isEmpty else { return "未知专辑" }
        return albumName
    }

    // MARK: - 解码

    private enum CodingKeys: String, CodingKey {
        case id, albumId, songName, authorName, authorId, albumName, version, language
        case publishDate, audioId, albumAudioId, audioGroupId, isHot, cover, playUrl
        case localPlayUrl, sourceName, sourceUrl, createTime, updateTime, label, lyrics
        case isLike, isFavorite, times
    }

    /// 自定义解码：后端部分数值字段（bigint 主键等）可能返回字符串，这里统一做兼容处理
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        albumId = c.flexibleInt(.albumId)
        authorId = c.flexibleInt(.authorId)
        audioId = c.flexibleInt(.audioId)
        albumAudioId = c.flexibleInt(.albumAudioId)
        audioGroupId = c.flexibleInt(.audioGroupId)
        isHot = c.flexibleInt(.isHot)
        isLike = c.flexibleInt(.isLike)
        isFavorite = c.flexibleInt(.isFavorite)
        times = c.flexibleInt(.times)
        songName = c.flexibleString(.songName) ?? ""
        authorName = c.flexibleString(.authorName) ?? ""
        cover = c.flexibleString(.cover) ?? ""
        albumName = c.flexibleString(.albumName)
        version = c.flexibleString(.version)
        language = c.flexibleString(.language)
        publishDate = c.flexibleString(.publishDate)
        playUrl = c.flexibleString(.playUrl)
        localPlayUrl = c.flexibleString(.localPlayUrl)
        sourceName = c.flexibleString(.sourceName)
        sourceUrl = c.flexibleString(.sourceUrl)
        createTime = c.flexibleString(.createTime)
        updateTime = c.flexibleString(.updateTime)
        label = c.flexibleString(.label)
        lyrics = c.flexibleString(.lyrics)
    }

    /// 手动构造（预览、本地缓存兜底等场景使用）
    init(id: Int, songName: String, authorName: String, cover: String,
         albumId: Int? = nil, albumName: String? = nil, playUrl: String? = nil,
         lyrics: String? = nil, isLike: Int? = nil) {
        self.id = id
        self.songName = songName
        self.authorName = authorName
        self.cover = cover
        self.albumId = albumId
        self.albumName = albumName
        self.playUrl = playUrl
        self.lyrics = lyrics
        self.isLike = isLike
    }
}

// MARK: - 数值 / 字符串兼容解码
private extension KeyedDecodingContainer {
    /// 兼容 Int / String / Double 三种返回形式
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
