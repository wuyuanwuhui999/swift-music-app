//
//  MusicCategoryEntryRow.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 首页分类入口（歌手 / 分类歌曲 / 经典老歌 / 热门歌曲）
///
/// 对齐 uniapp `MusicHomeComponent` 的 `.category-wrapper`：
/// 4 个等分入口，图标 + 文案纵向排列，四个都可点击跳转：
/// 歌手 → 歌手分类页，分类歌曲 → 歌曲分类页，经典老歌 / 热门歌曲 → 分类歌曲列表页。
struct MusicCategoryEntryRow: View {
    /// 点「歌手」
    let onSingerTap: () -> Void
    /// 点「分类歌曲」
    let onCategoryTap: () -> Void
    /// 点「经典老歌」
    let onClassicsTap: () -> Void
    /// 点「热门歌曲」
    let onRankTap: () -> Void

    /// 入口配置：图标资源名 + 文案
    private let entries: [(icon: String, title: String)] = [
        ("icon_music_singer", "歌手"),
        ("icon_music_classify", "分类歌曲"),
        ("icon_music_classics", "经典老歌"),
        ("icon_music_rank", "热门歌曲")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                entryView(index: index, entry: entry)
            }
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    /// 单个入口
    @ViewBuilder
    private func entryView(index: Int, entry: (icon: String, title: String)) -> some View {
        let content = VStack(spacing: Dimens.smallMargin) {
            Image(entry.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.musicCategoryIcon, height: Dimens.musicCategoryIcon)

            Text(entry.title)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())

        switch index {
        case 0:
            Button(action: onSingerTap) { content }.buttonStyle(.plain)
        case 1:
            Button(action: onCategoryTap) { content }.buttonStyle(.plain)
        case 2:
            // 经典老歌：跳分类歌曲列表页（id 2）
            Button(action: onClassicsTap) { content }.buttonStyle(.plain)
        default:
            // 热门歌曲：跳分类歌曲列表页（id 1）
            Button(action: onRankTap) { content }.buttonStyle(.plain)
        }
    }
}

#Preview {
    MusicCategoryEntryRow(onSingerTap: {}, onCategoryTap: {}, onClassicsTap: {}, onRankTap: {})
        .padding()
        .background(Colors.pageBackgroundColor)
}
