//
//  MusicLyricPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 歌词全屏页
///
/// 入口：播放页点歌词区域。
///
/// 对齐 flutter `MusicLyricPage.dart` 与 uniapp 播放页的歌词区：
/// - 全屏模糊封面背景（与播放页同一套）
/// - 顶部歌名 + 歌手
/// - 中间大字歌词：当前行高亮（不透明 1），其余 0.5 透明，随播放进度自动滚动居中
/// - 左上角返回；点击歌词区域也能返回
///
/// 歌词解析与滚动复用 `LyricScrollView` / `LyricParser`，不需要额外接口。
struct MusicLyricPage: View {
    @ObservedObject private var playerState = PlayerState.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 背景：模糊封面
            BlurredCoverBackground(cover: playerState.currentMusic?.cover)

            VStack(spacing: Dimens.middleMargin) {
                // 歌名 + 歌手
                header

                // 歌词
                LyricScrollView(
                    lyrics: playerState.currentMusic?.lyrics,
                    position: playerState.position,
                    fontSize: Dimens.bigFont,
                    lineSpacing: Dimens.largeMargin,
                    onTap: { dismiss() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, Dimens.middleMargin)
            .padding(.top, Dimens.bigIcon / 2)
            .padding(.bottom, Dimens.middleMargin)

            // 左上角返回
            backButton
        }
        .background(Colors.blackColor)
    }

    // MARK: - 子视图

    /// 歌名 + 歌手
    private var header: some View {
        VStack(spacing: Dimens.smallMargin) {
            Text(playerState.currentMusic?.songName ?? "未在播放")
                .font(.system(size: Dimens.middleFont))
                .fontWeight(.bold)
                .foregroundColor(Colors.whiteColor)
                .lineLimit(1)

            Text(playerState.currentMusic?.displayAuthorName ?? "")
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.whiteColor)
                .opacity(0.8)
                .lineLimit(1)
        }
        .padding(.top, Dimens.middleAvater)
    }

    /// 左上角返回按钮（和播放页同样的半透明样式）
    private var backButton: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image("icon_back")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
                        .opacity(0.5)
                        .padding(Dimens.middleMargin)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            Spacer()
        }
        .padding(.top, Dimens.middleMargin)
    }
}

#Preview {
    MusicLyricPage()
}
