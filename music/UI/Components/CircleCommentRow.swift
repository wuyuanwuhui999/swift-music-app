//
//  CircleCommentRow.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 音乐圈的一条评论（含二级回复，递归渲染）
///
/// 对齐 flutter `MusicCirclePage.buildCircleCommentItems`：
/// 头像 + 昵称（回复时显示「昵称▶被回复人」）+ 内容 + 时间，回复缩进展示。
/// 点内容进入回复该条评论的输入态。
struct CircleCommentRow: View {
    /// 评论数据
    let comment: CircleComment
    /// 点评论内容（用于回复）
    let onReply: (CircleComment) -> Void
    /// 是否是二级回复（决定头像大小与缩进）
    var isReply: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: Dimens.smallMargin) {
            UserAvatar(
                avatar: comment.avater,
                size: isReply ? Dimens.smallAvater : Dimens.middleAvater
            )

            VStack(alignment: .leading, spacing: Dimens.smallMargin) {
                // 昵称（回复别人时展示「谁▶回复谁」）
                Text(nameText)
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.subColor)
                    .lineLimit(1)

                // 内容（点击回复）
                Text(comment.content)
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.blackColor)
                    .contentShape(Rectangle())
                    .onTapGesture { onReply(comment) }

                // 时间（后端偶尔返回 null，空串时整行不占位）
                let time = DateUtils.relativeTime(comment.createTime)
                if !time.isEmpty {
                    Text(time)
                        .font(.system(size: Dimens.normalFont - 3))
                        .foregroundColor(Colors.subColor)
                }

                // 二级回复（递归）
                if comment.hasReplies {
                    VStack(alignment: .leading, spacing: Dimens.smallMargin) {
                        ForEach(comment.replyList ?? []) { reply in
                            CircleCommentRow(comment: reply, onReply: onReply, isReply: true)
                        }
                    }
                    .padding(.leading, Dimens.smallMargin)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Dimens.smallMargin)
    }

    /// 昵称文案：回复别人时「昵称▶被回复人」
    private var nameText: String {
        let name = comment.username ?? ""
        if let replyName = comment.replyUserName, !replyName.isEmpty {
            return "\(name)▶\(replyName)"
        }
        return name
    }
}

#Preview {
    CircleCommentRow(
        comment: CircleComment(
            id: 1,
            content: "这首歌太好听了",
            username: "小明",
            avater: nil,
            createTime: "2026-10-09 20:40:50",
            replyList: [
                CircleComment(
                    id: 2,
                    content: "同感",
                    username: "小红",
                    avater: nil,
                    replyUserName: "小明",
                    createTime: "2026-10-09 21:00:00"
                )
            ]
        ),
        onReply: { _ in }
    )
    .padding()
    .background(Colors.pageBackgroundColor)
}
