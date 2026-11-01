//
//  MiniPlayerView.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI
import Combine

/// 底部中央的迷你播放器（唱片）
///
/// 对齐 uniapp `MusicIndexPage.vue` 的 `.mini-player-wrapper` 与 flutter 的
/// `floatingActionButton`：
/// - 外圈是页面背景色，视觉上从白色 Tab 栏里「凹」进去（做 notch 效果）
/// - 中间是歌曲封面，播放时匀速旋转（flutter：10 秒一圈）
/// - 有歌曲时点按进入播放页；没有歌曲时展示音符占位，点了同样可以进播放页
struct MiniPlayerView: View {
    /// 当前歌曲，为 nil 时展示占位样式
    let music: Music?
    /// 是否正在播放（决定是否旋转）
    let isPlaying: Bool
    /// 点按回调
    let onTap: () -> Void

    /// 唱片旋转角度
    @State private var rotation: Double = 0

    /// 每 0.1s 推进一步，10 秒转一圈（36° / 秒）
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 外圈：页面背景色，做出白 Tab 栏上的凹槽
                Circle()
                    .fill(Colors.pageBackgroundColor)
                    .frame(width: Dimens.miniPlayerSize, height: Dimens.miniPlayerSize)

                // 内圈：封面 / 占位音符
                coverView
                    .frame(width: innerSize, height: innerSize)
                    .clipShape(Circle())
                    .rotationEffect(.degrees(rotation))
            }
        }
        .buttonStyle(.plain)
        .onReceive(timer) { _ in
            guard isPlaying else { return }
            rotation = (rotation + 3.6).truncatingRemainder(dividingBy: 360)
        }
    }

    /// 内圈直径（扣掉外圈描边）
    private var innerSize: CGFloat {
        Dimens.miniPlayerSize - Dimens.miniPlayerBorder * 2
    }

    /// 封面视图
    @ViewBuilder
    private var coverView: some View {
        if let urlString = MusicUtils.coverURL(music?.cover), let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty:
                    placeholder
                        .overlay {
                            ProgressView()
                                .tint(Colors.primaryColor)
                        }
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    /// 没有封面时的占位（灰色底 + 音符图标）
    private var placeholder: some View {
        ZStack {
            Colors.whiteColor
            Image(systemName: "music.note")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
                .foregroundColor(Colors.grayColor)
        }
    }
}

#Preview {
    VStack(spacing: Dimens.middleMargin) {
        MiniPlayerView(music: nil, isPlaying: false) {}
        MiniPlayerView(
            music: Music(id: 1, songName: "夜曲", authorName: "周杰伦", cover: ""),
            isPlaying: true
        ) {}
    }
    .padding()
    .background(Colors.whiteColor)
}
