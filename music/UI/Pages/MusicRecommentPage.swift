//
//  MusicRecommentPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 推荐 Tab
///
/// 对齐 flutter `MusicRecommentPage.dart` 与 uniapp `MusicRecommentComponent.vue`：
/// 一个带名次的推荐歌曲列表（前三名奖牌图标），下拉刷新、滚动到底加载更多，
/// 点击播放会切歌并把整个列表作为播放列表带进播放页。
///
/// 分类来源：uniapp 里写死 `categoryId = 1`，但后端 music_category 的自增 id 从 68 开始，
/// 该分类不存在，接口永远返回空列表（页面空白）。这里按 flutter 的修正版实现：
/// 先 `getMusicCategory` 取第一个分类，再用它的 id 拉歌曲。
struct MusicRecommentPage: View {
    @ObservedObject private var playerState = PlayerState.shared

    /// 推荐歌曲列表
    @State private var musics: [Music] = []
    /// 当前页码（从 1 开始）
    @State private var pageNum = 1
    /// 接口返回的总条数
    @State private var total = 0
    /// 已解析出的分类 id
    @State private var categoryId: Int?
    /// 是否正在请求
    @State private var isLoading = false
    /// 是否展示播放页
    @State private var showPlayerPage = false
    /// 点赞请求中（防重复点击）
    @State private var isLikeLoading = false
    /// 轻提示
    @State private var alertMessage: String?

    /// 每页数量
    private let pageSize = Constants.MusicConfig.pageSize

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: Dimens.middleMargin) {
                if musics.isEmpty {
                    emptyView
                } else {
                    ForEach(Array(musics.enumerated()), id: \.element.id) { index, music in
                        MusicRankRow(
                            music: music,
                            index: index,
                            classifyName: Constants.MusicConfig.recommendClassifyName,
                            onPlay: { play(music) },
                            onLike: { toggleLike(at: index) },
                            onMenu: {}
                        )
                    }

                    // 底部提示（同时也是「加载更多」的位置提示）
                    footer
                }
            }
            .padding(.horizontal, Dimens.middleMargin)
            .padding(.vertical, Dimens.middleMargin)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.pageBackgroundColor)
        .refreshable {
            // 下拉刷新：回到第一页
            await reload()
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            // 距离底部 200pt 以内视为「滚动到底」
            geometry.contentOffset.y + geometry.containerSize.height
                >= geometry.contentSize.height - 200
        } action: { _, isNearBottom in
            guard isNearBottom else { return }
            loadMoreIfNeeded()
        }
        .onAppear {
            if musics.isEmpty {
                loadFirstPage()
            }
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

    // MARK: - 视图组件

    /// 空态 / 加载态
    private var emptyView: some View {
        Text(isLoading ? "加载中..." : "暂无推荐歌曲")
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.subColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Dimens.largeMargin)
    }

    /// 底部提示
    private var footer: some View {
        Text(hasMore ? "正在加载更多..." : "已经到底了")
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.subColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Dimens.middleMargin)
    }

    // MARK: - 计算属性

    /// 是否还有下一页
    private var hasMore: Bool {
        musics.count < total
    }

    // MARK: - 数据

    /// 首次加载：解析分类 → 拉第一页
    private func loadFirstPage() {
        guard !isLoading else { return }
        isLoading = true
        resolveCategoryId { id in
            guard let id = id else {
                isLoading = false
                return
            }
            categoryId = id
            fetch(page: 1, replace: true)
        }
    }

    /// 下拉刷新
    @MainActor
    private func reload() async {
        // 刷新时保留已解析的分类，只重新拉第一页
        await withCheckedContinuation { continuation in
            resolveCategoryId { id in
                guard let id = id else {
                    continuation.resume()
                    return
                }
                categoryId = id
                HTTPClient.shared.getMusicListByCategoryId(
                    categoryId: id,
                    pageNum: 1,
                    pageSize: pageSize
                ) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let (list, totalCount)):
                            total = totalCount
                            musics = list
                            pageNum = 1
                        case .failure(let error):
                            alertMessage = error.localizedDescription
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }

    /// 解析推荐分类 id（取第一个分类；已解析过则直接用）
    private func resolveCategoryId(completion: @escaping (Int?) -> Void) {
        if let categoryId = categoryId {
            completion(categoryId)
            return
        }
        HTTPClient.shared.getMusicCategory { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let list):
                    completion(list.first?.id)
                case .failure(let error):
                    print("❌ 解析推荐分类失败: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }

    /// 拉取指定页
    private func fetch(page: Int, replace: Bool) {
        guard let categoryId = categoryId else {
            isLoading = false
            return
        }
        HTTPClient.shared.getMusicListByCategoryId(
            categoryId: categoryId,
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
            }
        }
    }

    /// 滚动到底：加载下一页
    private func loadMoreIfNeeded() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        fetch(page: pageNum + 1, replace: false)
    }

    // MARK: - 交互

    /// 播放某首歌
    /// 对齐 uniapp `usePlayMusicList`：切歌立即播放；若当前播放列表不是「推荐歌曲」，
    /// 则把整个推荐列表（最多 500 首）拉下来作为播放列表，再进播放页。
    private func play(_ music: Music) {
        let classifyName = Constants.MusicConfig.recommendClassifyName

        if playerState.currentMusic?.id != music.id {
            playerState.setMusic(music, autoPlay: true)

            if playerState.classifyName != classifyName, let categoryId = categoryId {
                HTTPClient.shared.getMusicListByCategoryId(
                    categoryId: categoryId,
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
            } else {
                playerState.setClassifyName(classifyName)
            }
        }
        showPlayerPage = true
    }

    /// 点赞 / 取消点赞
    private func toggleLike(at index: Int) {
        guard !isLikeLoading, musics.indices.contains(index) else { return }
        isLikeLoading = true

        let music = musics[index]
        let wasLiked = (music.isLike ?? 0) == 1

        let handler: (Result<Int, NetworkError>) -> Void = { result in
            DispatchQueue.main.async {
                isLikeLoading = false
                switch result {
                case .success(let rows) where rows > 0:
                    musics[index].isLike = wasLiked ? 0 : 1
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
    MusicRecommentPage()
}
