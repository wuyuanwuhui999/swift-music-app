//
//  MusicSectionHeader.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 模块标题栏（折叠箭头 + 标题 + 右侧操作区）
///
/// 对齐 uniapp `MusicTitleComponent` / flutter `MusicTitleComponent`：
/// 箭头 `icon_down`（折叠时顺时针 90°），右侧可放刷新、更多、新建等操作。
struct MusicSectionHeader<Trailing: View>: View {
    /// 标题
    let title: String
    /// 是否已折叠
    let isFold: Bool
    /// 点箭头折叠 / 展开
    let onFold: () -> Void
    /// 右侧操作区
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: Dimens.smallMargin) {
            Button(action: onFold) {
                Image("icon_down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.musicArrowIcon, height: Dimens.musicArrowIcon)
                    .rotationEffect(.degrees(isFold ? 90 : 0))
                    .opacity(0.2)
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .lineLimit(1)

            Spacer(minLength: Dimens.smallMargin)

            trailing()
        }
    }
}

#Preview {
    MusicSectionHeader(title: "我喜欢的歌曲", isFold: false, onFold: {}) {
        Text("更多")
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.grayColor)
            .underline()
    }
    .padding()
    .background(Colors.whiteColor)
}
