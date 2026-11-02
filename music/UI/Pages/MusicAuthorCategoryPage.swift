//
//  MusicAuthorCategoryPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 歌手分类页
///
/// 入口：首页四个分类入口里的「歌手」、首页「推荐歌手」模块的「更多」。
///
/// 对齐 flutter `MusicAuthorCategoryPage.dart` 与 uniapp `MusicAuthorCategoryPage.vue`：
/// - 导航栏标题「歌手分类」
/// - 分类网格：4 列（华语 / 华语男歌手 / 欧美组合 …），选中项主题色描边 + 主题色文字
/// - 歌手列表：圆形头像 + 歌手名 + 「N首」+ 播放 / 关注 / 菜单，行间分割线
/// - 分页加载、下拉刷新；点歌手进「歌手歌曲列表页」，点关注走关注 / 取消关注接口
///
/// 接口：
/// - `GET /service/music/getMusicAuthorCategory` 歌手分类
/// - `GET /service/music/getMusicAuthorListByCategoryId` 分类下的歌手
/// - `POST /service/music/insertFavoriteAuthor/{authorId}` / `DELETE .../deleteFavoriteAuthor/{authorId}`
struct MusicAuthorCategoryPage: View {
    @ObservedObject private var playerState = PlayerState.shared

    /// 歌手分类
    @State private var categories: [MusicAuthorCategory] = []
    /// 当前选中的分类下标
    @State private var activeIndex = 0
    /// 歌手列表
    @State private var authors: [MusicAuthor] = []
    /// 当前页码
    @State private var pageNum = 1
    /// 总条数
    @State private var total = 0
    /// 是否正在请求
    @State private var isLoading = false
    /// 是否正在关注 / 取关（防重复点击）
    @State private var isLikeLoading = false
    /// 点歌手要打开的歌手歌曲列表页
    @State private var authorRoute: MusicAuthor?
    /// 轻提示
    @State private var alertMessage: String?

    private let pageSize = Constants.MusicConfig.pageSize

    var body: some View {
        VStack(spacing: 0) {
            MusicNavBar(title: "歌手分类")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Dimens.middleMargin) {
                    categoryCard

                    if authors.isEmpty {
                        if isLoading {
                            loadingRow
                        } else if !categories.isEmpty {
                            emptyRow
                        }
                    } else {
                        authorList
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
        .fullScreenCover(item: $authorRoute) { author in
            MusicAuthorListPage(author: author)
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

    /// 分类网格（4 列，对齐 flutter crossAxisCount = 4）
    private var categoryCard: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Dimens.smallMargin), count: 4),
            spacing: Dimens.smallMargin
        ) {
            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                categoryButton(category, index: index)
            }
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    /// 单个分类按钮（选中态主题色）
    private func categoryButton(_ category: MusicAuthorCategory, index: Int) -> some View {
        let isActive = index == activeIndex

        return Button(action: { selectCategory(at: index) }) {
            Text(category.categoryName)
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

    /// 歌手列表（行间画分割线，最后一行不画）
    private var authorList: some View {
        VStack(spacing: Dimens.middleMargin) {
            ForEach(Array(authors.enumerated()), id: \.element.id) { index, author in
                VStack(spacing: Dimens.middleMargin) {
                    MusicAuthorRow(
                        author: author,
                        onTap: { authorRoute = author },
                        onLike: { toggleLike(at: index) }
                    )

                    if index < authors.count - 1 {
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
        Text("该分类暂无歌手")
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

    /// 当前选中的分类 id
    private var activeCategoryId: Int? {
        guard categories.indices.contains(activeIndex) else { return nil }
        return categories[activeIndex].id
    }

    /// 是否还有下一页
    private var hasMore: Bool {
        authors.count < total
    }

    // MARK: - 数据

    /// 加载分类，成功后拉第一个分类的歌手
    private func loadCategories() {
        isLoading = true
        HTTPClient.shared.getMusicAuthorCategory { result in
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

    /// 切分类
    private func selectCategory(at index: Int) {
        guard index != activeIndex, categories.indices.contains(index), !isLoading else { return }
        activeIndex = index
        authors = []
        total = 0
        pageNum = 1
        isLoading = true
        fetch(page: 1, replace: true)
    }

    /// 拉第一页
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
            HTTPClient.shared.getMusicAuthorCategory { result in
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

    /// 拉取指定页
    private func fetch(page: Int, replace: Bool, completion: (() -> Void)? = nil) {
        guard let categoryId = activeCategoryId else {
            isLoading = false
            completion?()
            return
        }
        HTTPClient.shared.getMusicAuthorListByCategoryId(
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
                        authors = list
                    } else {
                        authors.append(contentsOf: list)
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

    /// 关注 / 取消关注歌手
    private func toggleLike(at index: Int) {
        guard !isLikeLoading, authors.indices.contains(index) else { return }

        let author = authors[index]
        let authorId = author.authorId ?? author.id
        let wasLiked = (author.isLike ?? 0) == 1

        isLikeLoading = true
        let handler: (Result<Int, NetworkError>) -> Void = { result in
            DispatchQueue.main.async {
                isLikeLoading = false
                switch result {
                case .success(let rows) where rows > 0:
                    authors[index].isLike = wasLiked ? 0 : 1
                    alertMessage = wasLiked ? "取消收藏成功" : "收藏成功"
                case .success:
                    alertMessage = wasLiked ? "取消收藏失败" : "收藏失败"
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }

        if wasLiked {
            HTTPClient.shared.deleteFavoriteAuthor(authorId: authorId, completion: handler)
        } else {
            HTTPClient.shared.insertFavoriteAuthor(authorId: authorId, completion: handler)
        }
    }
}

#Preview {
    MusicAuthorCategoryPage()
}
