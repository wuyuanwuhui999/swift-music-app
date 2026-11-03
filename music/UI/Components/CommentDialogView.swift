//
//  CommentDialogView.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 评论弹窗（播放页「评论」按钮打开）
///
/// 对齐 flutter `FavoriteComponent` 同级的评论组件 / uniapp `CommentComponent`：
/// 一级评论 + 二级回复（`昵称▶被回复人`），点评论内容进入回复态，
/// 底部输入框 + 「发送」，发送成功后本地插入（后端同一套 insertComment 接口）。
///
/// 接口：
/// - `GET /service/social/getTopCommentList` 评论列表
/// - `POST /service/social/insertComment` 发评论 / 回复
struct CommentDialogView: View {
    /// 关联资源 id（歌曲 id）
    let relationId: Int
    /// 关联资源类型（音乐为 MUSIC）
    let type: String
    /// 评论总数变化回调（用于外部刷新红点 / 数量）
    var onCountChanged: ((Int) -> Void)?

    @ObservedObject private var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss

    /// 一级评论列表
    @State private var comments: [CircleComment] = []
    /// 总条数
    @State private var total = 0
    /// 当前页码
    @State private var pageNum = 1
    /// 是否正在加载
    @State private var isLoading = false
    /// 输入内容
    @State private var inputText = ""
    /// 是否正在发送
    @State private var isSending = false
    /// 回复目标（nil 表示评论歌曲本身）
    @State private var replyTarget: CircleComment?
    /// 轻提示
    @State private var alertMessage: String?

    private let pageSize = Constants.CircleConfig.pageSize

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                if comments.isEmpty {
                    emptyView
                } else {
                    VStack(spacing: Dimens.middleMargin) {
                        ForEach(Array(comments.enumerated()), id: \.element.id) { index, comment in
                            VStack(spacing: Dimens.middleMargin) {
                                CircleCommentRow(
                                    comment: comment,
                                    onReply: { target in replyTarget = target }
                                )

                                if index < comments.count - 1 {
                                    Rectangle()
                                        .fill(Colors.grayColor)
                                        .frame(height: 1)
                                }
                            }
                        }
                        footer
                    }
                    .padding(Dimens.middleMargin)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.containerSize.height
                    >= geometry.contentSize.height - 120
            } action: { _, isNearBottom in
                guard isNearBottom else { return }
                loadMoreIfNeeded()
            }

            inputBar
        }
        .background(Colors.pageBackgroundColor)
        .onAppear(perform: loadFirstPage)
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

    /// 标题栏：评论 + 数量 + 关闭
    private var header: some View {
        ZStack {
            HStack(spacing: Dimens.smallMargin) {
                Text("评论")
                    .font(.system(size: Dimens.middleFont))
                    .foregroundColor(Colors.blackColor)

                Text("\(total)")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.subColor)
            }

            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image("icon_close")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
    }

    /// 空态
    private var emptyView: some View {
        Text(isLoading ? "加载中..." : "暂无评论，快来抢沙发")
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

    /// 底部输入条
    private var inputBar: some View {
        HStack(spacing: Dimens.middleMargin) {
            TextField("", text: $inputText, prompt: Text(placeholder)
                .foregroundColor(Colors.grayColor))
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .padding(.horizontal, Dimens.middleMargin)
                .frame(height: Dimens.smallBtnHeight)
                .background(Colors.pageBackgroundColor)
                .cornerRadius(Dimens.smallBtnHeight / 2)

            Button(action: send) {
                Text("发送")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.whiteColor)
                    .padding(.horizontal, Dimens.middleMargin)
                    .frame(height: Dimens.smallBtnHeight)
                    .background(canSend ? Colors.primaryColor : Colors.grayColor)
                    .cornerRadius(Dimens.smallBtnHeight / 2)
            }
            .buttonStyle(.plain)
            .disabled(!canSend || isSending)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
    }

    // MARK: - 计算属性

    /// 输入框提示语
    private var placeholder: String {
        guard let target = replyTarget else { return "评论" }
        let name = target.username ?? ""
        return name.isEmpty ? "回复" : "回复 \(name)"
    }

    /// 是否可以发送
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 是否还有下一页
    private var hasMore: Bool {
        comments.count < total
    }

    // MARK: - 数据

    /// 加载第一页
    private func loadFirstPage() {
        guard !isLoading else { return }
        isLoading = true
        fetch(page: 1, replace: true)
    }

    /// 滚动到底加载更多
    private func loadMoreIfNeeded() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        fetch(page: pageNum + 1, replace: false)
    }

    /// 拉取评论
    private func fetch(page: Int, replace: Bool) {
        HTTPClient.shared.getTopCommentList(
            relationId: relationId,
            type: type,
            pageNum: page,
            pageSize: pageSize
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let (list, totalCount)):
                    total = totalCount
                    if replace {
                        comments = list
                    } else {
                        comments.append(contentsOf: list)
                    }
                    pageNum = page
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - 交互

    /// 发送评论 / 回复
    private func send() {
        guard !isSending else { return }
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        // 回复一级评论：topId = 该评论 id；回复二级评论：topId 取它的 topId，parentId = 该评论 id
        let topId = replyTarget.map { $0.topId ?? $0.id }
        let parentId = replyTarget?.id

        isSending = true
        HTTPClient.shared.insertComment(
            type: type,
            relationId: relationId,
            content: content,
            topId: topId,
            parentId: parentId
        ) { result in
            DispatchQueue.main.async {
                isSending = false
                switch result {
                case .success:
                    appendLocalComment(content: content, topId: topId, parentId: parentId)
                case .failure(let error):
                    if case .custom = error {
                        // 后端已知问题：返回 FAIL 但数据已入库，这里同样本地插入
                        print("⚠️ insertComment 返回失败但数据已写库: \(error.localizedDescription)")
                        appendLocalComment(content: content, topId: topId, parentId: parentId)
                    } else {
                        alertMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    /// 本地插入刚发的评论（后端 insertComment 的 data 恒为 null）
    private func appendLocalComment(content: String, topId: Int?, parentId: Int?) {
        let comment = CircleComment(
            id: Int(Date().timeIntervalSince1970 * 1000),
            content: content,
            username: appState.userData?.username,
            avater: appState.userData?.avater,
            topId: topId,
            parentId: parentId,
            createTime: DateUtils.nowString(),
            replyList: []
        )

        if let topId = topId, let index = comments.firstIndex(where: { $0.id == topId }) {
            // 回复：挂到对应一级评论的 replyList
            var replyList = comments[index].replyList ?? []
            replyList.append(comment)
            comments[index].replyList = replyList
        } else {
            // 评论歌曲本身
            comments.insert(comment, at: 0)
            total += 1
            onCountChanged?(total)
        }

        inputText = ""
        replyTarget = nil
    }
}

#Preview {
    CommentDialogView(relationId: 64346, type: Constants.CircleConfig.musicType)
}
