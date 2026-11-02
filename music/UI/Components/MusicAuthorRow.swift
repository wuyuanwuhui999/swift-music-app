//
//  MusicAuthorRow.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 歌手列表行（歌手分类页使用）
///
/// 对齐 flutter `MusicAuthorCategoryPage.buildAuthorListWidget`：
/// 圆形头像 + 歌手名 + 「N首」+ 播放图标 + 关注图标 + 菜单图标；整行可点进歌手歌曲列表。
struct MusicAuthorRow: View {
    /// 歌手
    let author: MusicAuthor
    /// 点整行（进歌手歌曲列表）
    let onTap: () -> Void
    /// 点关注 / 取消关注
    let onLike: () -> Void
    /// 点更多菜单
    var onMenu: () -> Void = {}

    var body: some View {
        HStack(spacing: Dimens.middleMargin) {
            MusicAuthorAvatarView(author: author, size: Dimens.middleAvater)

            VStack(alignment: .leading, spacing: Dimens.smallMargin) {
                Text(author.authorName)
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.blackColor)
                    .lineLimit(1)

                Text("\(author.total ?? 0)首")
                    .font(.system(size: Dimens.normalFont))
                    .fontWeight(.bold)
                    .foregroundColor(Colors.grayColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 播放（进歌手歌曲列表）
            Button(action: onTap) {
                Image("icon_music_play")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
            }
            .buttonStyle(.plain)

            // 关注 / 取消关注
            Button(action: onLike) {
                Image((author.isLike ?? 0) == 1 ? "icon_like_active" : "icon_like")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
            }
            .buttonStyle(.plain)

            // 更多菜单
            Button(action: onMenu) {
                Image("icon_music_menu")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    MusicAuthorRow(
        author: MusicAuthor(id: 154, authorName: "程响"),
        onTap: {},
        onLike: {}
    )
    .padding()
    .background(Colors.whiteColor)
}
