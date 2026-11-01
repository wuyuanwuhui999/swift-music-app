//
//  MusicPlayerPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 音乐播放页（占位）
/// 正式内容（唱片旋转、歌词、进度条、播放控制、评论/点赞/收藏）后续迭代开发，
/// 当前只保证「首页中央迷你播放器 → 播放页」的跳转链路能跑通。
struct MusicPlayerPage: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            PlaceholderPage(title: "音乐播放")

            // 返回按钮（fullScreenCover 没有系统返回手势，这里补一个）
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: Dimens.middleIcon))
                    .foregroundColor(Colors.primaryColor)
                    .padding(Dimens.middleMargin)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    MusicPlayerPage()
}
