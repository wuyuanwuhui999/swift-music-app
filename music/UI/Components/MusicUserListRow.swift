//
//  MusicUserListRow.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 「我的」页通用列表行
///
/// 收藏夹 / 我喜欢的歌曲 / 我关注的歌手 / 播放记录 四种列表结构一致：
/// 圆形封面（无封面用首字兜底）+ 标题 + 副标题 + 右侧操作图标（播放 / 删除 / 菜单）。
struct MusicUserListRow: View {
    /// 封面地址（可为空，空时展示 favatarText 首字）
    let cover: String?
    /// 封面兜底文字（取名称首字）
    let fallbackText: String
    /// 主标题
    let title: String
    /// 副标题（「N首」/「听过N次」等）
    var subtitle: String?

    /// 是否显示删除图标（播放记录行有，对齐 flutter）
    var showsDelete: Bool = false
    /// 点播放
    var onPlay: (() -> Void)?
    /// 点删除
    var onDelete: (() -> Void)?
    /// 点更多菜单
    var onMenu: (() -> Void)?
    /// 长按（用于删除 / 取消关注，替代 flutter 的左滑删除）
    var onLongPress: (() -> Void)?

    var body: some View {
        HStack(spacing: Dimens.middleMargin) {
            coverView

            VStack(alignment: .leading, spacing: Dimens.smallMargin) {
                Text(title)
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.blackColor)
                    .lineLimit(1)

                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.subColor)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let onPlay = onPlay {
                iconButton("icon_music_play", action: onPlay)
            }

            if showsDelete, let onDelete = onDelete {
                iconButton("icon_delete", action: onDelete)
            }

            if let onMenu = onMenu {
                iconButton("icon_music_menu", action: onMenu)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onPlay?() }
        .contextMenu {
            if let onLongPress = onLongPress {
                Button(role: .destructive, action: onLongPress) {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - 子视图

    /// 圆形封面（有图用图，没图用首字兜底）
    private var coverView: some View {
        ZStack {
            Colors.pageBackgroundColor

            if let urlString = MusicUtils.coverURL(cover), let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        placeholderText
                    @unknown default:
                        placeholderText
                    }
                }
            } else {
                placeholderText
            }
        }
        .frame(width: Dimens.musicCover, height: Dimens.musicCover)
        .clipShape(Circle())
    }

    /// 首字兜底
    private var placeholderText: some View {
        Text(fallbackText)
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.subColor)
    }

    /// 右侧小图标按钮
    private func iconButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.musicRowIcon, height: Dimens.musicRowIcon)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Dimens.middleMargin) {
        MusicUserListRow(
            cover: nil,
            fallbackText: "车",
            title: "车载音乐",
            subtitle: "2首",
            onPlay: {}, onMenu: {}, onLongPress: {}
        )
        MusicUserListRow(
            cover: nil,
            fallbackText: "黄",
            title: "黄昏",
            subtitle: "听过 3 次",
            showsDelete: true,
            onPlay: {}, onDelete: {}, onMenu: {}
        )
    }
    .padding()
    .background(Colors.whiteColor)
}
