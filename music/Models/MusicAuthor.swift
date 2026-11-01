//
//  MusicAuthor.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation

/// 歌手模型
///
/// 对应 uniapp 的 `MusicAuthorType` / flutter 的 `MusicAuthorModel`，
/// 接口：`GET /service/music/getMusicAuthorListByCategoryId`（data 为数组）。
struct MusicAuthor: Codable, Identifiable, Equatable {
    var id: Int
    var authorId: Int?
    var authorName: String
    var avatar: String?
    var country: String?
    var birthday: String?
    var total: Int?          // 歌曲总数（后端可能返回数字或字符串）
    var isLike: Int?         // 是否关注
    var type: Int?
    var identity: Int?
    var rank: Int?
    var categoryId: Int?

    private enum CodingKeys: String, CodingKey {
        case id, authorId, authorName, avatar, country, birthday, total
        case isLike, type, identity, rank, categoryId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        authorId = c.flexibleInt(.authorId)
        total = c.flexibleInt(.total)
        isLike = c.flexibleInt(.isLike)
        type = c.flexibleInt(.type)
        identity = c.flexibleInt(.identity)
        rank = c.flexibleInt(.rank)
        categoryId = c.flexibleInt(.categoryId)
        authorName = c.flexibleString(.authorName) ?? ""
        avatar = c.flexibleString(.avatar)
        country = c.flexibleString(.country)
        birthday = c.flexibleString(.birthday)
    }

    init(id: Int, authorName: String, avatar: String? = nil) {
        self.id = id
        self.authorName = authorName
        self.avatar = avatar
    }

    /// 头像缺失时展示的首字（对齐 uniapp MusicAvaterComponent 的 `{{ name[0] }}`）
    var avatarPlaceholderText: String {
        String(authorName.prefix(1))
    }
}
