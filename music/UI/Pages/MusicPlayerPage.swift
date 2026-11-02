//
//  MusicPlayerPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 播放页可跳转的二级页面（暂用占位页代替）
enum MusicPlayerRoute: String, Identifiable {
    case lyric     // 歌词页
    case share     // 分享到音乐圈
    case comment   // 评论
    case favorite  // 收藏夹

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lyric: return "歌词"
        case .share: return "分享到音乐圈"
        case .comment: return "评论"
        case .favorite: return "收藏夹"
        }
    }
}

/// 音乐播放页
///
/// 对齐 flutter `MusicPlayerPage.dart` 与 uniapp `MusicPlayerPage.vue`：
/// 模糊封面背景 + 歌名 + 旋转唱片 + 同步歌词 + 歌手 + 操作栏（收藏/分享/评论/收藏夹）
/// + 进度条 + 控制栏（循环模式 / 上一首 / 播放暂停 / 下一首 / 播放列表）。
/// 音频由 `PlayerState`（内部 `AudioPlayerManager`）驱动，播完按循环模式自动切歌。
struct MusicPlayerPage: View {
    @ObservedObject private var playerState = PlayerState.shared
    @Environment(\.dismiss) private var dismiss

    /// 二级页面跳转
    @State private var route: MusicPlayerRoute?
    /// 循环模式弹层是否展示
    @State private var showLoopMenu = false
    /// 点赞请求中（防重复点击）
    @State private var isLikeLoading = false
    /// 进度条拖动中
    @State private var isDragging = false
    /// 拖动中的进度值（0~1）
    @State private var dragValue: Double = 0
    /// 轻提示
    @State private var alertMessage: String?

    /// 当前歌曲
    private var music: Music? { playerState.currentMusic }

