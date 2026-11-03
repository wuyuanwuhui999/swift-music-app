//
//  FavoriteAuthorListPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 我关注的歌手（全部）
///
/// 入口：「我的」页「我关注的歌手」标题栏的「更多」。
///
/// 参考 uniapp `MusicMyComponent` 的关注歌手列表与 `MusicAuthorCategoryPage` 的歌手行：
/// 头像 + 歌手名 + 「N首」+ 播放 / 关注图标，点播放进歌手歌曲列表，长按取消关注。
///
/// 接口：
/// - `GET /service/music/getFavoriteAuthor?pageNum=&pageSize=`
/// - `DELETE /service/music/deleteFavoriteAuthor/{authorId}`
struct FavoriteAuthorListPage: View {
    /// 歌手列表
    @State private var authors: [MusicAuthor] = []
    /// 当前页码
    @State private var pageNum = 1
    /// 总条数
    @State private var total = 0
    /// 是否正在请求
    @State private var isLoading = false
    /// 是否正在取消关注
    @State private var isLikeLoading = false
    /// 打开歌手歌曲列表
    @State private var authorRoute: MusicAuthor?
    /// 轻提示
    @State private var alertMessage: String?

    private let pageSize = Constants.MusicConfig.pageSize

    var body: some View {
        VStack(spacing: 0) {
            MusicNavBar(title: "我关注的歌手")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Dimens.middleMargin) {
                    if authors.isEmpty {
                        emptyRow
                    } else {
                        authorCard
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
            if authors.isEmpty { loadFirstPage() }
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

    // MARK: - 子视图

    /// 歌手列表（行间分割线，长按取消关注）
    private var authorCard: some View {
        VStack(spacing: Dimens.middleMargin) {
            ForEach(Array(authors.enumerated()), id: \.element.id) { index, author in
                VStack(spacing: Dimens.middleMargin) {
                    MusicAuthorRow(
                        author: author,
                        onTap: { authorRoute = author },
                        onLike: { cancelFollow(at: index) },
                        // getFavoriteAuthor 不返回 isLike / total：这里都是已关注歌手，且不展示「N首」
                        isFollowedOverride: true,
                        showsTotal: false
                    )
                    .onLongPressGesture { cancelFollow(at: index) }

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

    private var emptyRow: some View {
        Text(isLoading ? "加载中..." : "还没有关注的歌手")
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
        authors.count < total
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
        HTTPClient.shared.getFavoriteAuthor(pageNum: page, pageSize: pageSize) { result in
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

    // MARK: - 交互

    /// 取消关注（成功后从列表移除）
    private func cancelFollow(at index: Int) {
        guard !isLikeLoading, authors.indices.contains(index) else { return }
        isLikeLoading = true

        let author = authors[index]
        let authorId = author.authorId ?? author.id

        HTTPClient.shared.deleteFavoriteAuthor(authorId: authorId) { result in
            DispatchQueue.main.async {
                isLikeLoading = false
                switch result {
                case .success(let rows) where rows > 0:
                    authors.remove(at: index)
                    total = max(0, total - 1)
                    alertMessage = "取消关注成功"
                case .success:
                    alertMessage = "取消关注失败"
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    FavoriteAuthorListPage()
}
