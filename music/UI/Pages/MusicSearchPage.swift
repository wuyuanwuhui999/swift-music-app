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
/// - 自定义导航栏：中间显示搜索模式（普通搜索 / 智能搜索），带下拉三角；
///   智能搜索时再显示「｜ + 模型名称 + 下拉三角」，点模型名可切换模型
/// - 顶部搜索栏：圆角输入框 + 清除图标 + 「搜索」按钮
/// - 未搜索时展示「历史搜索」（最多 20 条，本地持久化，逗号分隔），没有则显示「暂无搜索记录」
/// - 搜索后展示歌曲列表（复用 `MusicSongListCard`，内部是 `MusicSongRow`），滚动到底加载下一页，到底显示「已经到底了」
/// - 点歌：把搜索结果作为播放列表、模块名设为「搜索」后进播放页
///
/// 接口：
/// - `GET /service/music/searchMusic?keyword=&pageNum=&pageSize=&searchMode=&modelId=&searchId=`
///   smart 模式必传 `modelId`（`getModelList` 返回的模型 id）与 `searchId`（32 位 UUID，分页沿用同一个）
/// - `GET /service/chat/getModelList` 智能搜索用的模型列表
struct MusicSearchPage: View {
    /// 首页搜索框里的推荐关键词（输入框为空时用它兜底）
    let keyword: String

    @ObservedObject private var playerState = PlayerState.shared
    @Environment(\.dismiss) private var dismiss

    /// 搜索模式（普通 / 智能）
    @State private var searchMode: SearchMode = .normal
    /// 可用模型列表（智能搜索用）
    @State private var models: [ChatModel] = []
    /// 当前选中的模型下标
    @State private var selectedModelIndex = 0
    /// 是否展示搜索模式选择
    @State private var showModeMenu = false
    /// 是否展示模型选择
    @State private var showModelMenu = false
    /// 智能搜索会话 id（32 位 UUID，同一关键词分页时保持不变）
    @State private var searchId = ""
    /// 上次搜索时的「模式 + 模型 + 关键词」指纹，用于判断是否需要重新生成 searchId
    @State private var lastSearchSignature = ""

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
            navBar

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
        .onAppear {
            loadHistory()
            loadModels()
        }
        .confirmationDialog("搜索模式", isPresented: $showModeMenu, titleVisibility: .visible) {
            ForEach(SearchMode.allCases) { mode in
                Button(mode.title) { selectMode(mode) }
            }
            Button("取消", role: .cancel) {}
        }
        .confirmationDialog("选择模型", isPresented: $showModelMenu, titleVisibility: .visible) {
            ForEach(Array(models.enumerated()), id: \.element.id) { index, model in
                Button(model.modelName) { selectModel(at: index) }
            }
            Button("取消", role: .cancel) {}
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

    // MARK: - 导航栏

    /// 自定义导航栏：返回 + 中间「搜索模式（｜模型名）」
    private var navBar: some View {
        ZStack {
            // 中间：搜索模式（可点切换）
            HStack(spacing: Dimens.smallMargin) {
                Button(action: { showModeMenu = true }) {
                    HStack(spacing: Dimens.smallMargin) {
                        Text(searchMode.title)
                            .font(.system(size: Dimens.middleFont))
                            .foregroundColor(Colors.blackColor)

                        downTriangle
                    }
                }
                .buttonStyle(.plain)

                // 智能搜索才显示「｜ 模型名称」
                if searchMode == .smart {
                    Text("｜")
                        .font(.system(size: Dimens.middleFont))
                        .foregroundColor(Colors.grayColor)

                    Button(action: { showModelMenu = true }) {
                        HStack(spacing: Dimens.smallMargin) {
                            Text(modelName)
                                .font(.system(size: Dimens.normalFont))
                                .foregroundColor(Colors.subColor)
                                .lineLimit(1)

                            downTriangle
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Dimens.navBarHeight)

            // 左侧返回
            HStack {
                Button(action: { dismiss() }) {
                    Image("icon_back")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
                        .foregroundColor(Colors.blackColor)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, Dimens.middleMargin)
        }
        .frame(height: Dimens.navBarHeight)
        .frame(maxWidth: .infinity)
        .background(Colors.whiteColor)
    }

    /// 下拉三角（可点击的提示图标）
    private var downTriangle: some View {
        Image("icon_down")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Dimens.smallIcon * 0.7, height: Dimens.smallIcon * 0.7)
            .opacity(0.6)
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

    /// 当前选中模型的名称（未加载到模型时显示占位）
    private var modelName: String {
        guard models.indices.contains(selectedModelIndex) else { return "模型加载中" }
        return models[selectedModelIndex].modelName
    }

    /// 当前选中模型的 id（智能搜索要传给后端）
    private var modelId: String? {
        guard models.indices.contains(selectedModelIndex) else { return nil }
        return models[selectedModelIndex].id
    }

    /// 当前搜索指纹：模式 + 模型 + 关键词，任一项变化都要换新的 searchId
    private func signature(keyword: String) -> String {
        "\(searchMode.rawValue)|\(modelId ?? "")|\(keyword)"
    }

    /// 生成 32 位 UUID（去掉连字符）
    private func makeSearchId() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    /// 切换搜索模式
    private func selectMode(_ mode: SearchMode) {
        guard mode != searchMode else { return }
        searchMode = mode
        // 切到智能搜索时确保模型列表已加载
        if mode == .smart, models.isEmpty {
            loadModels()
        }
    }

    /// 选择模型
    private func selectModel(at index: Int) {
        guard models.indices.contains(index) else { return }
        selectedModelIndex = index
    }

    /// 拉取智能搜索可用的模型列表（取 `getModelList` 的第一条作为默认）
    private func loadModels() {
        guard models.isEmpty else { return }
        HTTPClient.shared.getModelList(companyId: Constants.ChatConfig.companyId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (list, _)):
                    // 与 AI 助手一致：ollama 类型优先（后端 chat 不支持 online 类型）
                    let usable = list.filter { ($0.disabled ?? 0) == 0 }
                    let local = usable.filter { $0.type != "online" }
                    let online = usable.filter { $0.type == "online" }
                    models = local + online
                    selectedModelIndex = 0
                case .failure(let error):
                    print("⚠️ 获取模型列表失败: \(error.localizedDescription)")
                }
            }
        }
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

        // 关键词 / 搜索模式 / 模型变了才换新的会话 id；同一关键词翻页沿用同一个 searchId
        let currentSignature = signature(keyword: kw)
        if currentSignature != lastSearchSignature || searchId.isEmpty {
            searchId = makeSearchId()
            lastSearchSignature = currentSignature
        }

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
        // 清空后重新搜索视为新会话
        lastSearchSignature = ""
        searchId = ""
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
        HTTPClient.shared.searchMusic(
            keyword: kw,
            pageNum: page,
            pageSize: pageSize,
            searchMode: searchMode.rawValue,
            modelId: modelId,
            searchId: searchId.isEmpty ? nil : searchId
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
