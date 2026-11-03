//
//  ChatPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// AI 聊天页
///
/// 入口：首页搜索栏右侧的 AI 图标。
///
/// 对齐 uniapp `ChatPage.vue` / flutter `ChatPage.dart` 的简化版：
/// - 顶部：标题「AI 助手」+ 当前模型（点击可切换）
/// - 消息列表：用户消息靠右（主题色气泡），AI 回复靠左（白色气泡，流式追加）
/// - 底部输入框 + 发送；发送中禁用，收到 [completed] 结束
///
/// 接口：
/// - `GET /service/chat/getModelList?companyId=` 模型列表
/// - `WS /service/chat/ws/chat?token=` 流式对话（`WebSocketManager`）
struct ChatPage: View {
    @Environment(\.dismiss) private var dismiss

    /// 聊天气泡
    struct ChatItem: Identifiable {
        let id = UUID()
        let isUser: Bool
        var text: String
        var isStreaming: Bool = false
    }

    /// 模型列表
    @State private var models: [ChatModel] = []
    /// 当前模型下标
    @State private var activeModelIndex = 0
    /// 是否展示模型选择
    @State private var showModelPicker = false
    /// 消息列表
    @State private var messages: [ChatItem] = []
    /// 输入内容
    @State private var inputText = ""
    /// 本次会话 id
    @State private var chatId = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    /// 是否正在等待 AI 回复
    @State private var isReceiving = false
    /// 轻提示
    @State private var alertMessage: String?

    @ObservedObject private var socket = WebSocketManager.shared

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Dimens.middleMargin) {
                        if messages.isEmpty {
                            welcomeView
                        } else {
                            ForEach(messages) { item in
                                bubble(for: item)
                                    .id(item.id)
                            }
                        }
                    }
                    .padding(Dimens.middleMargin)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: messages.last?.text) { _, _ in
                    // 流式输出时跟随滚动到底部
                    if let last = messages.last {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            inputBar
        }
        .background(Colors.pageBackgroundColor)
        .onAppear(perform: loadModels)
        .confirmationDialog("选择模型", isPresented: $showModelPicker, titleVisibility: .visible) {
            ForEach(Array(models.enumerated()), id: \.element.id) { index, model in
                Button(model.modelName) { activeModelIndex = index }
            }
            Button("取消", role: .cancel) {}
        }
        .alert("提示", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .onDisappear {
            socket.disconnect()
        }
    }

    // MARK: - 子视图

    /// 顶部标题栏（标题 + 模型切换）
    private var header: some View {
        HStack(spacing: Dimens.middleMargin) {
            Button(action: { dismiss() }) {
                Image("icon_back")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
            }
            .buttonStyle(.plain)

            Text("AI 助手")
                .font(.system(size: Dimens.middleFont))
                .foregroundColor(Colors.blackColor)

            Spacer(minLength: Dimens.middleMargin)

            // 模型切换
            Button(action: { showModelPicker = true }) {
                HStack(spacing: Dimens.smallMargin) {
                    Text(activeModelName)
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.subColor)
                        .lineLimit(1)

                    Image("icon_arrow")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
    }

    /// 空态欢迎语
    private var welcomeView: some View {
        VStack(spacing: Dimens.middleMargin) {
            Image("icon_ai")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.bigIcon, height: Dimens.bigIcon)

            Text("我是你的音乐小助手，想聊点什么？")
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.subColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Dimens.bigIcon)
    }

    /// 消息气泡
    private func bubble(for item: ChatItem) -> some View {
        HStack(alignment: .top, spacing: 0) {
            if item.isUser { Spacer(minLength: Dimens.bigIcon) }

            Text(item.text.isEmpty ? (item.isStreaming ? "正在思考..." : "") : item.text)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(item.isUser ? Colors.whiteColor : Colors.blackColor)
                .padding(Dimens.middleMargin)
                .background(item.isUser ? Colors.primaryColor : Colors.whiteColor)
                .cornerRadius(Dimens.borderRadius)
                .textSelection(.enabled)

            if !item.isUser { Spacer(minLength: Dimens.bigIcon) }
        }
    }

    /// 底部输入条
    private var inputBar: some View {
        HStack(spacing: Dimens.middleMargin) {
            TextField("", text: $inputText, prompt: Text("输入你的问题")
                .foregroundColor(Colors.grayColor))
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .submitLabel(.send)
                .onSubmit(send)
                .padding(.horizontal, Dimens.middleMargin)
                .frame(height: Dimens.smallBtnHeight)
                .background(Colors.whiteColor)
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
            .disabled(!canSend || isReceiving)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.pageBackgroundColor)
    }

    // MARK: - 计算属性

    private var activeModelName: String {
        guard models.indices.contains(activeModelIndex) else { return "默认模型" }
        return models[activeModelIndex].modelName
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - 数据

    /// 拉取模型列表
    private func loadModels() {
        guard models.isEmpty else { return }
        HTTPClient.shared.getModelList(companyId: Constants.ChatConfig.companyId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (list, _)):
                    // 后端 chat 服务只支持 ollama 类型模型（online 会返回「不支持的模型类型」），
                    // 因此把 ollama 排前面，online 作为兜底
                    let usable = list.filter { ($0.disabled ?? 0) == 0 }
                    let local = usable.filter { $0.type != "online" }
                    let online = usable.filter { $0.type == "online" }
                    models = local + online
                    activeModelIndex = 0
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - 交互

    /// 发送消息
    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isReceiving else { return }
        guard models.indices.contains(activeModelIndex) else {
            alertMessage = "暂无可用模型，请稍后再试"
            return
        }

        inputText = ""
        isReceiving = true

        messages.append(ChatItem(isUser: true, text: text))
        messages.append(ChatItem(isUser: false, text: "", isStreaming: true))

        let aiIndex = messages.count - 1
        let model = models[activeModelIndex]

        socket.connect(
            modelId: model.id,
            chatId: chatId,
            tenantId: "",
            companyId: Constants.ChatConfig.companyId,
            prompt: text,
            showThink: Constants.ChatConfig.showThink,
            language: Constants.ChatConfig.language,
            onMessage: { chunk in
                guard messages.indices.contains(aiIndex) else { return }
                messages[aiIndex].text += chunk
            },
            onComplete: {
                if messages.indices.contains(aiIndex) {
                    messages[aiIndex].isStreaming = false
                }
                isReceiving = false
            }
        )
    }
}

#Preview {
    ChatPage()
}
