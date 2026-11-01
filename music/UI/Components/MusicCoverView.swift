//
//  MusicCoverView.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 圆形封面（歌曲封面 / 歌手头像通用）
///
/// 对齐 uniapp `static/style.less` 的 `.music-cover`：
/// 圆形裁剪、灰色（页面背景色）兜底底色，图片加载中/失败时展示 `default_cover`。
struct MusicCoverView: View {
    /// 封面地址（相对路径或完整 URL 都可以，内部会走 `MusicUtils.coverURL` 拼接）
    let cover: String?
    /// 直径
    let size: CGFloat

    var body: some View {
        ZStack {
            // 兜底底色
            Colors.pageBackgroundColor

            if let urlString = MusicUtils.coverURL(cover), let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        defaultCover
                    @unknown default:
                        defaultCover
                    }
                }
            } else {
                defaultCover
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    /// 默认封面
    private var defaultCover: some View {
        Image("default_cover")
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
}

/// 歌手头像（圆形，无头像时展示姓名首字）
///
/// 对齐 uniapp `MusicAvaterComponent` 在 `type == 'author'` 时的表现。
struct MusicAuthorAvatarView: View {
    let author: MusicAuthor
    let size: CGFloat

    var body: some View {
        ZStack {
            Colors.pageBackgroundColor

            if let urlString = MusicUtils.coverURL(author.avatar), let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        initialText
                    @unknown default:
                        initialText
                    }
                }
            } else {
                initialText
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    /// 姓名首字兜底
    private var initialText: some View {
        Text(author.avatarPlaceholderText)
            .font(.system(size: size * 0.4))
            .foregroundColor(Colors.subColor)
    }
}
