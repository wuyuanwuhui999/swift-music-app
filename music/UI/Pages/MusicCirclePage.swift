//
//  MusicCirclePage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 评论输入目标
struct CircleCommentTarget: Identifiable {
    /// 动态 id
    let circleId: Int
    /// 一级评论 id（回复一级评论时传它的 id）
    let topId: Int?
    /// 被回复的评论 id（回复二级评论时传它）
    let parentId: Int?
    /// 输入框提示语
    let placeholder: String

    var id: String { "\(circleId)-\(topId ?? 0)-\(parentId ?? 0)" }
}

/// 音乐圈 Tab
///
/// 对齐 flutter `MusicCirclePage.dart` 与 uniapp `MusicCircleComponent.vue`：
/// 动态流（头像 / 昵称 / 内容 / 分享的歌曲 / 时间 / 点赞与评论）+ 点赞、评论、二级回复、
/// 分页加载、下拉刷新、右下角发布按钮（发布页当前是占位页）。
///
/// 接口：
/// - `GET /service/circle/getCircleListByType` 动态列表
/// - `POST /service/social/saveLike` / `DELETE /service/social/deleteLike` 点赞
/// - `POST /service/social/insertComment` 评论 / 回复
struct MusicCirclePage: View {
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var playerState = PlayerState.shared

    /// 动态列表
    @State private var circles: [MusicCircle] = []
    /// 当前页码（从 1 开始）
    @State private var pageNum = 1
    /// 接口返回的总条数
    @State private var total = 0
    /// 是否正在请求列表
    @State private var isLoading = false
    /// 展开操作菜单的动态 id
    @State private var menuCircleId: Int?
    /// 评论输入目标（nil 表示输入框收起）
    @State private var commentTarget: CircleCommentTarget?
    /// 评论输入内容
    @State private var inputText = ""
    /// 是否正在提交评论
    @State private var isSending = false
    /// 是否展示发布页
    @State private var showPublishPage = false
    /// 轻提示
    @State private var alertMessage: String?

