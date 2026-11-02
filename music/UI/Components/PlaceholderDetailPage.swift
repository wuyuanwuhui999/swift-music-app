//
//  PlaceholderDetailPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 二级页面占位（带返回导航栏）
///
/// 首页里的搜索、歌手分类、榜单列表、歌手歌曲列表、AI 聊天、个人中心等二级页面
/// 都还没开发，先用本页面统一占位，保证跳转链路可以跑通；
/// 后续实现某个页面时，把对应的 `MusicDetailRoute` 分支替换成真正的页面即可。
struct PlaceholderDetailPage: View {
    /// 页面标题
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            // 公共导航栏（返回 + 居中标题）
            MusicNavBar(title: title)

            // 内容区（统一占位样式）
            PlaceholderPage(title: title)
        }
        .background(Colors.pageBackgroundColor)
    }
}

#Preview {
    PlaceholderDetailPage(title: "搜索")
}
