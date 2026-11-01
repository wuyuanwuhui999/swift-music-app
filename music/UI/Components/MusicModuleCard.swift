//
//  MusicModuleCard.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 首页歌曲模块卡片（一个榜单 / 分类）
///
/// 对齐 uniapp `MusicClassifyComponent`：
/// 标题栏（可折叠 + 更多）+ 前 3 首歌曲；点击歌曲切换播放并进入播放页。
/// 接口：`GET /service/music/getMusicListByCategoryId`（pageSize = 3）
struct MusicModuleCard: View {
    /// 分类信息
    let category: MusicCategory
    /// 点「更多」
    let onMore: () -> Void
    /// 点某首歌（父级负责弹出播放页）
    let onPlayMusic: () -> Void

    @ObservedObject private var playerState = PlayerState.shared

    /// 模块歌曲
    @State private var songs: [Music] = []
    /// 是否折叠
    @State private var isFold = false
    /// 点赞请求中（防重复点击）
    @State private var isLikeLoading = false
    /// 轻提示文案
    @State private var alertMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Dimens.middleMargin) {
            MusicModuleHeader(
                title: category.category,
                isFold: isFold,
                onFold: { isFold.toggle() },
                onMore: onMore
            )

            if !isFold && !songs.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(songs.enumerated()), id: \.element.id) { index, music in
                        MusicSongRow(
                            music: music,
                            classifyName: category.category,
                            onPlay: { play(music) },
                            onLike: { toggleLike(at: index) },
                            onMenu: {}
                        )

                        // 行间分割线（最后一行不画）
                        if index < songs.count - 1 {
                            Rectangle()
                                .fill(Colors.grayColor)
                                .frame(height: 1)
                                .padding(.vertical, Dimens.smallMargin)
                        }
                    }
                }
            }
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
        .onAppear(perform: loadSongs)
        .alert("提示", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    // MARK: - 数据

    /// 加载本模块的前 3 首歌曲
    private func loadSongs() {
        guard songs.isEmpty else { return }
        HTTPClient.shared.getMusicListByCategoryId(
            categoryId: category.id,
            pageNum: 1,
            pageSize: Constants.MusicConfig.homeModuleSongCount
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (list, _)):
                    songs = list
                case .failure(let error):
                    print("❌ 获取模块歌曲失败(\(category.category)): \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 交互

    /// 播放某首歌
    /// 对齐 uniapp `usePlayMusic`：切歌时立即播放；若切换了模块，则把整个榜单拉下来作为播放列表
    private func play(_ music: Music) {
        if playerState.currentMusic?.id != music.id {
            playerState.setMusic(music, autoPlay: true)

            if playerState.classifyName != category.category {
                HTTPClient.shared.getMusicListByCategoryId(
                    categoryId: category.id,
                    pageNum: 1,
                    pageSize: Constants.MusicConfig.maxPlaylistCount
                ) { result in
                    DispatchQueue.main.async {
                        if case .success(let (list, _)) = result, !list.isEmpty {
                            playerState.setMusicList(list)
                            playerState.setClassifyName(category.category)
                        }
                    }
                }
            }
        }
        onPlayMusic()
    }

    /// 点赞 / 取消点赞
    private func toggleLike(at index: Int) {
        guard !isLikeLoading, songs.indices.contains(index) else { return }
        isLikeLoading = true

        let music = songs[index]
        let wasLiked = (music.isLike ?? 0) == 1

        let handler: (Result<Int, NetworkError>) -> Void = { result in
            DispatchQueue.main.async {
                isLikeLoading = false
                switch result {
                case .success(let rows) where rows > 0:
                    songs[index].isLike = wasLiked ? 0 : 1
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
    MusicModuleCard(
        category: MusicCategory(id: 68, category: "酷狗飙升榜", classify: "热门榜单"),
        onMore: {},
        onPlayMusic: {}
    )
    .padding()
    .background(Colors.pageBackgroundColor)
}
