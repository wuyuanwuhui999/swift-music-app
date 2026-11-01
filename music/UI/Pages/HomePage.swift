//
//  HomePage.swift
//  music
//
//  Created by 吴文强 on 2026/11/1.
//

import SwiftUI

/// 主页（占位版）
/// 第一步只负责跑通「登录成功 → HomePage」链路，页面中间仅展示 hello world，
/// 后续按模块逐个补充首页 / 推荐 / 音乐圈 / 我的 等页面。
struct HomePage: View {
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        ZStack {
            // 页面背景色（主题规范）
            Colors.pageBackgroundColor
                .ignoresSafeArea()

            Text("hello world")
                .font(.system(size: Dimens.bigFont))
                .foregroundColor(Colors.primaryColor)
        }
    }
}

#Preview {
    HomePage()
}
