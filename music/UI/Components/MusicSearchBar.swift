//
//  MusicSearchBar.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 首页顶部搜索栏
///
/// 对齐 uniapp `MusicSearchComponent`：用户头像 + 搜索框（展示推荐关键词）+ AI 图标。
/// - 点头像 / 搜索框 / AI 图标都会跳到二级页面（当前是占位页，见 `MusicDetailRoute`）
struct MusicSearchBar: View {
    /// 搜索框里展示的推荐关键词（来自 `getKeywordMusic`，格式「歌手 - 歌名」）
    let keyword: String
    /// 当前用户头像路径
    let userAvatar: String?

    /// 点头像
    let onAvatarTap: () -> Void
    /// 点搜索框
    let onSearchTap: () -> Void
    /// 点 AI 图标
    let onAITap: () -> Void

    var body: some View {
        HStack(spacing: Dimens.middleMargin) {
            // 用户头像
            Button(action: onAvatarTap) {
                UserAvatar(avatar: userAvatar, size: Dimens.middleAvater)
            }
            .buttonStyle(.plain)

            // 搜索框（只展示推荐关键词，点击进入搜索页）
            Button(action: onSearchTap) {
                HStack {
                    Text(keyword.isEmpty ? "搜索歌曲、歌手" : keyword)
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.grayColor)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Dimens.middleMargin)
                .frame(height: Dimens.musicSearchHeight)
                .background(Colors.pageBackgroundColor)
                .cornerRadius(Dimens.musicSearchHeight / 2)
            }
            .buttonStyle(.plain)

            // AI 图标
            Button(action: onAITap) {
                Image("icon_ai")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
            }
            .buttonStyle(.plain)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }
}

#Preview {
    MusicSearchBar(
        keyword: "赵乃吉 - 黄昏",
        userAvatar: nil,
        onAvatarTap: {}, onSearchTap: {}, onAITap: {}
    )
    .padding()
    .background(Colors.pageBackgroundColor)
}
