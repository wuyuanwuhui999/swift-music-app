//
//  MusicRankRow.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 带名次的歌曲行（推荐页使用）
///
/// 对齐 uniapp `MusicRecommentComponent` 的 `.music-item` / flutter `buildMusicItem`：
/// 名次（前三名用奖牌图标，其余用数字）+ 封面 + 歌名/歌手 + 播放状态 + 喜欢 + 更多菜单，
/// 每一行本身是一张白色卡片。
struct MusicRankRow: View {
    /// 歌曲
    let music: Music
    /// 名次下标（从 0 开始）
    let index: Int
    /// 所属模块名（用于判断「当前播放的是否是本列表的歌」）
    let classifyName: String

    /// 点播放（行点击也是播放）
    let onPlay: () -> Void
    /// 点喜欢
    let onLike: () -> Void
    /// 点更多菜单
    let onMenu: () -> Void

    @ObservedObject private var playerState = PlayerState.shared

    var body: some View {
        HStack(spacing: Dimens.middleMargin) {
            // 名次：前三名奖牌图标，其余数字
            rankView
                .frame(width: Dimens.musicRowIcon, height: Dimens.musicRowIcon)

            MusicCoverView(cover: music.cover, size: Dimens.musicCover)

            // 歌名 + 歌手
            VStack(alignment: .leading, spacing: Dimens.smallMargin) {
                Text(music.songName)
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.blackColor)
                    .lineLimit(1)

                Text(music.displayAuthorName)
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.grayColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 播放 / 播放中
            Button(action: onPlay) {
                Image(playIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.musicRowIcon, height: Dimens.musicRowIcon)
            }
            .buttonStyle(.plain)

            // 喜欢
            Button(action: onLike) {
                Image(isLiked ? "icon_like_active" : "icon_like")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.musicRowIcon, height: Dimens.musicRowIcon)
            }
            .buttonStyle(.plain)

            // 更多菜单
            Button(action: onMenu) {
                Image("icon_music_menu")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.musicRowIcon, height: Dimens.musicRowIcon)
            }
            .buttonStyle(.plain)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
        .contentShape(Rectangle())
        .onTapGesture(perform: onPlay)
    }

    // MARK: - 子视图

    /// 名次视图
    @ViewBuilder
    private var rankView: some View {
        switch index {
        case 0:
            rankIcon("icon_no1")
        case 1:
            rankIcon("icon_no2")
        case 2:
            rankIcon("icon_no3")
        default:
            Text("\(index + 1)")
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.subColor)
        }
    }

    /// 奖牌图标
    private func rankIcon(_ name: String) -> some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Dimens.musicRowIcon, height: Dimens.musicRowIcon)
    }

    // MARK: - 状态

    /// 是否是本列表正在播放的歌
    private var isCurrentPlaying: Bool {
        playerState.currentMusic?.id == music.id
            && playerState.isPlaying
            && playerState.classifyName == classifyName
    }

    /// 播放图标
    private var playIcon: String {
        isCurrentPlaying ? "icon_music_playing_grey" : "icon_music_play"
    }

    /// 是否已喜欢
    private var isLiked: Bool {
        (music.isLike ?? 0) == 1
    }
}

#Preview {
    VStack(spacing: Dimens.middleMargin) {
        MusicRankRow(
            music: Music(id: 1, songName: "隔岸", authorName: "姚六一", cover: ""),
            index: 0,
            classifyName: "推荐歌曲",
            onPlay: {}, onLike: {}, onMenu: {}
        )
        MusicRankRow(
            music: Music(id: 2, songName: "奇迹", authorName: "贺峻霖", cover: ""),
            index: 4,
            classifyName: "推荐歌曲",
            onPlay: {}, onLike: {}, onMenu: {}
        )
    }
    .padding()
    .background(Colors.pageBackgroundColor)
}
