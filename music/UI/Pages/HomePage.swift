//
//  HomePage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 主页 —— 四个 Tab 的容器页
///
/// 对齐 uniapp `src/pages/MusicIndexPage.vue` 与 flutter `lib/pages/MusicIndexPage.dart`：
/// - 四个 Tab：首页 / 推荐 / 音乐圈 / 我的
/// - 底部中央：迷你播放器（唱片），点按进入播放页
/// - Tab 页懒加载：只有被点击过的 Tab 才创建视图（对齐 uniapp 的 `isInitComponent`）
/// - 切换 Tab 不销毁已创建的页面，回来时保留状态（对齐 uniapp 的 `v-show` 与 flutter 的 keepAlive）
struct HomePage: View {
    @ObservedObject private var playerState = PlayerState.shared

    /// 当前选中的 Tab 下标：0 首页 / 1 推荐 / 2 音乐圈 / 3 我的
    @State private var selectedIndex = 0
    /// 各 Tab 是否已初始化（首页默认初始化）
    @State private var initializedTabs: [Bool] = [true, false, false, false]
    /// 是否展示播放页
    @State private var showPlayerPage = false

    var body: some View {
        ZStack {
            // 页面背景色
            Colors.pageBackgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Tab 内容区
                tabContent

                // 底部 Tab 栏（含中央迷你播放器）
                HomeTabBar(
                    selectedIndex: selectedIndex,
                    currentMusic: playerState.currentMusic,
                    isPlaying: playerState.isPlaying,
                    onSelect: selectTab,
                    onMiniPlayerTap: { showPlayerPage = true }
                )
            }
        }
        .onAppear {
            // 恢复本地缓存的「当前歌曲 / 播放列表 / 循环模式」
            playerState.restoreFromCache()
        }
        .fullScreenCover(isPresented: $showPlayerPage) {
            MusicPlayerPage()
        }
    }

    // MARK: - 视图组件

    /// Tab 内容区
    /// 未被点击过的 Tab 不创建视图；已创建的 Tab 用 opacity 隐藏，保证切回来时状态不丢
    private var tabContent: some View {
        ZStack {
            MusicHomePage()
                .tabPage(active: selectedIndex == 0)

            if initializedTabs[1] {
                MusicRecommentPage()
                    .tabPage(active: selectedIndex == 1)
            }

            if initializedTabs[2] {
                MusicCirclePage()
                    .tabPage(active: selectedIndex == 2)
            }

            if initializedTabs[3] {
                MusicUserPage()
                    .tabPage(active: selectedIndex == 3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 交互

    /// 切换 Tab（首次切换时初始化对应页面）
    private func selectTab(_ index: Int) {
        guard index != selectedIndex else { return }
        initializedTabs[index] = true
        selectedIndex = index
    }
}

// MARK: - Tab 页面显隐修饰器
/// 通过 opacity + 命中测试开关实现「保留状态但不可见 / 不可点」
private struct TabPageVisibility: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
    }
}

private extension View {
    /// 标记该页面是否为当前展示的 Tab 页
    func tabPage(active: Bool) -> some View {
        modifier(TabPageVisibility(isActive: active))
    }
}

#Preview {
    HomePage()
}
