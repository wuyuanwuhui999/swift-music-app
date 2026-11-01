//
//  MusicModuleHeader.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 首页模块标题栏
///
/// 对齐 uniapp `MusicTitleComponent`：`icon_down` 箭头（折叠时旋转 90°）+ 模块名 + 「更多」。
/// 箭头透明度与 uniapp 一致取 0.2，其余按项目规范用图标透明度 0.5 之外的显式值会在下方注明。
struct MusicModuleHeader: View {
    /// 模块名（分类的 `category`）
    let title: String
    /// 是否已折叠
    let isFold: Bool
    /// 点箭头：展开 / 折叠
    let onFold: () -> Void
    /// 点「更多」
    let onMore: () -> Void

    var body: some View {
        HStack(spacing: Dimens.smallMargin) {
            // 展开/折叠箭头（折叠时顺时针转 90°）
            Button(action: onFold) {
                Image("icon_down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.musicArrowIcon, height: Dimens.musicArrowIcon)
                    .rotationEffect(.degrees(isFold ? 90 : 0))
                    .opacity(0.2)
            }
            .buttonStyle(.plain)

            // 模块名
            Text(title)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .lineLimit(1)

            Spacer(minLength: Dimens.smallMargin)

            // 更多
            Button(action: onMore) {
                Text("更多")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.grayColor)
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    VStack(spacing: Dimens.middleMargin) {
        MusicModuleHeader(title: "酷狗飙升榜", isFold: false, onFold: {}, onMore: {})
        MusicModuleHeader(title: "酷狗飙升榜", isFold: true, onFold: {}, onMore: {})
    }
    .padding()
    .background(Colors.whiteColor)
}
