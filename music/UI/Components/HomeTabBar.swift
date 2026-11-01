//
//  HomeTabBar.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 首页底部 Tab 栏
///
/// 对齐 uniapp `MusicIndexPage.vue` 的 `.tab-bar` 与 flutter 的 `BottomAppBar`：
/// 首页 / 推荐 / [中央迷你播放器] / 音乐圈 / 我的
/// - 中间预留固定宽度给迷你播放器，迷你播放器骑在 Tab 栏上沿（见 `MiniPlayerView`）
/// - 选中态：图标换成 *active 图标，文字变主题色
struct HomeTabBar: View {
    /// 当前选中的下标：0 首页 / 1 推荐 / 2 音乐圈 / 3 我的
    let selectedIndex: Int
    /// 当前歌曲（为 nil 时迷你播放器展示占位）
    let currentMusic: Music?
    /// 是否正在播放
    let isPlaying: Bool
    /// 点击 Tab
    let onSelect: (Int) -> Void
    /// 点击迷你播放器
    let onMiniPlayerTap: () -> Void

    /// Tab 文案（与 uniapp titles 顺序一致）
    private let titles = ["首页", "推荐", "音乐圈", "我的"]
    /// 未选中图标
    private let normalIcons = ["icon_home", "icon_recomment", "icon_music_circle", "icon_user"]
    /// 选中图标
    private let activeIcons = ["icon_home_active", "icon_recomment_active",
                               "icon_music_circle_active", "icon_user_active"]

    var body: some View {
        HStack(spacing: 0) {
            tabItem(index: 0)
            tabItem(index: 1)

            // 中央迷你播放器占位（宽度固定，保证两侧 Tab 位置稳定）
            Color.clear
                .frame(width: Dimens.miniPlayerSize)

            tabItem(index: 2)
            tabItem(index: 3)
        }
        .frame(height: Dimens.bottomBarHeight)
        .frame(maxWidth: .infinity)
        .background(Colors.whiteColor)
        .overlay(alignment: .top) {
            // 迷你播放器：圆心压在 Tab 栏上沿，一半露在内容区
            MiniPlayerView(
                music: currentMusic,
                isPlaying: isPlaying,
                onTap: onMiniPlayerTap
            )
            .offset(y: -Dimens.miniPlayerSize / 2)
        }
    }

    /// 单个 Tab（图标 + 文字）
    private func tabItem(index: Int) -> some View {
        let isSelected = selectedIndex == index
        return Button(action: {
            onSelect(index)
        }) {
            VStack(spacing: Dimens.smallMargin) {
                Image(isSelected ? activeIcons[index] : normalIcons[index])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)

                Text(titles[index])
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(isSelected ? Colors.primaryColor : Colors.blackColor)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        HomeTabBar(
            selectedIndex: 0,
            currentMusic: Music(id: 1, songName: "夜曲", authorName: "周杰伦", cover: ""),
            isPlaying: true,
            onSelect: { _ in },
            onMiniPlayerTap: {}
        )
    }
    .background(Colors.pageBackgroundColor)
}
