//
//  MusicPlayerDisc.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI
import Combine

/// 播放页的唱片
///
/// 对齐 uniapp `.circle-wrapper` / flutter `buildPlayCircle`：
/// 外圈半透明黑 + 黑→#333→黑 的渐变圆环 + 中间歌曲封面，播放时整体匀速旋转（10 秒一圈）。
struct MusicPlayerDisc: View {
    /// 封面
    let cover: String?
    /// 是否正在播放（决定是否旋转）
    let isPlaying: Bool

    @State private var rotation: Double = 0
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    /// 外圈直径
    private var discSize: CGFloat { Dimens.playerDisc }
    /// 内圈（渐变环）直径
    private var ringSize: CGFloat { discSize - Dimens.smallMargin * 2 }
    /// 封面直径
    private var coverSize: CGFloat { ringSize - Dimens.playerDiscPadding * 2 }

    var body: some View {
        ZStack {
            // 外圈：半透明黑底
            Circle()
                .fill(Colors.opacityBlack)
                .frame(width: discSize, height: discSize)

            // 会旋转的部分：渐变环 + 封面
            ZStack {
                LinearGradient(
                    colors: [Colors.blackColor, Colors.discGradient, Colors.discGradient, Colors.blackColor],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(width: ringSize, height: ringSize)
                .clipShape(Circle())

                MusicCoverView(cover: cover, size: coverSize)
            }
            .rotationEffect(.degrees(rotation))
        }
        .onReceive(timer) { _ in
            guard isPlaying else { return }
            rotation = (rotation + 3.6).truncatingRemainder(dividingBy: 360)
        }
    }
}

#Preview {
    MusicPlayerDisc(cover: nil, isPlaying: true)
        .padding()
        .background(Colors.blackColor)
}
