//
//  MusicCategoryPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 歌曲分类页
///
/// 入口：首页四个分类入口里的「分类歌曲」。
///
/// 对齐 flutter `MusicCategoryPage.dart` 与 uniapp `MusicCategoryListPage.vue`：
/// - 导航栏标题「歌曲分类」
/// - 分类卡片：3 列网格，默认只展示前 9 个，可「展开更多 / 收起」；
///   选中项为主题色描边 + 主题色文字，未选中为灰色描边 + 黑字
/// - 切分类重新从第一页拉歌曲列表；滚动到底加载下一页，到底显示「已经到底了」
/// - 点歌：把该分类整张列表作为播放列表、classifyName 设为分类名后进播放页
///
/// 接口：
/// - `GET /service/music/getMusicCategory` 全部分类
/// - `GET /service/music/getMusicListByCategoryId` 分类下的歌曲
struct MusicCategoryPage: View {
    @ObservedObject private var playerState = PlayerState.shared

    /// 全部分类
    @State private var categories: [MusicCategory] = []
    /// 当前选中的分类下标
    @State private var activeIndex = 0
    /// 是否展开全部分类
    @State private var expand = false

    /// 歌曲列表
    @State private var musics: [Music] = []
    /// 当前页码
    @State private var pageNum = 1
    /// 总条数
    @State private var total = 0
    /// 是否正在请求
    @State private var isLoading = false
    /// 是否正在处理喜欢（防重复点击）
    @State private var isLikeLoading = false
    /// 是否展示播放页
    @State private var showPlayerPage = false
    /// 轻提示
    @State private var alertMessage: String?

    /// 默认展示的分类数量（对齐 flutter / uniapp 的 9 个）
    private let collapsedCount = 9
    private let pageSize = Constants.MusicConfig.pageSize

    var body: some View {
        VStack(spacing: 0) {
            MusicNavBar(title: "歌曲分类")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Dimens.middleMargin) {
                    categoryCard

                    if musics.isEmpty {
                        if isLoading {
                            loadingRow
                        } else if !categories.isEmpty {
                            emptyRow
                        }
                    } else {
                        MusicSongListCard(
                            musics: musics,
                            classifyName: activeCategoryName,
                            onPlay: { play($0) },
                            onLike: { toggleLike(at: $0) }
                        )
                        footer
                    }
                }
                .padding(Dimens.middleMargin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            if categories.isEmpty {
                loadCategories()
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

    /// 分类卡片（3 列网格 + 展开更多）
    private var categoryCard: some View {
        VStack(spacing: Dimens.middleMargin) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Dimens.smallMargin),
                               count: 3),
                spacing: Dimens.smallMargin
            ) {
                ForEach(Array(visibleCategories.enumerated()), id: \.element.id) { index, category in
                    categoryButton(category, index: index)
                }
            }

            // 展开更多 / 收起（分类数量超过 9 个才显示）
            if categories.count > collapsedCount {
                Button(action: { expand.toggle() }) {
                    HStack(spacing: Dimens.smallMargin) {
                        Text(expand ? "收起" : "展开更多")
                            .font(.system(size: Dimens.normalFont))
                            .foregroundColor(Colors.subColor)

                        Image("icon_arrow")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
                            .rotationEffect(.degrees(expand ? 90 : 0))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    /// 单个分类按钮（选中态主题色）
    private func categoryButton(_ category: MusicCategory, index: Int) -> some View {
        let isActive = index == activeIndex

        return Button(action: { selectCategory(at: index) }) {
            Text(category.category)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(isActive ? Colors.primaryColor : Colors.blackColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: Dimens.smallBtnHeight)
                .background(Colors.whiteColor)
                .cornerRadius(Dimens.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Dimens.borderRadius)
                        .stroke(isActive ? Colors.primaryColor : Colors.grayColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    /// 加载中
    private var loadingRow: some View {
        Text("加载中...")
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.subColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Dimens.largeMargin)
    }

    /// 空态
    private var emptyRow: some View {
        Text("该分类暂无歌曲")
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

    /// 当前展开状态下展示的分类
    private var visibleCategories: [MusicCategory] {
        expand ? categories : Array(categories.prefix(collapsedCount))
    }

    /// 当前选中分类的名称（作为播放列表名）
    private var activeCategoryName: String {
        guard categories.indices.contains(activeIndex) else { return "" }
        return categories[activeIndex].category
    }

    /// 当前选中分类的 id
    private var activeCategoryId: Int? {
        guard categories.indices.contains(activeIndex) else { return nil }
        return categories[activeIndex].id
    }

    /// 是否还有下一页
    private var hasMore: Bool {
        musics.count < total
    }

    // MARK: - 数据

    /// 加载全部分类，成功后默认拉第一个分类的歌曲
    private func loadCategories() {
        isLoading = true
        HTTPClient.shared.getMusicCategory { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let list):
                    categories = list
                    activeIndex = 0
                    loadFirstPage()
                case .failure(let error):
                    isLoading = false
                    alertMessage = error.localizedDescription
                }
            }
        }
    }

    /// 切分类：清空列表重新拉第一页
    private func selectCategory(at index: Int) {
        guard index != activeIndex, categories.indices.contains(index), !isLoading else { return }
        activeIndex = index
        musics = []
        total = 0
        pageNum = 1
        isLoading = true
        fetch(page: 1, replace: true)
    }

    /// 首次加载 / 切分类后加载第一页
    private func loadFirstPage() {
        guard activeCategoryId != nil else {
            isLoading = false
            return
        }
        isLoading = true
        fetch(page: 1, replace: true)
    }

    /// 下拉刷新：重拉分类 + 第一页
    @MainActor
    private func reload() async {
        await withCheckedContinuation { continuation in
            HTTPClient.shared.getMusicCategory { result in
                DispatchQueue.main.async {
                    if case .success(let list) = result {
                        categories = list
                        if activeIndex >= list.count { activeIndex = 0 }
                    }
                    fetch(page: 1, replace: true) {
                        continuation.resume()
                    }
                }
            }
        }
    }

    /// 拉取指定页（completion 可选，供下拉刷新等待）
    private func fetch(page: Int, replace: Bool, completion: (() -> Void)? = nil) {
        guard let categoryId = activeCategoryId else {
            isLoading = false
            completion?()
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
                completion?()
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
    /// 切歌立即播放；若当前播放列表不属于本分类，拉整张列表（500 条）作为播放列表
    private func play(_ music: Music) {
        if playerState.currentMusic?.id != music.id {
            playerState.setMusic(music, autoPlay: true)
        } else if !playerState.isPlaying {
            playerState.play()
        }

        if playerState.classifyName != activeCategoryName, let categoryId = activeCategoryId {
            HTTPClient.shared.getMusicListByCategoryId(
                categoryId: categoryId,
                pageNum: 1,
                pageSize: Constants.MusicConfig.maxPlaylistCount
            ) { result in
                DispatchQueue.main.async {
                    if case .success(let (list, _)) = result, !list.isEmpty {
                        playerState.setMusicList(list)
                        playerState.setClassifyName(activeCategoryName)
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
    MusicCategoryPage()
}
