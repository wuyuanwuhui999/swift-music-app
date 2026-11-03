//
//  MusicCircleCard.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 音乐圈单条动态卡片
///
/// 对齐 flutter `MusicCirclePage.buildCircleList` 与 uniapp `MusicCircleComponent`：
/// 头像 + 昵称（蓝色加粗）+ 内容 + 分享的歌曲条 + 时间/操作菜单 + 点赞与评论区。
struct MusicCircleCard: View {
    /// 动态数据
    let circle: MusicCircle
    /// 当前登录用户 id（判断是否已点赞）
    let currentUserId: String?
    /// 操作菜单是否展开
    let isMenuOpen: Bool

    /// 点菜单图标
    let onMenuTap: () -> Void
    /// 点赞 / 取消点赞
    let onLike: () -> Void
    /// 评论（打开输入框）
    let onComment: () -> Void
    /// 回复某条评论
    let onReply: (CircleComment) -> Void

    /// 卡片是否展开操作菜单（用于抬高层级，避免被下一张卡片盖住）
    var body: some View {
        HStack(alignment: .top, spacing: Dimens.middleMargin) {
            // 头像
            UserAvatar(avatar: circle.useravater, size: Dimens.middleAvater)

            VStack(alignment: .leading, spacing: Dimens.middleMargin) {
                // 昵称
                Text(circle.username ?? "")
                    .font(.system(size: Dimens.normalFont))
                    .fontWeight(.bold)
                    .foregroundColor(Colors.blueColor)

                // 内容
                if !circle.content.isEmpty {
                    Text(circle.content)
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.blackColor)
                        .lineLimit(5)
                }

                // 分享的歌曲
                if circle.hasMusic {
                    musicBar
                }

                // 时间 + 操作菜单
                HStack(spacing: Dimens.smallMargin) {
                    Text(DateUtils.relativeTime(circle.createTime))
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.grayColor)

                    Spacer(minLength: 0)

                    menuButton
                }

                // 点赞 / 评论区
                socialBlock
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    // MARK: - 子视图

    /// 分享的歌曲条：封面 + 「歌名 - 歌手」+ 播放图标
    private var musicBar: some View {
        HStack(spacing: Dimens.middleMargin) {
            MusicCoverView(cover: circle.musicCover, size: Dimens.musicCover)

            Text(circle.musicTitle)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image("icon_music_play")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.musicRowIcon, height: Dimens.musicRowIcon)
        }
        .padding(Dimens.smallMargin)
        .background(Colors.pageBackgroundColor)
        .cornerRadius(Dimens.musicCover / 2)
    }

    /// 更多菜单按钮（点开「赞 / 评论」气泡）
    private var menuButton: some View {
        Button(action: onMenuTap) {
            Image("icon_music_menu")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.musicRowIcon, height: Dimens.musicRowIcon)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottomTrailing) {
            if isMenuOpen {
                actionMenu
                    .offset(x: Dimens.musicRowIcon / 2, y: -Dimens.musicRowIcon - Dimens.smallMargin)
            }
        }
    }

    /// 「赞 / 评论」气泡菜单（对齐 flutter buildMenu）
    private var actionMenu: some View {
        HStack(spacing: 0) {
            Button(action: onLike) {
                HStack(spacing: Dimens.smallMargin) {
                    Image("icon_like_white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
                    Text(isLiked ? "取消赞" : "赞")
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.whiteColor)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onComment) {
                HStack(spacing: Dimens.smallMargin) {
                    Image("icon_comment_white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
                    Text("评论")
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.whiteColor)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: Dimens.circleActionMenuWidth, height: Dimens.circleActionMenuHeight)
        .background(Colors.subColor)
        .cornerRadius(Dimens.borderRadius)
    }

    /// 点赞 + 评论列表区
    @ViewBuilder
    private var socialBlock: some View {
        let likes = circle.circleLikes ?? []
        let comments = circle.circleComments ?? []

        if !likes.isEmpty || !comments.isEmpty {
            VStack(alignment: .leading, spacing: Dimens.smallMargin) {
                // 点赞用户
                if !likes.isEmpty {
                    HStack(alignment: .top, spacing: Dimens.smallMargin) {
                        Image("icon_music_like")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)

                        Text(circle.likeUserNames)
                            .font(.system(size: Dimens.normalFont))
                            .foregroundColor(Colors.blueColor)
                            .lineLimit(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // 一级评论（回复在内部递归）
                ForEach(comments) { comment in
                    CircleCommentRow(comment: comment, onReply: onReply)
                }
            }
            .padding(Dimens.smallMargin)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Colors.pageBackgroundColor)
            .cornerRadius(Dimens.borderRadius)
        }
    }

    /// 当前用户是否已点赞
    private var isLiked: Bool {
        (circle.circleLikes ?? []).contains { $0.userId == currentUserId }
    }
}

#Preview {
    MusicCircleCard(
        circle: {
            let json = """
            {"id":87,"content":"分享一首好歌","username":"用户昵称","useravater":null,
             "createTime":"2026-10-09 20:40:50","type":"MUSIC",
             "musicSongName":"笑傲江湖","musicAuthorName":"刘欢、王菲","musicCover":null,
             "circleLikes":[{"id":1,"userId":"u1","username":"小明"}],
             "circleComments":[{"id":2,"content":"好听","username":"小红","createTime":"2026-10-09 21:00:00","replyList":[]}]}
            """
            return try! JSONDecoder().decode(MusicCircle.self, from: Data(json.utf8))
        }(),
        currentUserId: "u1",
        isMenuOpen: false,
        onMenuTap: {}, onLike: {}, onComment: {}, onReply: { _ in }
    )
    .padding()
    .background(Colors.pageBackgroundColor)
}
