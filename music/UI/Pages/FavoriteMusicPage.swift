//
//  FavoriteMusicPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 收藏夹详情（某个收藏夹里的歌曲）
///
/// 入口：「我的」页「我的收藏夹」列表里某个收藏夹的「更多」/ 标题栏「更多」。
///
/// 参考 uniapp `MusicFavoriteListPage.vue`（携带 favoriteDirectory）与
/// flutter `MusicFavoriteListPage.dart`：分页列表，点歌播放，长按歌曲行从收藏夹移除。
///
/// 接口：
/// - `GET /service/music/getMusicListByFavoriteId?favoriteId=&pageNum=&pageSize=`
/// - `GET /service/music/getFavoriteDirectory?musicId=`（移除时用于取其余收藏夹）
/// - `POST /service/music/insertMusicFavorite/{musicId}`（提交剩余收藏夹，实现「仅从这个收藏夹移除」）
struct FavoriteMusicPage: View {
    /// 收藏夹
    let directory: FavoriteDirectory

    @ObservedObject private var playerState = PlayerState.shared

    /// 歌曲列表
    @State private var musics: [Music] = []
    /// 当前页码
    @State private var pageNum = 1
    /// 总条数
    @State private var total = 0
    /// 是否正在请求
    @State private var isLoading = false
    /// 是否正在移除
    @State private var isRemoving = false
    /// 展示播放页
    @State private var showPlayerPage = false
    /// 轻提示
    @State private var alertMessage: String?

    private let pageSize = Constants.MusicConfig.pageSize

    /// 播放列表名固定为收藏夹名
    private var classifyName: String { directory.name }

    var body: some View {
        VStack(spacing: 0) {
            MusicNavBar(title: directory.name)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Dimens.middleMargin) {
                    if musics.isEmpty {
                        emptyRow
                    } else {
                        MusicSongListCard(
                            musics: musics,
                            classifyName: classifyName,
                            onPlay: { play($0) },
                            onLike: { toggleLike(at: $0) },
                            onLongPress: { removeFromDirectory(at: $0) }
                        )
                        footer
                    }
                }
                .padding(Dimens.middleMargin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .refreshable { await reload() }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.containerSize.height
                    >= geometry.contentSize.height - 200
            } action: { _, isNearBottom in
                guard isNearBottom else { return }
                loadMoreIfNeeded()
            }
        }
        .background(Colors.pageBackgroundColor)
        .onAppear {
            if musics.isEmpty { loadFirstPage() }
        }
        .fullScreenCover(isPresented: $showPlayerPage) {
            MusicPlayerPage()
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

    // MARK: - 子视图

    private var emptyRow: some View {
        Text(isLoading ? "加载中..." : "这个收藏夹还没有歌曲")
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.subColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Dimens.bigIcon)
    }

    private var footer: some View {
        Text(hasMore ? "正在加载更多..." : "已经到底了")
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.subColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Dimens.middleMargin)
    }

    // MARK: - 计算属性

    private var hasMore: Bool {
        musics.count < total
    }

    // MARK: - 数据

    private func loadFirstPage() {
        guard !isLoading else { return }
        isLoading = true
        fetch(page: 1, replace: true)
    }

    private func loadMoreIfNeeded() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        fetch(page: pageNum + 1, replace: false)
    }

    @MainActor
    private func reload() async {
        await withCheckedContinuation { continuation in
            fetch(page: 1, replace: true) { continuation.resume() }
        }
    }

    private func fetch(page: Int, replace: Bool, completion: (() -> Void)? = nil) {
        HTTPClient.shared.getMusicListByFavoriteId(
            favoriteId: directory.id,
            pageNum: page,
            pageSize: pageSize
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let (list, totalCount)):
                    total = totalCount
                    if replace {
                        musics = list
                    } else {
                        musics.append(contentsOf: list)
                    }
                    pageNum = page
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
                completion?()
            }
        }
    }

    // MARK: - 交互

    /// 播放：收藏夹整张列表作为播放列表
    private func play(_ music: Music) {
        if playerState.currentMusic?.id != music.id {
            playerState.setMusic(music, autoPlay: true)
        } else if !playerState.isPlaying {
            playerState.play()
        }

        if playerState.classifyName != classifyName {
            HTTPClient.shared.getMusicListByFavoriteId(
                favoriteId: directory.id,
                pageNum: 1,
                pageSize: Constants.MusicConfig.maxPlaylistCount
            ) { result in
                DispatchQueue.main.async {
                    if case .success(let (list, _)) = result, !list.isEmpty {
                        playerState.setMusicList(list)
                        playerState.setClassifyName(classifyName)
                    }
                }
            }
        }

        showPlayerPage = true
    }

    /// 喜欢 / 取消喜欢（与其它页面一致，心形图标表示「喜欢」而不是「已收藏」）
    private func toggleLike(at index: Int) {
        guard musics.indices.contains(index) else { return }
        let music = musics[index]
        let wasLiked = (music.isLike ?? 0) == 1

        let handler: (Result<Int, NetworkError>) -> Void = { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let rows) where rows > 0:
                    musics[index].isLike = wasLiked ? 0 : 1
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

    /// 从当前收藏夹移除（长按歌曲行触发）
    /// 后端 `insertMusicFavorite` 是「先清空该歌所有收藏，再按传入的收藏夹重建」，
    /// 所以这里先取该歌所在的其他收藏夹，再提交剩下的，达到「只移出当前收藏夹」的效果。
    private func removeFromDirectory(at index: Int) {
        guard !isRemoving, musics.indices.contains(index) else { return }
        isRemoving = true

        let music = musics[index]

        HTTPClient.shared.getFavoriteDirectory(musicId: music.id) { result in
            var remainingIds: [Int] = []
            if case .success(let list) = result {
                remainingIds = list
                    .filter { ($0.checked ?? 0) == 1 && $0.id != directory.id }
                    .map { $0.id }
            }

            HTTPClient.shared.insertMusicFavorite(musicId: music.id, favoriteIds: remainingIds) { result in
                DispatchQueue.main.async {
                    isRemoving = false
                    switch result {
                    case .success:
                        if musics.indices.contains(index) {
                            musics.remove(at: index)
                            total = max(0, total - 1)
                        }
                        alertMessage = "已从收藏夹移除"
                    case .failure(let error):
                        alertMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

#Preview {
    FavoriteMusicPage(directory: FavoriteDirectory(id: 21, name: "车载音乐"))
}
