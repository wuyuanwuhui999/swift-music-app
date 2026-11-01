//
//  MusicCategoryEntryRow.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 首页分类入口（歌手 / 分类歌曲 / 经典老歌 / 热门榜单）
///
/// 对齐 uniapp `MusicHomeComponent` 的 `.category-wrapper`：
/// 4 个等分入口，图标 + 文案纵向排列；其中「歌手」「分类歌曲」可点击跳转，
/// 「经典老歌」「热门榜单」在 uniapp 里也没有绑定跳转，这里保持一致（仅展示）。
struct MusicCategoryEntryRow: View {
    /// 点「歌手」
    let onSingerTap: () -> Void
    /// 点「分类歌曲」
    let onCategoryTap: () -> Void

    /// 入口配置：图标资源名 + 文案
    private let entries: [(icon: String, title: String)] = [
        ("icon_music_singer", "歌手"),
        ("icon_music_classify", "分类歌曲"),
        ("icon_music_classics", "经典老歌"),
        ("icon_music_rank", "热门榜单")
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
        default:
            // 经典老歌 / 热门榜单：uniapp 未绑定跳转，先只展示
            content
        }
    }
}

#Preview {
    MusicCategoryEntryRow(onSingerTap: {}, onCategoryTap: {})
        .padding()
        .background(Colors.pageBackgroundColor)
}
