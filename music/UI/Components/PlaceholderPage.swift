//
//  PlaceholderPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 占位页面
///
/// 首页拆成「首页 / 推荐 / 音乐圈 / 我的」四个子页面 + 各种二级跳转页，
/// 这些页面按迭代计划逐个开发，开发前统一用本组件占位（只展示 hello world + 页面名），
/// 保证 Tab 切换、跳转链路可以先跑通。
struct PlaceholderPage: View {
    /// 页面名称，仅用于占位识别，正式开发时删除
    let title: String

    var body: some View {
        VStack(spacing: Dimens.middleMargin) {
            Text("hello world")
                .font(.system(size: Dimens.bigFont))
                .foregroundColor(Colors.primaryColor)

            Text(title)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.subColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.pageBackgroundColor)
    }
}

#Preview {
    PlaceholderPage(title: "首页")
}
