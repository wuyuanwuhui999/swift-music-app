//
//  MusicCircle.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation

/// 点赞记录
///
/// 对应 uniapp `LikeType` / flutter `CircleLikeModel`，
/// 接口：`POST /service/social/saveLike`、`DELETE /service/social/deleteLike`。
struct CircleLike: Codable, Equatable, Identifiable {
    var id: Int?
    var type: String?
    var relationId: Int?
    var userId: String?
    var username: String?
    var createTime: String?
    var updateTime: String?

    private enum CodingKeys: String, CodingKey {
        case id, type, relationId, userId, username, createTime, updateTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id)
        relationId = c.flexibleInt(.relationId)
        type = c.flexibleString(.type)
        userId = c.flexibleString(.userId)
        username = c.flexibleString(.username)
        createTime = c.flexibleString(.createTime)
        updateTime = c.flexibleString(.updateTime)
    }

    init(id: Int? = nil, type: String? = nil, relationId: Int? = nil,
         userId: String? = nil, username: String? = nil) {
        self.id = id
        self.type = type
        self.relationId = relationId
        self.userId = userId
        self.username = username
    }
}

/// 评论（支持二级回复：一条一级评论的 `replyList` 里是它的回复）
///
/// 对应 uniapp `CommentType` / flutter `CommentModel`。
struct CircleComment: Codable, Equatable, Identifiable {
    var id: Int
    var content: String
    var parentId: Int?
    var topId: Int?
    var relationId: Int?
    var type: String?
    var userId: String?
    var username: String?
    var avater: String?
    var replyUserId: String?
    var replyUserName: String?
    var createTime: String?
    var replyCount: Int?
    var replyList: [CircleComment]?

    private enum CodingKeys: String, CodingKey {
        case id, content, parentId, topId, relationId, type, userId, username
        case avater, replyUserId, replyUserName, createTime, replyCount, replyList
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        parentId = c.flexibleInt(.parentId)
        topId = c.flexibleInt(.topId)
        relationId = c.flexibleInt(.relationId)
        replyCount = c.flexibleInt(.replyCount)
        content = c.flexibleString(.content) ?? ""
        type = c.flexibleString(.type)
        userId = c.flexibleString(.userId)
        username = c.flexibleString(.username)
        avater = c.flexibleString(.avater)
        replyUserId = c.flexibleString(.replyUserId)
        replyUserName = c.flexibleString(.replyUserName)
        createTime = c.flexibleString(.createTime)
        replyList = try? c.decodeIfPresent([CircleComment].self, forKey: .replyList)
    }

    init(id: Int, content: String, username: String?, avater: String?,
         topId: Int? = nil, parentId: Int? = nil, replyUserName: String? = nil,
         createTime: String? = nil, replyList: [CircleComment]? = nil) {
        self.id = id
        self.content = content
        self.username = username
        self.avater = avater
        self.topId = topId
        self.parentId = parentId
        self.replyUserName = replyUserName
        self.createTime = createTime
        self.replyList = replyList
    }

    /// 是否有回复
    var hasReplies: Bool {
        !(replyList ?? []).isEmpty
    }
}

/// 音乐圈动态
///
/// 对应 uniapp `CircleType` / flutter `CircleModel`，
/// 接口：`GET /service/circle/getCircleListByType?type=MUSIC&pageNum=&pageSize=`。
struct MusicCircle: Codable, Equatable, Identifiable {
    var id: Int
    /// 分享的文字内容
    var content: String
    /// 发布者昵称 / 头像（后端字段名就是 useravater）
    var username: String?
    var useravater: String?
    var userId: String?
    var createTime: String?
    var type: String?

    // 分享的歌曲信息
    var musicSongName: String?
    var musicAuthorName: String?
    var musicCover: String?
    var musicPlayUrl: String?
    var musicLocalPlayUrl: String?
    var musicLyrics: String?
    var musicAudioId: String?

    /// 点赞列表
    var circleLikes: [CircleLike]?
    /// 评论列表（一级评论，回复在 `replyList` 里）
    var circleComments: [CircleComment]?

    private enum CodingKeys: String, CodingKey {
        case id, content, username, useravater, userId, createTime, type
        case musicSongName, musicAuthorName, musicCover, musicPlayUrl
        case musicLocalPlayUrl, musicLyrics, musicAudioId
        case circleLikes, circleComments
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id) ?? 0
        content = c.flexibleString(.content) ?? ""
        username = c.flexibleString(.username)
        useravater = c.flexibleString(.useravater)
        userId = c.flexibleString(.userId)
        createTime = c.flexibleString(.createTime)
        type = c.flexibleString(.type)
        musicSongName = c.flexibleString(.musicSongName)
        musicAuthorName = c.flexibleString(.musicAuthorName)
        musicCover = c.flexibleString(.musicCover)
        musicPlayUrl = c.flexibleString(.musicPlayUrl)
        musicLocalPlayUrl = c.flexibleString(.musicLocalPlayUrl)
        musicLyrics = c.flexibleString(.musicLyrics)
        musicAudioId = c.flexibleString(.musicAudioId)
        circleLikes = try? c.decodeIfPresent([CircleLike].self, forKey: .circleLikes)
        circleComments = try? c.decodeIfPresent([CircleComment].self, forKey: .circleComments)
    }

    /// 手动构造（发布成功后本地置顶展示用）
    init(
        id: Int,
        content: String,
        username: String? = nil,
        useravater: String? = nil,
        userId: String? = nil,
        createTime: String? = nil,
        type: String? = nil,
        musicSongName: String? = nil,
        musicAuthorName: String? = nil,
        musicCover: String? = nil,
        musicPlayUrl: String? = nil,
        musicLocalPlayUrl: String? = nil,
        circleLikes: [CircleLike]? = [],
        circleComments: [CircleComment]? = []
    ) {
        self.id = id
        self.content = content
        self.username = username
        self.useravater = useravater
        self.userId = userId
        self.createTime = createTime
        self.type = type
        self.musicSongName = musicSongName
        self.musicAuthorName = musicAuthorName
        self.musicCover = musicCover
        self.musicPlayUrl = musicPlayUrl
        self.musicLocalPlayUrl = musicLocalPlayUrl
        self.circleLikes = circleLikes
        self.circleComments = circleComments
    }

    /// 点赞用户昵称拼成的文案（uniapp 用「、」连接）
    var likeUserNames: String {
        (circleLikes ?? []).compactMap { $0.username }.joined(separator: "、")
    }

    /// 是否分享的是歌曲（有封面或有歌名）
    var hasMusic: Bool {
        !(musicCover ?? "").isEmpty || !(musicSongName ?? "").isEmpty
    }

    /// 歌曲展示文案「歌名 - 歌手」
    var musicTitle: String {
        let song = musicSongName ?? ""
        let author = musicAuthorName ?? ""
        if song.isEmpty { return author }
        if author.isEmpty { return song }
        return "\(song) - \(author)"
    }
}