    private let pageSize = Constants.CircleConfig.pageSize

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: Dimens.middleMargin) {
                    if circles.isEmpty {
                        emptyView
                    } else {
                        ForEach(Array(circles.enumerated()), id: \.element.id) { index, circle in
                            MusicCircleCard(
                                circle: circle,
                                currentUserId: appState.userData?.id,
                                isMenuOpen: menuCircleId == circle.id,
                                onMenuTap: { toggleMenu(circleId: circle.id) },
                                onLike: { toggleLike(at: index) },
                                onComment: { openCommentInput(circleId: circle.id, target: nil) },
                                onReply: { comment in
                                    openCommentInput(circleId: circle.id, target: comment)
                                }
                            )
                            // 打开菜单的卡片抬高层级，避免气泡被下一张卡片盖住
                            .zIndex(menuCircleId == circle.id ? 10 : 0)
                        }

                        footer
                    }
                }
                .padding(.horizontal, Dimens.middleMargin)
                .padding(.vertical, Dimens.middleMargin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Colors.pageBackgroundColor)
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await reload() }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.containerSize.height
                    >= geometry.contentSize.height - 200
            } action: { _, isNearBottom in
                guard isNearBottom else { return }
                loadMoreIfNeeded()
            }
            .onTapGesture {
                // 点空白处收起操作菜单（对齐 uniapp useHideMenu）
                menuCircleId = nil
            }

            // 发布按钮（右下角）
            publishButton

            // 评论输入框
            if commentTarget != nil {
                commentInputBar
            }
        }
        .onAppear {
            if circles.isEmpty {
                loadFirstPage()
            }
        }
        .fullScreenCover(isPresented: $showPublishPage) {
            // 发布页：有正在播放的歌就预填，没有则提示选歌
            MusicSharePage(music: playerState.currentMusic)
        }
        .onReceive(NotificationCenter.default.publisher(for: .musicCircleDidUpdate)) { note in
            // 发布成功后把新动态插到最前面（后端没写 create_time，拉列表会排到最后）
            if let post = note.object as? MusicCircle, !circles.contains(where: { $0.id == post.id }) {
                circles.insert(post, at: 0)
                total += 1
            }
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

    /// 空态 / 加载态
    private var emptyView: some View {
        Text(isLoading ? "加载中..." : "还没有动态，快来发布第一条吧")
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

    /// 右下角发布按钮（对齐 uniapp `.icon-add-circle`）
    private var publishButton: some View {
        HStack {
            Spacer()
            Button(action: { showPublishPage = true }) {
                Image("icon_music_add")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.circlePublishButton, height: Dimens.circlePublishButton)
                    .opacity(0.5)
            }
            .buttonStyle(.plain)
            .padding(.trailing, Dimens.middleMargin)
            .padding(.bottom, Dimens.middleMargin * 3)
        }
    }

    /// 底部评论输入条
    private var commentInputBar: some View {
        HStack(spacing: Dimens.middleMargin) {
            TextField("", text: $inputText, prompt: Text(commentTarget?.placeholder ?? "评论")
                .foregroundColor(Colors.grayColor))
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .padding(.horizontal, Dimens.middleMargin)
                .frame(height: Dimens.inputHeight)
                .background(Colors.pageBackgroundColor)
                .cornerRadius(Dimens.inputHeight / 2)

            Button(action: sendComment) {
                Text("发送")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.whiteColor)
                    .frame(width: Dimens.btnHeight * 1.4, height: Dimens.btnHeight * 0.8)
                    .background(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Colors.grayColor : Colors.primaryColor)
                    .cornerRadius(Dimens.btnHeight * 0.4)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
        .padding(.horizontal, Dimens.middleMargin)
        .padding(.bottom, Dimens.middleMargin)
    }

    // MARK: - 计算属性

    /// 是否还有下一页
    private var hasMore: Bool {
        circles.count < total
    }

    // MARK: - 数据

    /// 首次加载
    private func loadFirstPage() {
        guard !isLoading else { return }
        isLoading = true
        fetch(page: 1, replace: true)
    }

    /// 下拉刷新
    @MainActor
    private func reload() async {
        await withCheckedContinuation { continuation in
            HTTPClient.shared.getCircleListByType(pageNum: 1, pageSize: pageSize) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let (list, totalCount)):
                        total = totalCount
                        circles = list
                        pageNum = 1
                    case .failure(let error):
                        alertMessage = error.localizedDescription
                    }
                    continuation.resume()
                }
            }
        }
    }

    /// 拉取指定页
    private func fetch(page: Int, replace: Bool) {
        HTTPClient.shared.getCircleListByType(pageNum: page, pageSize: pageSize) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let (list, totalCount)):
                    total = totalCount
                    if replace {
                        circles = list
                    } else {
                        circles.append(contentsOf: list)
                    }
                    pageNum = page
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
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

    /// 展开 / 收起操作菜单
    private func toggleMenu(circleId: Int) {
        menuCircleId = (menuCircleId == circleId) ? nil : circleId
    }

    /// 打开评论输入框
    /// - Parameters:
    ///   - circleId: 动态 id
    ///   - target: 被回复的评论（nil 表示评论这条动态本身）
    private func openCommentInput(circleId: Int, target: CircleComment?) {
        menuCircleId = nil
        if let target = target {
            // 回复一级评论时 topId 就是它自己；回复二级评论时 topId 取它的 topId
            let topId = target.topId ?? target.id
            commentTarget = CircleCommentTarget(
                circleId: circleId,
                topId: topId,
                parentId: target.id,
                placeholder: "回复 \(target.username ?? "")"
            )
        } else {
            commentTarget = CircleCommentTarget(
                circleId: circleId,
                topId: nil,
                parentId: nil,
                placeholder: "评论"
            )
        }
    }

    /// 点赞 / 取消点赞
    ///
    /// 注意：后端 `saveLike` 目前会返回 FAIL（`LikeSchema` 未定义），但点赞记录其实已经写库，
    /// 所以这里做「乐观更新」——先本地插入/移除，再按接口结果校正：
    /// 取消赞失败才回滚并提示；点赞失败保留本地状态（服务端已写入），只在控制台打印服务端消息。
    private func toggleLike(at index: Int) {
        guard circles.indices.contains(index) else { return }
        let circle = circles[index]
        let uid = appState.userData?.id
        var likes = circle.circleLikes ?? []

        if let likeIndex = likes.firstIndex(where: { $0.userId == uid }) {
            // 已赞 → 取消赞
            let removed = likes.remove(at: likeIndex)
            circles[index].circleLikes = likes

            HTTPClient.shared.deleteLike(relationId: circle.id) { result in
                DispatchQueue.main.async {
                    if case .failure(let error) = result {
                        // 取消失败：把点赞加回去
                        circles[index].circleLikes?.append(removed)
                        alertMessage = error.localizedDescription
                    }
                }
            }
        } else {
            // 未赞 → 点赞（乐观更新）
            let optimistic = CircleLike(
                type: Constants.CircleConfig.musicCircleRelation,
                relationId: circle.id,
                userId: uid,
                username: appState.userData?.username
            )
            likes.append(optimistic)
            circles[index].circleLikes = likes

            HTTPClient.shared.saveLike(relationId: circle.id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let like):
                        // 服务端返回真实记录时替换掉临时记录
                        if let like = like,
                           let i = circles[index].circleLikes?.firstIndex(where: { $0.userId == uid }) {
                            circles[index].circleLikes?[i] = like
                        }
                    case .failure(let error):
                        if isServerRejection(error) {
                            // 后端已知问题：返回 FAIL 但记录已写库，保留乐观状态即可
                            print("⚠️ saveLike 返回失败但数据已写库（后端 LikeSchema 问题）: \(error.localizedDescription)")
                        } else {
                            // 真正的网络问题：回滚
                            removeLike(at: index, userId: uid)
                            alertMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    /// 发送评论 / 回复
    ///
    /// 同样存在「后端返回失败但数据已写库」的问题（`发表评论失败`），
    /// 所以先把评论插到本地列表，接口返回服务端拒绝时保留（可在下一次刷新时以服务端为准），
    /// 只有网络错误才提示。
    private func sendComment() {
        guard let target = commentTarget, !isSending else { return }
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isSending = true
        HTTPClient.shared.insertComment(
            relationId: target.circleId,
            content: content,
            topId: target.topId,
            parentId: target.parentId
        ) { result in
            DispatchQueue.main.async {
                isSending = false
                switch result {
                case .success:
                    appendLocalComment(target: target, content: content)
                    inputText = ""
                    commentTarget = nil
                case .failure(let error):
                    if isServerRejection(error) {
                        print("⚠️ insertComment 返回失败但数据已写库: \(error.localizedDescription)")
                        appendLocalComment(target: target, content: content)
                        inputText = ""
                        commentTarget = nil
                    } else {
                        alertMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    /// 是否是「服务端明确返回失败」（非网络层错误）
    /// 用于区分后端业务报错与真正的网络异常
    private func isServerRejection(_ error: NetworkError) -> Bool {
        if case .custom = error { return true }
        return false
    }

    /// 移除指定用户的点赞（回滚用）
    private func removeLike(at index: Int, userId: String?) {
        guard circles.indices.contains(index),
              let likeIndex = circles[index].circleLikes?.firstIndex(where: { $0.userId == userId }) else { return }
        circles[index].circleLikes?.remove(at: likeIndex)
    }

    /// 评论成功后本地构造一条评论插入列表
    /// 后端 `insertComment` 的 data 返回 null，拿不到服务端记录，只能按当前用户信息本地拼装
    private func appendLocalComment(target: CircleCommentTarget, content: String) {
        guard let index = circles.firstIndex(where: { $0.id == target.circleId }) else { return }

        let comment = CircleComment(
            id: Int(Date().timeIntervalSince1970 * 1000),
            content: content,
            username: appState.userData?.username,
            avater: appState.userData?.avater,
            topId: target.topId,
            parentId: target.parentId,
            replyUserName: nil,
            createTime: nil,
            replyList: []
        )

        var comments = circles[index].circleComments ?? []

        if let topId = target.topId {
            // 回复：挂到对应一级评论的 replyList 下
            if let topIndex = comments.firstIndex(where: { $0.id == topId }) {
                var replyList = comments[topIndex].replyList ?? []
                replyList.append(comment)
                comments[topIndex].replyList = replyList
            }
        } else {
            // 评论动态本身
            comments.append(comment)
        }

        circles[index].circleComments = comments
    }
}

#Preview {
    MusicCirclePage()
}
