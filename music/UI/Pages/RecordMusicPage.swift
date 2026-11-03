//
//  RecordMusicPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 播放记录（全部）
///
/// 入口：「我的」页「最近播放」标题栏的「更多」（超过 10 条时出现）。
///
/// 对齐 uniapp `RecordMusicPage.vue` / flutter `RecordMusicPage.dart`：
/// 分页列表，每行展示「歌手 - 歌名」+「听过N次」，点歌播放。
/// 后端没有删除播放记录的接口，因此这里不提供删除。
///
/// 接口：`GET /service/music/getMusicRecord?pageNum=&pageSize=`
struct RecordMusicPage: View {
    @ObservedObject private var playerState = PlayerState.shared

    /// 歌曲列表
    @State private var musics: [Music] = []
    /// 当前页码
    @State private var pageNum = 1
    /// 总条数
    @State private var total = 0
    /// 是否正在请求
    @State private var isLoading = false
    /// 展示播放页
    @State private var showPlayerPage = false
    /// 轻提示
    @State private var alertMessage: String?

    private let pageSize = Constants.MusicConfig.pageSize

    var body: some View {
        VStack(spacing: 0) {
            MusicNavBar(title: "播放记录")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Dimens.middleMargin) {
                    if musics.isEmpty {
                        emptyRow
                    } else {
                        recordCard
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

    /// 记录列表（「听过N次」副标题 + 行间分割线）
    private var recordCard: some View {
        VStack(spacing: Dimens.middleMargin) {
            ForEach(Array(musics.enumerated()), id: \.element.id) { index, music in
                VStack(spacing: Dimens.middleMargin) {
                    MusicUserListRow(
                        cover: music.cover,
                        fallbackText: music.songName,
                        title: "\(music.displayAuthorName) - \(music.songName)",
                        subtitle: "听过\(music.times ?? 0)次",
                        onPlay: { play(music) }
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

    private var emptyRow: some View {
        Text(isLoading ? "加载中..." : "还没有播放记录")
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
        HTTPClient.shared.getMusicRecord(pageNum: page, pageSize: pageSize) { result in
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

    /// 播放：整页记录作为播放列表
    private func play(_ music: Music) {
        if playerState.currentMusic?.id != music.id {
            playerState.setMusic(music, autoPlay: true)
        } else if !playerState.isPlaying {
            playerState.play()
        }

        if playerState.classifyName != "播放记录" {
            HTTPClient.shared.getMusicRecord(pageNum: 1, pageSize: Constants.MusicConfig.maxPlaylistCount) { result in
                DispatchQueue.main.async {
                    if case .success(let (list, _)) = result, !list.isEmpty {
                        playerState.setMusicList(list)
                        playerState.setClassifyName("播放记录")
                    }
                }
            }
        }

        showPlayerPage = true
    }
}

#Preview {
    RecordMusicPage()
}
