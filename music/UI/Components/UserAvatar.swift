//
//  UserAvatar.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 当前登录用户的头像（圆形）
///
/// 对齐 uniapp `AvaterComponent`：取 `AppState.userData.avater`，
/// 为空或加载失败时展示 `default_avater` 兜底图。
struct UserAvatar: View {
    /// 头像相对路径（后端返回，可能是 `/{path}` 也可能已是完整 URL）
    let avatar: String?
    /// 直径
    let size: CGFloat

    var body: some View {
        ZStack {
            Colors.pageBackgroundColor

            if let urlString = MusicUtils.coverURL(avatar), let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        defaultAvatar
                    @unknown default:
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    /// 默认头像
    private var defaultAvatar: some View {
        Image("default_avater")
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
}
