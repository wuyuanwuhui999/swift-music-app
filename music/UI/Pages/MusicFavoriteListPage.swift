//
//  MusicFavoriteListPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 我喜欢的歌曲（全部）
///
/// 入口：「我的」页「我喜欢的歌曲」标题栏的「更多」（超过 5 首时出现）。
///
/// 对齐 uniapp `FavoriteMusicPage.vue` / flutter `MusicFavoriteListPage.dart`：
/// 分页列表（每页 20 条），点歌播放，长按取消喜欢（取消后从列表中移除）。
///
/// 接口：
/// - `GET /service/music/getMusicLike?pageNum=&pageSize=`
/// - `DELETE /service/music/deleteMusicLike/{musicId}`
struct MusicFavoriteListPage: View {
    @ObservedObject private var playerState = PlayerState.shared

    /// 歌曲列表
    @State private var musics: [Music] = []
    /// 当前页码
    @State private var pageNum = 1
    /// 总条数
    @State private var total = 0
    /// 是否正在请求
    @State private var isLoading = false
    /// 是否正在取消喜欢
    @State private var isLikeLoading = false
    /// 展示播放页
    @State private var showPlayerPage = false
    /// 轻提示
    @State private var alertMessage: String?

    private let pageSize = Constants.MusicConfig.pageSize

    var body: some View {
        VStack(spacing: 0) {
            MusicNavBar(title: "我喜欢的歌曲")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Dimens.middleMargin) {
                    if musics.isEmpty {
                        emptyRow
                    } else {
                        MusicSongListCard(
                            musics: musics,
                            classifyName: "我喜欢的歌曲",
                            onPlay: { play($0) },
                            onLike: { cancelLike(at: $0) }
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
        Text(isLoading ? "加载中..." : "还没有喜欢的歌曲")
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
        HTTPClient.shared.getMusicLike(pageNum: page, pageSize: pageSize) { result in
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

    /// 播放：该页歌曲整体作为播放列表
    private func play(_ music: Music) {
        if playerState.currentMusic?.id != music.id {
            playerState.setMusic(music, autoPlay: true)
        } else if !playerState.isPlaying {
            playerState.play()
        }

        if playerState.classifyName != "我喜欢的歌曲" {
            HTTPClient.shared.getMusicLike(pageNum: 1, pageSize: Constants.MusicConfig.maxPlaylistCount) { result in
                DispatchQueue.main.async {
                    if case .success(let (list, _)) = result, !list.isEmpty {
                        playerState.setMusicList(list)
                        playerState.setClassifyName("我喜欢的歌曲")
                    }
                }
            }
        }

        showPlayerPage = true
    }

    /// 取消喜欢（成功后从列表移除并同步总数）
    private func cancelLike(at index: Int) {
        guard !isLikeLoading, musics.indices.contains(index) else { return }
        isLikeLoading = true

        let music = musics[index]
        HTTPClient.shared.deleteMusicLike(musicId: music.id) { result in
            DispatchQueue.main.async {
                isLikeLoading = false
                switch result {
                case .success(let rows) where rows > 0:
                    musics.remove(at: index)
                    total = max(0, total - 1)
                    alertMessage = "取消喜欢成功"
                case .success:
                    alertMessage = "取消喜欢失败"
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    MusicFavoriteListPage()
}
