//
//  MusicHomePage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 首页可跳转的页面（除播放页 / 分类歌曲列表页外，其余先用占位页代替）
///
/// 「分类歌曲列表」需要携带被点击的模块，所以用关联值传参，
/// 避免依赖「先设置另一个 @State 再设置 route」这种跨状态时序（fullScreenCover 里读到旧值会拿到 nil）。
enum MusicDetailRoute: Identifiable {
    case search(String)  // 搜索页（携带首页推荐关键词，作为输入框提示）
    case authorCategory  // 歌手分类
    case categoryList    // 分类歌曲
    case classifyList(MusicCategory)   // 榜单歌曲列表（携带模块）
    case authorList(MusicAuthor)   // 歌手歌曲列表（携带歌手）
    case chat            // AI 聊天
    case user            // 个人中心
    case player          // 音乐播放页

    /// 唯一标识
    var id: String {
        switch self {
        case .search: return "search"
        case .authorCategory: return "authorCategory"
        case .categoryList: return "categoryList"
        case .classifyList(let category): return "classifyList-\(category.id)"
        case .authorList: return "authorList"
        case .chat: return "chat"
        case .user: return "user"
        case .player: return "player"
        }
    }

    /// 导航栏标题
    var title: String {
        switch self {
        case .search: return "搜索"
        case .authorCategory: return "歌手分类"
        case .categoryList: return "分类歌曲"
        case .classifyList: return "榜单歌曲"
        case .authorList: return "歌手歌曲"
        case .chat: return "AI 聊天"
        case .user: return "个人中心"
        case .player: return "音乐播放"
        }
    }
}

/// 首页 Tab 的正式内容
///
/// 对齐 uniapp `MusicHomeComponent` 与 flutter `MusicHomePage`：
/// 1. 顶部搜索栏（用户头像 + 推荐关键词 + AI 入口）
/// 2. 四个分类入口（歌手 / 分类歌曲 / 经典老歌 / 热门歌曲）
/// 3. 「推荐歌手」模块（默认 4 个歌手）
/// 4. 若干榜单模块（每个模块展示 3 首歌），初始加载 3 个模块，滚动到底再加 1 个
///
/// 接口：
/// - `GET /service/music/getKeywordMusic` 搜索框推荐关键词
/// - `GET /service/music/getMusicCategory` 分类模块列表
/// - `GET /service/music/getMusicListByCategoryId` 模块歌曲（模块组件内部各自请求）
/// - `GET /service/music/getMusicAuthorListByCategoryId` 推荐歌手（歌手模块内部请求）
struct MusicHomePage: View {
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var playerState = PlayerState.shared

