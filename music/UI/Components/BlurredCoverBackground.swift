//
//  BlurredCoverBackground.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 全屏模糊封面背景（播放页 / 歌词页共用）
///
/// 对齐 flutter `MusicPlayerPage` / `MusicLyricPage` 的 `ImageFiltered(blur 50)`：
/// 封面铺满全屏后高斯模糊（radius 50），没有封面时退回默认封面图。
struct BlurredCoverBackground: View {
    /// 封面地址（相对路径或完整 URL 都可以，内部走 `MusicUtils.coverURL`）
    let cover: String?

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let urlString = MusicUtils.coverURL(cover), let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            defaultBackground
                        }
                    }
                } else {
                    defaultBackground
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .blur(radius: 50)
        }
        .ignoresSafeArea()
    }

    /// 没有封面时的默认背景
    private var defaultBackground: some View {
        Image("default_cover")
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
}

#Preview {
    BlurredCoverBackground(cover: nil)
}
