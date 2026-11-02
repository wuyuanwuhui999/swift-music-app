//
//  MusicAuthorCategory.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation

/// 歌手分类（华语 / 华语男歌手 / 欧美组合 …）
///
/// 对应 uniapp `MusicAuthorCategoryType` / flutter `MusicAuthorCategoryModel`，
/// 接口：`GET /service/music/getMusicAuthorCategory`（data 为数组）。
struct MusicAuthorCategory: Codable, Identifiable, Equatable {
    var id: Int
    /// 分类名称，例如「华语男歌手」
    var categoryName: String
    /// 排序
    var rank: Int?
    /// 是否禁用（0 为启用）
    var disabled: Int?
    var createTime: String?
    var updateTime: String?

    private enum CodingKeys: String, CodingKey {
        case id, categoryName, rank, disabled, createTime, updateTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        rank = c.flexibleInt(.rank)
        disabled = c.flexibleInt(.disabled)
        categoryName = c.flexibleString(.categoryName) ?? ""
        createTime = c.flexibleString(.createTime)
        updateTime = c.flexibleString(.updateTime)
    }

    init(id: Int, categoryName: String) {
        self.id = id
        self.categoryName = categoryName
    }
}
