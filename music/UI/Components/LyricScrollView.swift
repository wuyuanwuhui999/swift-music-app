//
//  LyricScrollView.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 播放页歌词区域
///
/// 对齐 uniapp `.lyrice-scroll-wrapper` / flutter `buildLyric`：
/// 居中展示 LRC 歌词，当前行不透明（1），其余行 0.5 透明；随播放进度自动滚动到当前行。
/// 点击歌词区域进入歌词页（二级页面，当前占位）。
struct LyricScrollView: View {
    /// LRC 歌词原文
    let lyrics: String?
    /// 当前播放进度（秒）
    let position: Double
    /// 点歌词区域
    let onTap: () -> Void

    /// 解析后的歌词行
    @State private var lines: [LyricLine] = []

    var body: some View {
        ZStack {
            if lines.isEmpty {
                Text("暂无歌词")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.whiteColor)
                    .opacity(0.5)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: Dimens.middleMargin) {
                            ForEach(lines) { line in
                                Text(line.text)
                                    .font(.system(size: Dimens.normalFont))
                                    .fontWeight(.bold)
                                    .foregroundColor(Colors.whiteColor)
                                    .opacity(line.id == currentLineId ? 1 : 0.5)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .id(line.id)
                            }
                        }
                        .padding(.vertical, Dimens.middleMargin)
                    }
                    .onChange(of: currentLineId) { _, newValue in
                        guard let newValue = newValue else { return }
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear(perform: reload)
        .onChange(of: lyrics) { _, _ in reload() }
    }

    /// 当前高亮的歌词行 id
    /// 解析时 `LyricLine.id` 就是行下标，所以直接用下标记即可
    private var currentLineId: Int? {
        LyricParser.currentIndex(in: lines, position: position)
    }

    /// 重新解析歌词
    private func reload() {
        lines = LyricParser.parse(lyrics)
    }
}

#Preview {
    LyricScrollView(
        lyrics: "[00:00.01]隔岸 - 姚六一\n[00:01.51]词：姚六一\n[00:02.66]曲：姚六一",
        position: 2,
        onTap: {}
    )
    .frame(height: 200)
    .background(Colors.blackColor)
}
