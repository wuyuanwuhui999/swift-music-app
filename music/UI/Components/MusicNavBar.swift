//
//  MusicNavBar.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 二级页面通用导航栏（返回按钮 + 居中标题）
///
/// 对齐 uniapp `NavigatorTitleComponent` / flutter `NavigatorTitleComponent`：
/// 左侧返回箭头取色 `Colors.grayColor`，标题居中，右侧留一个透明占位保证标题真的居中。
struct MusicNavBar: View {
    /// 标题
    let title: String
    /// 点返回
    var onBack: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button(action: {
                if let onBack = onBack {
                    onBack()
                } else {
                    dismiss()
                }
            }) {
                Image("icon_back")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: Dimens.middleFont))
                .foregroundColor(Colors.blackColor)
                .lineLimit(1)

            Spacer()

            // 占位按钮，保证标题居中
            Image("icon_back")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
                .opacity(0)
        }
        .padding(.horizontal, Dimens.middleMargin)
        .padding(.vertical, Dimens.middleMargin)
        .background(Colors.whiteColor)
    }
}

#Preview {
    MusicNavBar(title: "酷狗飙升榜")
}
