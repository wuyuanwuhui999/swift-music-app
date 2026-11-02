//
//  FavoriteDirectory.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation

/// 音乐收藏夹
///
/// 对应 uniapp `FavoriteDirectoryType` / flutter `FavoriteDirectoryModel`，
/// 接口：`GET /service/music/getFavoriteDirectory?musicId=`
struct FavoriteDirectory: Codable, Equatable, Identifiable {
    var id: Int
    /// 收藏夹名称
    var name: String
    /// 里面的歌曲数
    var total: Int?
    /// 当前歌曲是否已在这个收藏夹里（1 = 已收藏）
    var checked: Int?
    /// 收藏夹封面
    var cover: String?
    var createTime: String?
    var updateTime: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, total, checked, cover, createTime, updateTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        total = c.flexibleInt(.total)
        checked = c.flexibleInt(.checked)
        name = c.flexibleString(.name) ?? ""
        cover = c.flexibleString(.cover)
        createTime = c.flexibleString(.createTime)
        updateTime = c.flexibleString(.updateTime)
    }

    init(id: Int = 0, name: String, total: Int? = 0, cover: String? = nil, checked: Int? = 0) {
        self.id = id
        self.name = name
        self.total = total
        self.cover = cover
        self.checked = checked
    }

    /// 没有封面时用名称首字兜底
    var placeholderText: String {
        String(name.prefix(1))
    }
}
