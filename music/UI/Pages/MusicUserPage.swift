//
//  MusicUserPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 「我的」页可跳转的二级页面
///
/// 注意：`favoriteDirectory` 带关联值，所以不能再用 `String` 原始值，
/// 统一用 `id` 做 `Identifiable` 的标识。
enum MusicUserRoute: Identifiable {
    case profile                        // 个人信息（编辑资料）
    case favoriteDirectory(FavoriteDirectory)  // 收藏夹详情（携带收藏夹）
    case likedMusic                     // 我喜欢的歌曲（全部）
    case favoriteAuthor                 // 我关注的歌手（全部）
    case record                         // 播放记录（全部）

    var id: String {
        switch self {
        case .profile: return "profile"
        case .favoriteDirectory(let directory): return "favoriteDirectory-\(directory.id)"
        case .likedMusic: return "likedMusic"
        case .favoriteAuthor: return "favoriteAuthor"
        case .record: return "record"
        }
    }

    var title: String {
        switch self {
        case .profile: return "个人信息"
        case .favoriteDirectory: return "收藏夹详情"
        case .likedMusic: return "我喜欢的歌曲"
        case .favoriteAuthor: return "我关注的歌手"
        case .record: return "播放记录"
        }
    }
}

/// 待删除项
private struct DeleteTarget: Identifiable {
    enum Kind {
        case directory   // 收藏夹
        case likedMusic  // 喜欢的歌曲
        case author      // 关注的歌手
        case record      // 播放记录
    }

    let kind: Kind
    /// 列表下标
    let index: Int
    /// 业务 id（收藏夹 id / 歌曲 id / 歌手 authorId）
    let businessId: Int
    /// 展示名称
    let name: String

    /// 列表唯一标识
    var id: String { "\(kind)-\(index)-\(businessId)" }
}

/// 我的 Tab
///
/// 对齐 flutter `MusicUserPage.dart` 与 uniapp `MusicMyComponent.vue`：
/// 1. 用户信息卡（头像 / 昵称 / 签名 / 编辑入口）
/// 2. 我的收藏夹（新建 / 刷新 / 列表 / 删除）
/// 3. 我喜欢的歌曲（刷新 / 更多 / 列表 / 删除）
/// 4. 我关注的歌手（刷新 / 更多 / 列表 / 取消关注）
/// 5. 我最近播放的歌曲（刷新 / 更多 / 列表 / 删除）
///
/// 各模块都可折叠；删除操作用长按菜单（替代 flutter 的左滑删除）。
struct MusicUserPage: View {
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var playerState = PlayerState.shared

    // 数据
    @State private var directories: [FavoriteDirectory] = []
    @State private var likedMusics: [Music] = []
    @State private var likedTotal = 0
    @State private var favoriteAuthors: [MusicAuthor] = []
    @State private var authorTotal = 0
    @State private var records: [Music] = []
    @State private var recordTotal = 0

    // 折叠状态
    @State private var isDirectoryFolded = false
    @State private var isLikedFolded = false
    @State private var isAuthorFolded = false
    @State private var isRecordFolded = false

