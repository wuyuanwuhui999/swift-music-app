//
//  MusicSongRow.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 歌曲列表行
///
/// 对齐 uniapp `MusicClassifyListComponent` 的 `.music-row`：
/// 封面 + 「歌手 - 歌名」+ 播放状态图标 + 喜欢图标 + 更多菜单图标。
struct MusicSongRow: View {
    /// 歌曲
    let music: Music
    /// 所属模块名（用于判断「当前播放的是否是本模块的歌」）
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
            MusicCoverView(cover: music.cover, size: Dimens.musicCover)

            // 「歌手 - 歌名」
            Text("\(music.displayAuthorName) - \(music.songName)")
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 播放中 / 播放
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
        .contentShape(Rectangle())
        .onTapGesture(perform: onPlay)
    }

    /// 当前行是否就是正在播放的那首歌（且模块一致）
    private var isCurrentPlaying: Bool {
        playerState.currentMusic?.id == music.id
            && playerState.isPlaying
            && playerState.classifyName == classifyName
    }

    /// 播放图标：正在播放时用灰色播放中图标
    private var playIcon: String {
        isCurrentPlaying ? "icon_music_playing_grey" : "icon_music_play"
    }

    /// 是否已喜欢（isLike 为 1 视为已喜欢）
    private var isLiked: Bool {
        (music.isLike ?? 0) == 1
    }
}
