//
//  MusicSongListCard.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 歌曲列表卡片（白底圆角 + 行间分割线）
///
/// 分类歌曲列表、歌手歌曲列表、搜索结果、歌曲分类页共用同一套列表样式，
/// 统一在这里实现，避免每个页面重复写「行 + 分割线 + 卡片背景」。
struct MusicSongListCard: View {
    /// 歌曲列表
    let musics: [Music]
    /// 所属模块名（用于行内判断「当前播放的是否是本列表的歌」）
    let classifyName: String
    /// 点播放（行点击也是播放）
    let onPlay: (Music) -> Void
    /// 点喜欢（传下标，便于回写行内状态）
    let onLike: (Int) -> Void
    /// 点更多菜单
    var onMenu: (Int) -> Void = { _ in }

    var body: some View {
        VStack(spacing: Dimens.middleMargin) {
            ForEach(Array(musics.enumerated()), id: \.element.id) { index, music in
                VStack(spacing: Dimens.middleMargin) {
                    MusicSongRow(
                        music: music,
                        classifyName: classifyName,
                        onPlay: { onPlay(music) },
                        onLike: { onLike(index) },
                        onMenu: { onMenu(index) }
                    )

                    // 最后一行不画分割线
                    if index < musics.count - 1 {
                        Rectangle()
                            .fill(Colors.grayColor)
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }
}
