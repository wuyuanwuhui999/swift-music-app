//
//  MusicCategoryEntryRow.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 首页分类入口项
struct MusicCategoryEntry: Identifiable, Hashable {
    /// 点击后的去向
    enum Destination: Hashable {
        /// 歌手分类页
        case singer
        /// 歌曲分类页（分类网格）
        case categoryGrid
        /// 分类歌曲列表页（携带分类 id 与名称，名称同时作为导航栏标题）
        case songs(id: Int, title: String)
    }

    /// 展示文案（同时作为唯一标识）
    let title: String
    /// 图标资源名（Assets.xcassets 里的 imageset 名）
    let icon: String
    /// 点击去向
    let destination: Destination

    var id: String { title }
}

/// 首页分类入口（两行 4 列网格）
///
/// 对齐 uniapp `MusicHomeComponent` 的 `.category-wrapper`，在其 4 个入口基础上增加 4 个歌曲分类，
/// 排成 2 行 × 4 列：
/// - 第一行：歌手、分类歌曲、经典老歌、热门歌曲
/// - 第二行：蝰蛇母带、专属好歌、音乐记忆、流行热歌
///
/// 除「歌手」「分类歌曲」进各自的分类页外，其余 6 个都进 `MusicClassifyListPage`，
/// 并把分类 id 与名称带过去（名称作为导航栏标题）。
struct MusicCategoryEntryRow: View {
    /// 点某个入口（由调用方按 `destination` 决定跳转）
    let onTap: (MusicCategoryEntry) -> Void

    /// 入口配置：图标 + 文案 + 去向（顺序即展示顺序，两行 4 列）
    private let entries: [MusicCategoryEntry] = [
        .init(title: "歌手", icon: "icon_music_singer", destination: .singer),
        .init(title: "分类歌曲", icon: "icon_music_classify", destination: .categoryGrid),
        .init(title: "经典老歌", icon: "icon_music_classics", destination: .songs(id: 2, title: "经典老歌")),
        .init(title: "热门歌曲", icon: "icon_music_rank", destination: .songs(id: 1, title: "热门歌曲")),
        .init(title: "蝰蛇母带", icon: "icon_music_kuishe", destination: .songs(id: 3, title: "蝰蛇母带")),
        .init(title: "专属好歌", icon: "icon_music_exclusive", destination: .songs(id: 4, title: "专属好歌")),
        .init(title: "音乐记忆", icon: "icon_music_memory", destination: .songs(id: 5, title: "音乐记忆")),
        .init(title: "流行热歌", icon: "icon_music_popular", destination: .songs(id: 6, title: "流行热歌"))
    ]

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Dimens.smallMargin), count: 4),
            spacing: Dimens.middleMargin
        ) {
            ForEach(entries) { entry in
                Button(action: { onTap(entry) }) {
                    entryView(entry)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    /// 单个入口（图标 + 文案纵向排列）
    private func entryView(_ entry: MusicCategoryEntry) -> some View {
        VStack(spacing: Dimens.smallMargin) {
            Image(entry.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.musicCategoryIcon, height: Dimens.musicCategoryIcon)

            Text(entry.title)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

#Preview {
    MusicCategoryEntryRow(onTap: { _ in })
        .padding()
        .background(Colors.pageBackgroundColor)
}
