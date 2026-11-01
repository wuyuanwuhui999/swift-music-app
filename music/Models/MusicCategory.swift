//
//  MusicCategory.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation

/// 音乐分类（首页的一个「模块」）
///
/// 对应 uniapp 的 `MusicCategoryType` / flutter 的 `MusicClassifyModel`，
/// 接口：`GET /service/music/getMusicCategory`（data 为数组）。
///
/// 字段含义（以真实返回为例）：
/// - `category`：模块标题，例如「酷狗飙升榜」
/// - `classify`：模块归类，例如「热门榜单」「特色音乐榜」「全球榜」
/// - `img`：模块封面图
struct MusicCategory: Codable, Identifiable, Equatable {
    var id: Int
    var img: String?
    var category: String
    var classify: String
    var createTime: String?
    var updateTime: String?

    private enum CodingKeys: String, CodingKey {
        case id, img, category, classify, createTime, updateTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        category = c.flexibleString(.category) ?? ""
        classify = c.flexibleString(.classify) ?? ""
        img = c.flexibleString(.img)
        createTime = c.flexibleString(.createTime)
        updateTime = c.flexibleString(.updateTime)
    }

    init(id: Int, category: String, classify: String, img: String? = nil) {
        self.id = id
        self.category = category
        self.classify = classify
        self.img = img
    }

    /// 是否为「推荐歌手」模块（该模块展示歌手头像而不是歌曲列表）
    /// uniapp 判断 `category === '推荐歌手'`，flutter 判断 `classifyName == '推荐歌手'`，
    /// 这里两个字段都判断，避免后端把「推荐歌手」放在 `classify` 里时漏判。
    var isSingerModule: Bool {
        category == "推荐歌手" || classify == "推荐歌手"
    }
}