    var body: some View {
        ZStack {
            // 背景：封面模糊铺满
            backgroundView

            VStack(spacing: Dimens.middleMargin) {
                // 歌名
                Text(music?.songName ?? "暂无歌曲")
                    .font(.system(size: Dimens.bigFont))
                    .fontWeight(.bold)
                    .foregroundColor(Colors.whiteColor)
                    .lineLimit(1)
                    .padding(.top, Dimens.middleMargin * 3)

                // 旋转唱片
                MusicPlayerDisc(cover: music?.cover, isPlaying: playerState.isPlaying)

                // 歌词
                LyricScrollView(
                    lyrics: music?.lyrics,
                    position: playerState.position,
                    onTap: { route = .lyric }
                )
                .frame(maxHeight: .infinity)

                // 歌手
                Text(music?.displayAuthorName ?? "")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.whiteColor)
                    .underline()
                    .lineLimit(1)

                // 操作栏：收藏 / 分享 / 评论 / 收藏夹
                operateRow

                // 进度条
                progressRow

                // 控制栏
                controlRow
                    .padding(.bottom, Dimens.middleMargin)
            }
            .padding(.horizontal, Dimens.middleMargin)

            // 返回按钮
            backButton
        }
        .onAppear {
            // 对齐 flutter：进入播放页即开始播放
            if !playerState.isPlaying {
                playerState.play()
            }
        }
        .fullScreenCover(item: $route) { route in
            switch route {
            case .share:
                // 分享到音乐圈：带上当前播放的歌曲
                MusicSharePage(music: playerState.currentMusic)
            default:
                PlaceholderDetailPage(title: route.title)
            }
        }
        .alert("提示", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    // MARK: - 视图组件

    /// 背景：封面模糊铺满全屏（无封面时用默认封面）
    private var backgroundView: some View {
        GeometryReader { geometry in
            Group {
                if let urlString = MusicUtils.coverURL(music?.cover), let url = URL(string: urlString) {
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

    /// 默认背景图
    private var defaultBackground: some View {
        Image("default_cover")
            .resizable()
            .aspectRatio(contentMode: .fill)
    }

    /// 返回按钮（左上角，透明度 0.5，对齐 uniapp `.icon-back`）
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

    /// 操作栏：收藏（喜欢）/ 分享 / 评论 / 收藏夹
    private var operateRow: some View {
        HStack {
            // 收藏（喜欢）
            Button(action: toggleLike) {
                Image(isLiked ? "icon_collection_active" : "icon_music_collect")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
            }
            .buttonStyle(.plain)

            Spacer()

            // 分享到音乐圈
            Button(action: { route = .share }) {
                Image("icon_share_music")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
            }
            .buttonStyle(.plain)

            Spacer()

            // 评论
            Button(action: { route = .comment }) {
                Image("icon_music_comments")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
            }
            .buttonStyle(.plain)

            Spacer()

            // 收藏夹（是否已收藏待接 isMusicFavorite 接口）
            Button(action: { route = .favorite }) {
                Image("icon_favorite")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Dimens.middleMargin * 2)
    }

    /// 进度条：当前时间 + 滑块 + 总时长
    private var progressRow: some View {
        HStack(spacing: 0) {
            Text(MusicUtils.formatDuration(isDragging ? dragValue * playerState.duration : playerState.position))
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.whiteColor)
                .opacity(0.8)

            Slider(
                value: Binding(
                    get: { isDragging ? dragValue : progressRatio },
                    set: { dragValue = $0 }
                ),
                in: 0...1,
                onEditingChanged: { editing in
                    if editing {
                        isDragging = true
                        dragValue = progressRatio
                    } else {
                        // 松手才真正跳转，避免拖动过程中频繁 seek
                        playerState.seek(to: dragValue * playerState.duration)
                        isDragging = false
                    }
                }
            )
            .tint(Colors.whiteColor)
            .padding(.horizontal, Dimens.middleMargin)

            Text(MusicUtils.formatDuration(playerState.duration))
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.whiteColor)
                .opacity(0.8)
        }
        .padding(.horizontal, Dimens.middleMargin)
    }

    /// 控制栏：循环模式 / 上一首 / 播放暂停 / 下一首 / 播放列表
    private var controlRow: some View {
        HStack(spacing: 0) {
            // 循环模式（点击弹层）
            Button(action: { showLoopMenu.toggle() }) {
                Image(playerState.loopMode.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottomLeading) {
                if showLoopMenu {
                    loopMenu
                        .offset(y: -Dimens.middleIcon - Dimens.middleMargin)
                }
            }

            // 上一首
            Button(action: { playerState.playPrevious() }) {
                Image("icon_music_prev")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            // 播放 / 暂停
            Button(action: { playerState.togglePlay() }) {
                ZStack {
                    Circle()
                        .stroke(Colors.whiteColor, lineWidth: Dimens.playerCircleBorder)
                        .frame(width: Dimens.playerCircle, height: Dimens.playerCircle)

                    Image(playerState.isPlaying ? "icon_music_playing" : "icon_music_play_white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
                }
            }
            .buttonStyle(.plain)

            // 下一首
            Button(action: { playerState.playNext() }) {
                Image("icon_music_next")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            // 播放列表（与 uniapp 一致，暂未绑定交互）
            Image("icon_music_play_menu")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
                .frame(maxWidth: .infinity)
        }
        .frame(height: Dimens.playerCircle)
    }

    /// 循环模式弹层（顺序 / 单曲 / 随机）
    private var loopMenu: some View {
        VStack(spacing: 0) {
            ForEach(LoopMode.allCases, id: \.self) { mode in
                Button(action: {
                    playerState.setLoopMode(mode)
                    showLoopMenu = false
                }) {
                    HStack(spacing: Dimens.smallMargin) {
                        Image(mode.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)

                        Text(mode.title)
                            .font(.system(size: Dimens.normalFont))
                            .foregroundColor(Colors.whiteColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Dimens.middleMargin)
                    .padding(.vertical, Dimens.smallMargin)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: Dimens.playerLoopMenuWidth)
        .padding(.vertical, Dimens.smallMargin)
        .background(Colors.blackColor)
        .cornerRadius(Dimens.borderRadius)
        .opacity(0.8)
    }

    // MARK: - 计算属性

    /// 当前进度（0~1）
    private var progressRatio: Double {
        guard playerState.duration > 0 else { return 0 }
        return min(max(playerState.position / playerState.duration, 0), 1)
    }

    /// 当前歌曲是否已喜欢
    private var isLiked: Bool {
        (music?.isLike ?? 0) == 1
    }

    // MARK: - 交互

    /// 收藏 / 取消收藏（对齐 uniapp `useLike`）
    private func toggleLike() {
        guard !isLikeLoading, let music = music else { return }
        isLikeLoading = true
        let wasLiked = (music.isLike ?? 0) == 1

        let handler: (Result<Int, NetworkError>) -> Void = { result in
            DispatchQueue.main.async {
                isLikeLoading = false
                switch result {
                case .success(let rows) where rows > 0:
                    playerState.updateLike(isLike: wasLiked ? 0 : 1)
                    alertMessage = wasLiked ? "取消点赞成功" : "点赞成功"
                case .success:
                    alertMessage = wasLiked ? "取消点赞失败" : "点赞失败"
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }

        if wasLiked {
            HTTPClient.shared.deleteMusicLike(musicId: music.id, completion: handler)
        } else {
            HTTPClient.shared.insertMusicLike(musicId: music.id, completion: handler)
        }
    }
}

#Preview {
    MusicPlayerPage()
}
