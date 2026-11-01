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

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            // 内容区（统一占位样式）
            PlaceholderPage(title: title)
        }
        .background(Colors.pageBackgroundColor)
    }

    /// 自定义导航栏（返回 + 标题 + 占位，保证标题居中）
    private var customNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: Dimens.middleIcon))
                    .foregroundColor(Colors.grayColor)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: Dimens.middleFont))
                .foregroundColor(Colors.blackColor)

            Spacer()

            // 占位按钮，保持标题居中
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.system(size: Dimens.middleIcon))
                    .foregroundColor(.clear)
            }
            .disabled(true)
        }
        .padding(.horizontal, Dimens.middleMargin)
        .padding(.vertical, Dimens.middleMargin)
        .background(Colors.whiteColor)
        .overlay(
            Rectangle()
                .fill(Colors.grayColor.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

#Preview {
    PlaceholderDetailPage(title: "搜索")
}