    // 交互状态
    @State private var route: MusicUserRoute?
    /// 是否展示播放页
    @State private var showPlayerPage = false
    /// 要打开的歌手歌曲页（歌手作为 item 直接传入）
    @State private var authorRoute: MusicAuthor?
    @State private var showCreateDirectory = false
    @State private var newDirectoryName = ""
    @State private var deleteTarget: DeleteTarget?
    @State private var alertMessage: String?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Dimens.middleMargin) {
                userInfoCard
                directorySection
                likedMusicSection
                authorSection
                recordSection
            }
            .padding(.horizontal, Dimens.middleMargin)
            .padding(.vertical, Dimens.middleMargin)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.pageBackgroundColor)
        .refreshable { await loadAll() }
        .onAppear {
            if likedTotal == 0 && records.isEmpty && favoriteAuthors.isEmpty {
                loadAllInBackground()
            }
        }
        .fullScreenCover(item: $route) { route in
            switch route {
            case .profile:
                // 用户信息编辑
                EditUserInfoPage()
            case .favoriteDirectory(let directory):
                // 收藏夹详情
                FavoriteMusicPage(directory: directory)
            case .likedMusic:
                // 我喜欢的歌曲（全部）
                MusicFavoriteListPage()
            case .favoriteAuthor:
                // 我关注的歌手（全部）
                FavoriteAuthorListPage()
            case .record:
                // 播放记录（全部）
                RecordMusicPage()
            }
        }
        .fullScreenCover(isPresented: $showPlayerPage) {
            MusicPlayerPage()
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
        .alert("新建收藏夹", isPresented: $showCreateDirectory) {
            TextField("收藏夹名称", text: $newDirectoryName)
            Button("取消", role: .cancel) { newDirectoryName = "" }
            Button("确定") { createDirectory() }
        } message: {
            Text("给收藏夹起个名字")
        }
        .confirmationDialog(
            "确定删除？",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible,
            presenting: deleteTarget
        ) { target in
            Button("删除", role: .destructive) { performDelete(target) }
            Button("取消", role: .cancel) { deleteTarget = nil }
        } message: { target in
            Text(target.name)
        }
    }

    // MARK: - 用户信息

    /// 用户信息卡
    private var userInfoCard: some View {
        HStack(spacing: Dimens.middleMargin) {
            UserAvatar(avatar: appState.userData?.avater, size: Dimens.bigAvater)

            VStack(alignment: .leading, spacing: Dimens.smallMargin) {
                Text(appState.userData?.username ?? "未登录")
                    .font(.system(size: Dimens.middleFont))
                    .foregroundColor(Colors.blackColor)
                    .lineLimit(1)

                Text(appState.userData?.sign ?? "")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.subColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { route = .profile }) {
                Image("icon_edit")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
            }
            .buttonStyle(.plain)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    // MARK: - 我的收藏夹

    private var directorySection: some View {
        sectionCard {
            MusicSectionHeader(title: "我的收藏夹", isFold: isDirectoryFolded, onFold: {
                isDirectoryFolded.toggle()
            }) {
                HStack(spacing: Dimens.middleMargin) {
                    // 新建
                    Button(action: {
                        newDirectoryName = ""
                        showCreateDirectory = true
                    }) {
                        Image("icon_add")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
                    }
                    .buttonStyle(.plain)

                    // 刷新
                    refreshButton { loadDirectories() }
                }
            }
        } content: {
            if !isDirectoryFolded {
                if directories.isEmpty {
                    emptyRow("还没有收藏夹")
                } else {
                    ForEach(Array(directories.enumerated()), id: \.element.id) { index, directory in
                        rowDivider(show: index < directories.count - 1)
                        MusicUserListRow(
                            cover: directory.cover,
                            fallbackText: directory.placeholderText,
                            title: directory.name,
                            subtitle: "\(directory.total ?? 0)首",
                            onPlay: { route = .favoriteDirectory(directory) },
                            onMenu: {},
                            onLongPress: {
                                deleteTarget = DeleteTarget(
                                    kind: .directory,
                                    index: index,
                                    businessId: directory.id,
                                    name: directory.name
                                )
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - 我喜欢的歌曲

    private var likedMusicSection: some View {
        sectionCard {
            MusicSectionHeader(title: "我喜欢的歌曲", isFold: isLikedFolded, onFold: {
                isLikedFolded.toggle()
            }) {
                HStack(spacing: Dimens.middleMargin) {
                    refreshButton { loadLikedMusics() }
                    if likedTotal > Constants.MusicConfig.userLikedCount {
                        moreButton { route = .likedMusic }
                    }
                }
            }
        } content: {
            if !isLikedFolded {
                if likedMusics.isEmpty {
                    emptyRow("还没有喜欢的歌曲")
                } else {
                    ForEach(Array(likedMusics.enumerated()), id: \.element.id) { index, music in
                        rowDivider(show: index < likedMusics.count - 1)
                        MusicUserListRow(
                            cover: music.cover,
                            fallbackText: String(music.songName.prefix(1)),
                            title: music.songName,
                            subtitle: nil,
                            onPlay: { play(music) },
                            onMenu: {},
                            onLongPress: {
                                deleteTarget = DeleteTarget(
                                    kind: .likedMusic,
                                    index: index,
                                    businessId: music.id,
                                    name: music.songName
                                )
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - 我关注的歌手

    private var authorSection: some View {
        sectionCard {
            MusicSectionHeader(title: "我关注的歌手", isFold: isAuthorFolded, onFold: {
                isAuthorFolded.toggle()
            }) {
                HStack(spacing: Dimens.middleMargin) {
                    refreshButton { loadFavoriteAuthors() }
                    if authorTotal > Constants.MusicConfig.userAuthorCount {
                        moreButton { route = .favoriteAuthor }
                    }
                }
            }
        } content: {
            if !isAuthorFolded {
                if favoriteAuthors.isEmpty {
                    emptyRow("还没有关注的歌手")
                } else {
                    ForEach(Array(favoriteAuthors.enumerated()), id: \.element.id) { index, author in
                        rowDivider(show: index < favoriteAuthors.count - 1)
                        MusicUserListRow(
                            cover: author.avatar,
                            fallbackText: author.avatarPlaceholderText,
                            title: author.authorName,
                            subtitle: author.total.map { "\($0)首" },
                            onPlay: { authorRoute = author },
                            onMenu: {},
                            onLongPress: {
                                deleteTarget = DeleteTarget(
                                    kind: .author,
                                    index: index,
                                    businessId: author.authorId ?? author.id,
                                    name: author.authorName
                                )
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - 我最近播放的歌曲

    private var recordSection: some View {
        sectionCard {
            MusicSectionHeader(title: "我最近播放的歌曲", isFold: isRecordFolded, onFold: {
                isRecordFolded.toggle()
            }) {
                HStack(spacing: Dimens.middleMargin) {
                    refreshButton { loadRecords() }
                    if recordTotal > Constants.MusicConfig.userRecordCount {
                        moreButton { route = .record }
                    }
                }
            }
        } content: {
            if !isRecordFolded {
                if records.isEmpty {
                    emptyRow("还没有播放记录")
                } else {
                    ForEach(Array(records.enumerated()), id: \.element.id) { index, music in
                        rowDivider(show: index < records.count - 1)
                        MusicUserListRow(
                            cover: music.cover,
                            fallbackText: String(music.songName.prefix(1)),
                            title: music.songName,
                            subtitle: (music.times ?? 0) > 0 ? "听过\(music.times ?? 0)次" : nil,
                            showsDelete: true,
                            onPlay: { play(music) },
                            onDelete: {
                                deleteTarget = DeleteTarget(
                                    kind: .record,
                                    index: index,
                                    businessId: music.id,
                                    name: music.songName
                                )
                            },
                            onMenu: {}
                        )
                    }
                }
            }
        }
    }

    // MARK: - 通用子视图

    /// 模块卡片（标题栏 + 内容）
    private func sectionCard<Header: View, Content: View>(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Dimens.middleMargin) {
            header()
            content()
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    /// 行间分割线
    private func rowDivider(show: Bool) -> some View {
        Rectangle()
            .fill(show ? Colors.grayColor : Color.clear)
            .frame(height: 1)
    }

    /// 空态行
    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.grayColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Dimens.middleMargin)
    }

    /// 刷新图标按钮
    private func refreshButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image("icon_refresh")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
        }
        .buttonStyle(.plain)
    }

    /// 更多按钮
    private func moreButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("更多")
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.grayColor)
                .underline()
        }
        .buttonStyle(.plain)
    }

    // MARK: - 数据

    /// 首次进入并行加载四个模块
    private func loadAllInBackground() {
        loadLikedMusics()
        loadFavoriteAuthors()
        loadRecords()
        loadDirectories()
    }

    /// 下拉刷新
    @MainActor
    private func loadAll() async {
        await withCheckedContinuation { continuation in
            let group = DispatchGroup()
            group.enter()
            HTTPClient.shared.getMusicLike(pageNum: 1, pageSize: Constants.MusicConfig.userLikedCount) { result in
                DispatchQueue.main.async {
                    if case .success(let (list, total)) = result {
                        likedMusics = list
                        likedTotal = total
                    }
                    group.leave()
                }
            }
            group.enter()
            HTTPClient.shared.getFavoriteAuthor(pageNum: 1, pageSize: Constants.MusicConfig.userAuthorCount) { result in
                DispatchQueue.main.async {
                    if case .success(let (list, total)) = result {
                        favoriteAuthors = list
                        authorTotal = total
                    }
                    group.leave()
                }
            }
            group.enter()
            HTTPClient.shared.getMusicRecord(pageNum: 1, pageSize: Constants.MusicConfig.userRecordCount) { result in
                DispatchQueue.main.async {
                    if case .success(let (list, total)) = result {
                        records = list
                        recordTotal = total
                    }
                    group.leave()
                }
            }
            group.enter()
            loadDirectories { group.leave() }
            group.notify(queue: .main) { continuation.resume() }
        }
    }

    /// 我喜欢的歌曲（首页展示 5 条）
    private func loadLikedMusics() {
        HTTPClient.shared.getMusicLike(pageNum: 1, pageSize: Constants.MusicConfig.userLikedCount) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (list, total)):
                    likedMusics = list
                    likedTotal = total
                case .failure(let error):
                    print("❌ 获取喜欢的歌曲失败: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 我关注的歌手
    private func loadFavoriteAuthors() {
        HTTPClient.shared.getFavoriteAuthor(pageNum: 1, pageSize: Constants.MusicConfig.userAuthorCount) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (list, total)):
                    favoriteAuthors = list
                    authorTotal = total
                case .failure(let error):
                    print("❌ 获取关注的歌手失败: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 播放记录
    private func loadRecords() {
        HTTPClient.shared.getMusicRecord(pageNum: 1, pageSize: Constants.MusicConfig.userRecordCount) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (list, total)):
                    records = list
                    recordTotal = total
                case .failure(let error):
                    print("❌ 获取播放记录失败: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 收藏夹列表
    /// 后端该接口必须传 musicId（用于标记当前歌曲是否已收藏），这里优先用当前播放歌曲，
    /// 其次用第一首喜欢的歌曲；都没有（musicId = 0）时后端会报错，直接视为空列表。
    private func loadDirectories(completion: (() -> Void)? = nil) {
        let musicId = playerState.currentMusic?.id ?? likedMusics.first?.id ?? 0
        guard musicId > 0 else {
            directories = []
            completion?()
            return
        }
        HTTPClient.shared.getFavoriteDirectory(musicId: musicId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let list):
                    directories = list
                case .failure(let error):
                    print("❌ 获取收藏夹失败: \(error.localizedDescription)")
                }
                completion?()
            }
        }
    }

    // MARK: - 交互

    /// 新建收藏夹
    private func createDirectory() {
        let name = newDirectoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        newDirectoryName = ""
        guard !name.isEmpty else { return }

        HTTPClient.shared.insertFavoriteDirectory(name: name) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadDirectories()
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }
    }

    /// 执行删除
    private func performDelete(_ target: DeleteTarget) {
        deleteTarget = nil

        switch target.kind {
        case .directory:
            HTTPClient.shared.deleteFavoriteDirectory(favoriteId: target.businessId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        if directories.indices.contains(target.index) {
                            directories.remove(at: target.index)
                        }
                    case .failure(let error):
                        alertMessage = error.localizedDescription
                    }
                }
            }
        case .likedMusic:
            HTTPClient.shared.deleteMusicLike(musicId: target.businessId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        if likedMusics.indices.contains(target.index) {
                            likedMusics.remove(at: target.index)
                            likedTotal = max(0, likedTotal - 1)
                        }
                    case .failure(let error):
                        alertMessage = error.localizedDescription
                    }
                }
            }
        case .author:
            HTTPClient.shared.deleteFavoriteAuthor(authorId: target.businessId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        if favoriteAuthors.indices.contains(target.index) {
                            favoriteAuthors.remove(at: target.index)
                            authorTotal = max(0, authorTotal - 1)
                        }
                    case .failure(let error):
                        alertMessage = error.localizedDescription
                    }
                }
            }
        case .record:
            // 后端没有删除播放记录的接口，先只做本地移除提示
            if records.indices.contains(target.index) {
                records.remove(at: target.index)
            }
            alertMessage = "播放记录暂不支持删除（后端暂无接口）"
        }
    }

    /// 播放某首歌：同一首歌就继续播，否则切歌并把当前列表作为播放列表
    private func play(_ music: Music) {
        if playerState.currentMusic?.id != music.id {
            playerState.setMusic(music, autoPlay: true)
        } else if !playerState.isPlaying {
            playerState.play()
        }
        showPlayerPage = true
    }
}

#Preview {
    MusicUserPage()
}
