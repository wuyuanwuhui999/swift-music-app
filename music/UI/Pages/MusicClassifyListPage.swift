//
//  MusicClassifyListPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 分类歌曲列表页
///
/// 首页某个模块标题栏点「更多」进入，展示该模块（榜单 / 分类）下的全部歌曲。
///
/// 对齐 flutter `MusicClassifyListPage.dart` 与 uniapp `MusicClassifyListPage.vue`：
/// - 顶部导航栏标题为模块名称
/// - 歌曲列表（封面 + 「歌手 - 歌名」+ 播放状态 + 喜欢 + 菜单）
/// - 滚动到底加载下一页，到底显示「已经到底了」
/// - 点歌：切歌立即播放；若当前播放列表不属于本模块，则拉整张列表作为播放列表后进播放页
///
/// 接口：`GET /service/music/getMusicListByCategoryId?categoryId=&pageNum=&pageSize=`
struct MusicClassifyListPage: View {
    /// 首页传进来的模块（榜单 / 分类）
    let category: MusicCategory

    @ObservedObject private var playerState = PlayerState.shared
    @Environment(\.dismiss) private var dismiss

    /// 歌曲列表
    @State private var musics: [Music] = []
    /// 当前页码（从 1 开始）
    @State private var pageNum = 1
    /// 接口返回的总条数
    @State private var total = 0
    /// 是否正在请求
    @State private var isLoading = false
    /// 是否正在处理喜欢（防重复点击）
    @State private var isLikeLoading = false
    /// 是否展示播放页
    @State private var showPlayerPage = false
    /// 轻提示
    @State private var alertMessage: String?

    private let pageSize = Constants.MusicConfig.pageSize

    var body: some View {
        VStack(spacing: 0) {
            MusicNavBar(title: category.category)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Dimens.middleMargin) {
                    if musics.isEmpty {
                        emptyView
                    } else {
                        musicList
                        footer
                    }
                }
                .padding(Dimens.middleMargin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await reload() }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                // 距离底部 200pt 以内视为「滚动到底」
                geometry.contentOffset.y + geometry.containerSize.height
                    >= geometry.contentSize.height - 200
            } action: { _, isNearBottom in
                guard isNearBottom else { return }
                loadMoreIfNeeded()
            }
        }
        .background(Colors.pageBackgroundColor)
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

    /// 歌曲列表（行之间画分割线，最后一行不画）
    private var musicList: some View {
        VStack(spacing: Dimens.middleMargin) {
            ForEach(Array(musics.enumerated()), id: \.element.id) { index, music in
                VStack(spacing: Dimens.middleMargin) {
                    MusicSongRow(
                        music: music,
                        classifyName: category.category,
                        onPlay: { play(music) },
                        onLike: { toggleLike(at: index) },
                        onMenu: {}
                    )

                    if index < musics.count - 1 {
                        Rectangle()
                            .fill(Colors.grayColor)
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    /// 空态 / 加载态
    private var emptyView: some View {
        Text(isLoading ? "加载中..." : "暂无歌曲")
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

    /// 首次加载
    private func loadFirstPage() {
        guard !isLoading else { return }
        isLoading = true
        fetch(page: 1, replace: true)
    }

    /// 下拉刷新
    @MainActor
    private func reload() async {
        await withCheckedContinuation { continuation in
            HTTPClient.shared.getMusicListByCategoryId(
                categoryId: category.id,
                pageNum: 1,
                pageSize: pageSize
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let (list, totalCount)):
                        musics = list
                        total = totalCount
                        pageNum = 1
                    case .failure(let error):
                        alertMessage = error.localizedDescription
                    }
                    continuation.resume()
                }
            }
        }
    }

    /// 拉取指定页
    private func fetch(page: Int, replace: Bool) {
        HTTPClient.shared.getMusicListByCategoryId(
            categoryId: category.id,
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

    /// 滚动到底加载下一页
    private func loadMoreIfNeeded() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        fetch(page: pageNum + 1, replace: false)
    }

    // MARK: - 交互

    /// 播放某首歌
    /// 对齐 flutter `usePlayRouter` / uniapp `usePlayMusic`：
    /// 切歌立即播放；若当前播放列表不属于本模块，拉整张列表（不做分页）作为播放列表
    private func play(_ music: Music) {
        if playerState.currentMusic?.id != music.id {
            playerState.setMusic(music, autoPlay: true)
        } else if !playerState.isPlaying {
            playerState.play()
        }

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

        showPlayerPage = true
    }

    /// 喜欢 / 取消喜欢
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
    MusicClassifyListPage(
        category: MusicCategory(id: 68, category: "酷狗飙升榜", classify: "热门榜单")
    )
}