    /// 搜索框展示的推荐关键词（「歌手 - 歌名」）
    @State private var keyword = ""
    /// 所有分类模块
    @State private var categories: [MusicCategory] = []
    /// 已展示的模块数量（滚动到底 +1）
    @State private var visibleCount = Constants.MusicConfig.homeModuleInitialCount
    /// 当前跳转的页面（nil 表示不跳转）
    @State private var route: MusicDetailRoute?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Dimens.middleMargin) {
                // 搜索栏
                MusicSearchBar(
                    keyword: keyword,
                    userAvatar: appState.userData?.avater,
                    onAvatarTap: { route = .user },
                    onSearchTap: { route = .search(keyword) },
                    onAITap: { route = .chat }
                )

                // 四个分类入口
                MusicCategoryEntryRow(
                    onSingerTap: { route = .authorCategory },
                    onCategoryTap: { route = .categoryList },
                    onClassicsTap: { openClassics() },
                    onRankTap: { openRank() }
                )

                // 榜单 / 推荐歌手模块
                ForEach(visibleCategories) { category in
                    moduleView(for: category)
                }

                // 底部提示（同时也是「加载更多」的触发器）
                bottomHint
            }
            .padding(.horizontal, Dimens.middleMargin)
            .padding(.vertical, Dimens.middleMargin)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.pageBackgroundColor)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            // 距离底部 200pt 以内视为「滚动到底」
            geometry.contentOffset.y + geometry.containerSize.height
                >= geometry.contentSize.height - 200
        } action: { _, isNearBottom in
            guard isNearBottom else { return }
            loadMoreIfNeeded()
        }
        .onAppear(perform: loadData)
        .fullScreenCover(item: $route) { route in
            switch route {
            case .player:
                MusicPlayerPage()
            case .search(let searchKeyword):
                // 搜索页（推荐关键词由 route 直接带过来）
                MusicSearchPage(keyword: searchKeyword)
            case .classifyList(let category):
                // 分类歌曲列表页（模块由 route 直接带过来）
                MusicClassifyListPage(category: category)
            case .authorList(let author):
                // 歌手歌曲列表页（歌手由 route 直接带过来）
                MusicAuthorListPage(author: author)
            case .categoryList:
                // 歌曲分类页
                MusicCategoryPage()
            case .authorCategory:
                // 歌手分类页
                MusicAuthorCategoryPage()
            case .chat:
                // AI 助手
                ChatPage()
            case .user:
                // 个人信息（首页搜索栏头像，对齐 uniapp 的 UserPage）
                EditUserInfoPage()
            }
        }
    }

    // MARK: - 视图组件

    /// 点首页「经典老歌」入口：进分类歌曲列表页，参数为 { id: 2, category: "经典老歌" }
    private func openClassics() {
        route = .classifyList(
            MusicCategory(
                id: Constants.MusicConfig.classicsCategoryId,
                category: Constants.MusicConfig.classicsCategoryName,
                classify: Constants.MusicConfig.classicsCategoryName
            )
        )
    }

    /// 点首页「热门歌曲」入口：进分类歌曲列表页，参数为 { id: 1, category: "热门歌曲" }
    private func openRank() {
        route = .classifyList(
            MusicCategory(
                id: Constants.MusicConfig.rankCategoryId,
                category: Constants.MusicConfig.rankCategoryName,
                classify: Constants.MusicConfig.rankCategoryName
            )
        )
    }

    /// 当前已展示的模块
    private var visibleCategories: [MusicCategory] {
        Array(categories.prefix(visibleCount))
    }

    /// 是否还有未展示的模块
    private var hasMore: Bool {
        visibleCount < categories.count
    }

    /// 单个模块：推荐歌手走歌手卡片，其余走歌曲卡片
    @ViewBuilder
    private func moduleView(for category: MusicCategory) -> some View {
        if category.isSingerModule {
            MusicSingerCard(
                category: category,
                onMore: { route = .authorCategory },
                onAuthorTap: { author in route = .authorList(author) }
            )
        } else {
            MusicModuleCard(
                category: category,
                onMore: { route = .classifyList(category) },
                onPlayMusic: { route = .player }
            )
        }
    }

    /// 底部提示文案
    private var bottomHint: some View {
        Text(hasMore ? "正在加载更多..." : "已经到底了")
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.subColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Dimens.middleMargin)
    }

    // MARK: - 数据

    /// 首次进入：加载关键词 + 分类模块
    private func loadData() {
        loadKeyword()
        loadCategories()
    }

    /// 加载搜索框推荐关键词
    private func loadKeyword() {
        guard keyword.isEmpty else { return }
        HTTPClient.shared.getKeywordMusic { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let music):
                    keyword = "\(music.displayAuthorName) - \(music.songName)"
                    // 对齐 flutter：还没有正在播放的歌时，用推荐歌曲作为「当前歌曲」（不自动播放）
                    if playerState.currentMusic == nil {
                        playerState.setMusic(music, autoPlay: false)
                    }
                case .failure(let error):
                    print("❌ 获取推荐关键词失败: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 加载首页所有分类模块
    private func loadCategories() {
        guard categories.isEmpty else { return }
        HTTPClient.shared.getMusicCategory { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let list):
                    categories = list
                    // 初始展示 3 个模块（不足 3 个时全展示）
                    visibleCount = min(Constants.MusicConfig.homeModuleInitialCount, list.count)
                case .failure(let error):
                    print("❌ 获取音乐分类失败: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 滚动到底：多展示一个模块
    private func loadMoreIfNeeded() {
        guard hasMore else { return }
        visibleCount += 1
    }
}

#Preview {
    MusicHomePage()
}
