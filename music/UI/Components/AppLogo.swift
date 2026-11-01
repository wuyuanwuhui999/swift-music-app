//
//  AppLogo.swift
//  music
//
//  Created by 吴文强 on 2026/11/1.
//

import SwiftUI

/// 应用 Logo 组件
/// 使用 Assets.xcassets 中的 `icon_logo` 图片，替代 chat 项目里 AI 对话专用的 AIAvatar
struct AppLogo: View {
    /// 显示尺寸（正方形，按原图等比缩放）
    let size: CGFloat

    /// 圆角半径：默认取 Dimens.borderRadius，换成圆形时传 size / 2
    let cornerRadius: CGFloat

    init(size: CGFloat, cornerRadius: CGFloat = Dimens.borderRadius) {
        self.size = size
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Image("icon_logo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // MARK: - 兼容旧调用（对齐 AIAvatar.large()）
    /// 大尺寸 Logo（欢迎页 / 登录页顶部）
    static func large() -> AppLogo {
        AppLogo(size: Dimens.bigAvater * 1.5)
    }

    /// 中尺寸 Logo
    static func middle() -> AppLogo {
        AppLogo(size: Dimens.middleAvater)
    }

    /// 小尺寸 Logo
    static func small() -> AppLogo {
        AppLogo(size: Dimens.smallAvater)
    }
}

#Preview {
    VStack(spacing: Dimens.middleMargin) {
        AppLogo.large()
        AppLogo.middle()
        AppLogo.small()
    }
    .padding()
    .background(Colors.pageBackgroundColor)
}
