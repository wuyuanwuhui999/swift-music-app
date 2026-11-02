//
//  MusicSearchPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 歌曲搜索页
///
/// 首页点搜索框进入，搜索框里的推荐关键词作为输入框提示语。
///
/// 对齐 flutter `MusicSearchPage.dart` 与 uniapp `MusicSearchPage.vue`：
/// - 顶部搜索栏：圆角输入框 + 清除图标 + 「搜索」按钮
/// - 未搜索时展示「历史搜索」（最多 20 条，本地持久化，逗号分隔），没有则显示「暂无搜索记录」
/// - 搜索后展示歌曲列表（复用 `MusicSongListCard`，内部是 `MusicSongRow`），滚动到底加载下一页，到底显示「已经到底了」
/// - 点歌：把搜索结果作为播放列表、模块名设为「搜索」后进播放页
///
/// 接口：`GET /service/music/searchMusic?keyword=&pageNum=&pageSize=`
struct MusicSearchPage: View {
    /// 首页搜索框里的推荐关键词（输入框为空时用它兜底）
    let keyword: String

    @ObservedObject private var playerState = PlayerState.shared

    /// 输入框内容
    @State private var input = ""
    /// 是否已发起搜索（false 展示历史记录）
    @State private var searching = false
    /// 是否正在请求
    @State private var isLoading = false
    /// 搜索结果
    @State private var musics: [Music] = []
    /// 当前页码
    @State private var pageNum = 1
    /// 总条数
    @State private var total = 0
    /// 搜索历史
    @State private var history: [String] = []
    /// 是否正在处理喜欢（防重复点击）
    @State private var isLikeLoading = false
    /// 是否展示播放页
    @State private var showPlayerPage = false
    /// 轻提示
    @State private var alertMessage: String?

    private let pageSize = Constants.MusicConfig.pageSize

    var body: some View {
        VStack(spacing: 0) {
            MusicNavBar(title: "搜索")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Dimens.middleMargin) {
                    searchBar

                    if searching {
                        if isLoading && musics.isEmpty {
                            loadingRow
                        } else if musics.isEmpty {
                            emptyRow
                        } else {
                            resultCard
                            footer
                        }
                    } else {
                        historyCard
                    }
                }
                .padding(Dimens.middleMargin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollDismissesKeyboard(.interactively)
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
        .onAppear(perform: loadHistory)
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

    // MARK: - 搜索栏

    /// 顶部搜索栏：输入框 + 清除 + 搜索按钮
    private var searchBar: some View {
        HStack(spacing: Dimens.smallMargin) {
            HStack(spacing: Dimens.smallMargin) {
                TextField("", text: $input, prompt: Text(keyword)
                    .foregroundColor(Colors.grayColor))
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.blackColor)
                    .submitLabel(.search)
                    .onSubmit(search)
                    .padding(.leading, Dimens.middleMargin)

                // 清除（有内容才显示）
                if !input.isEmpty {
                    Button(action: clear) {
                        Image("icon_clear")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, Dimens.smallMargin)
                }
            }
            .frame(height: Dimens.btnHeight)
            .background(Colors.pageBackgroundColor)
            .cornerRadius(Dimens.btnHeight / 2)

            Button(action: search) {
                Text("搜索")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.whiteColor)
                    .frame(width: Dimens.btnHeight * 1.6, height: Dimens.btnHeight)
                    .background(Colors.primaryColor)
                    .cornerRadius(Dimens.btnHeight / 2)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    // MARK: - 历史搜索

    /// 历史搜索卡片
    private var historyCard: some View {
        VStack(alignment: .leading, spacing: Dimens.middleMargin) {
            Text("历史搜索")
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)

            if history.isEmpty {
                Text("暂无搜索记录")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.grayColor)
                    .frame(maxWidth: .infinity, minHeight: Dimens.middleAvater * 2)
            } else {
                FlowLayout(spacing: Dimens.smallMargin, lineSpacing: Dimens.smallMargin) {
                    ForEach(history, id: \.self) { item in
                        Button(action: { searchHistory(item) }) {
                            Text(item)
                                .font(.system(size: Dimens.normalFont))
                                .foregroundColor(Colors.subColor)
                                .lineLimit(1)
                                .padding(.horizontal, Dimens.middleMargin)
                                .padding(.vertical, Dimens.smallMargin)
                                .background(Colors.pageBackgroundColor)
                                .cornerRadius(Dimens.smallMargin)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Dimens.middleMargin)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    // MARK: - 搜索结果

    /// 结果列表（复用通用列表卡片）
    private var resultCard: some View {
        MusicSongListCard(
            musics: musics,
            classifyName: Constants.MusicConfig.searchClassifyName,
            onPlay: { play($0) },
            onLike: { toggleLike(at: $0) }
        )
    }

    /// 加载中
    private var loadingRow: some View {
        Text("搜索中...")
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.subColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Dimens.largeMargin)
    }

    /// 无结果
    private var emptyRow: some View {
        Text("没有找到相关歌曲")
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

    // MARK: - 搜索

    /// 点搜索按钮 / 键盘回车
    private func search() {
        guard !isLoading else { return }

        var kw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        // 输入为空时用首页的推荐关键词兜底（对齐 flutter / uniapp）
        if kw.isEmpty {
            kw = keyword
        }
        guard !kw.isEmpty else { return }

        input = kw
        saveHistory(kw)
        searching = true
        isLoading = true
        musics = []
        pageNum = 1
        fetch(page: 1, replace: true)
    }

    /// 点历史记录直接搜
    private func searchHistory(_ text: String) {
        input = text
        search()
    }

    /// 清除输入（回到历史记录）
    private func clear() {
        guard !isLoading else { return }
        input = ""
        searching = false
        musics = []
        total = 0
        pageNum = 1
    }

    /// 加载下一页
    private func loadMoreIfNeeded() {
        guard searching, !isLoading, hasMore else { return }
        isLoading = true
        fetch(page: pageNum + 1, replace: false)
    }

    /// 请求搜索结果
    private func fetch(page: Int, replace: Bool) {
        let kw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        HTTPClient.shared.searchMusic(keyword: kw, pageNum: page, pageSize: pageSize) { result in
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

    // MARK: - 搜索历史读写

    /// 读取历史（逗号分隔，最多 20 条）
    private func loadHistory() {
        let raw = UserDefaults.standard.string(forKey: Constants.StorageKey.musicSearchHistory) ?? ""
        history = raw.split(separator: ",")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }

    /// 保存历史：已存在则提到最前，否则插到最前，最多保留 20 条
    private func saveHistory(_ text: String) {
        history.removeAll { $0 == text }
        history.insert(text, at: 0)
        if history.count > Constants.MusicConfig.searchHistoryMax {
            history = Array(history.prefix(Constants.MusicConfig.searchHistoryMax))
        }
        UserDefaults.standard.set(history.joined(separator: ","), forKey: Constants.StorageKey.musicSearchHistory)
    }

    // MARK: - 交互

    /// 播放某首歌：搜索结果作为播放列表，模块名记为「搜索」
    private func play(_ music: Music) {
        if !musics.isEmpty {
            playerState.setMusicList(musics)
        }
        playerState.setClassifyName(Constants.MusicConfig.searchClassifyName)
        playerState.setMusic(music, autoPlay: true)
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
    MusicSearchPage(keyword: "赵乃吉 - 黄昏")
}
