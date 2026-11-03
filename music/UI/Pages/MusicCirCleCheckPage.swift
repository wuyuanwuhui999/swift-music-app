//
//  MusicCirCleCheckPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 选歌页（发音乐圈动态时挑选要分享的歌曲）
///
/// 入口：发布动态页「请选择一首歌曲」。
///
/// 对齐 uniapp `MusicCirCleCheckPage.vue`：
/// - 导航栏标题「选择音乐」
/// - 搜索框 + 搜索按钮，接口 `GET /service/music/searchMusic`
/// - 结果列表：封面 + 「歌手 - 歌名」，点某首歌即回填并返回发布页
struct MusicCirCleCheckPage: View {
    /// 选中歌曲的回调
    let onSelect: (Music) -> Void

    @Environment(\.dismiss) private var dismiss

    /// 搜索关键词
    @State private var keyword = ""
    /// 搜索结果
    @State private var musics: [Music] = []
    /// 当前页码
    @State private var pageNum = 1
    /// 总条数
    @State private var total = 0
    /// 是否正在请求
    @State private var isLoading = false
    /// 是否已经搜索过（控制「暂无数据」的展示）
    @State private var hasSearched = false
    /// 轻提示
    @State private var alertMessage: String?

    private let pageSize = Constants.MusicConfig.pageSize

    var body: some View {
        VStack(spacing: 0) {
            MusicNavBar(title: "选择音乐")

            searchRow

            ScrollView(.vertical, showsIndicators: false) {
                if musics.isEmpty {
                    emptyRow
                } else {
                    VStack(spacing: Dimens.middleMargin) {
                        MusicSongListCard(
                            musics: musics,
                            classifyName: Constants.MusicConfig.searchClassifyName,
                            onPlay: { music in
                                onSelect(music)
                                dismiss()
                            },
                            onLike: { index in likeTapped(at: index) }
                        )
                        footer
                    }
                    .padding(Dimens.middleMargin)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.containerSize.height
                    >= geometry.contentSize.height - 200
            } action: { _, isNearBottom in
                guard isNearBottom else { return }
                loadMoreIfNeeded()
            }
        }
        .background(Colors.pageBackgroundColor)
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

    /// 搜索栏
    private var searchRow: some View {
        HStack(spacing: Dimens.middleMargin) {
            TextField("请输入歌曲或者歌手名称", text: $keyword)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .submitLabel(.search)
                .onSubmit(search)
                .padding(.horizontal, Dimens.middleMargin)
                .frame(height: Dimens.smallBtnHeight)
                .background(Colors.whiteColor)
                .cornerRadius(Dimens.smallBtnHeight / 2)

            Button(action: search) {
                Image("icon_search")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Dimens.middleMargin)
        .padding(.vertical, Dimens.middleMargin)
    }

    /// 空态
    private var emptyRow: some View {
        Text(isLoading ? "加载中..." : (hasSearched ? "暂无数据" : "输入歌名或歌手名搜索"))
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.subColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Dimens.bigIcon)
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

    private var hasMore: Bool {
        musics.count < total
    }

    // MARK: - 数据

    /// 搜索（重置分页）
    private func search() {
        musics = []
        total = 0
        pageNum = 1
        hasSearched = true
        isLoading = true
        fetch(page: 1, replace: true)
    }

    /// 滚动到底加载更多
    private func loadMoreIfNeeded() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        fetch(page: pageNum + 1, replace: false)
    }

    /// 拉取搜索结果
    private func fetch(page: Int, replace: Bool) {
        let text = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        HTTPClient.shared.searchMusic(keyword: text, pageNum: page, pageSize: pageSize) { result in
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

    /// 喜欢 / 取消喜欢（列表行上的心形，与发布流程无关）
    private func likeTapped(at index: Int) {
        guard musics.indices.contains(index) else { return }
        let music = musics[index]
        let wasLiked = (music.isLike ?? 0) == 1

        let handler: (Result<Int, NetworkError>) -> Void = { result in
            DispatchQueue.main.async {
                if case .success(let rows) = result, rows > 0 {
                    musics[index].isLike = wasLiked ? 0 : 1
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
    MusicCirCleCheckPage(onSelect: { _ in })
}
