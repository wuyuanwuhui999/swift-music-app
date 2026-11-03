//
//  FavoriteDirectoryDialogView.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 收藏夹弹窗（播放页「收藏夹」按钮打开）
///
/// 对齐 uniapp `FavoriteDirectoryComponent.vue`：
/// 顶部「新建收藏夹」+ 收藏夹列表（勾选框，勾选状态由后端 `checked` 给出）+ 底部提交按钮
/// （没有勾选且已收藏时为「取消收藏」，否则为「添加（已选N个）」）。
///
/// 接口：
/// - `GET /service/music/getFavoriteDirectory?musicId=` 收藏夹列表（带 checked）
/// - `GET /service/music/isMusicFavorite/{musicId}` 是否已收藏
/// - `POST /service/music/insertFavoriteDirectory` 新建收藏夹
/// - `POST /service/music/insertMusicFavorite/{musicId}` 提交勾选（空数组 = 取消收藏）
struct FavoriteDirectoryDialogView: View {
    /// 歌曲 id
    let musicId: Int
    /// 收藏状态变化回调（外部据此更新星标）
    var onFavoriteChanged: ((Bool) -> Void)?

    @Environment(\.dismiss) private var dismiss

    /// 收藏夹列表
    @State private var directories: [FavoriteDirectory] = []
    /// 勾选的收藏夹 id
    @State private var selectedIds: Set<Int> = []
    /// 当前歌曲是否已收藏
    @State private var isFavorite = false
    /// 是否正在加载
    @State private var isLoading = false
    /// 是否正在提交
    @State private var isSubmitting = false
    /// 是否展示新建输入框
    @State private var isCreating = false
    /// 新建收藏夹名称
    @State private var newDirectoryName = ""
    /// 轻提示
    @State private var alertMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if isCreating {
                createRow
            } else {
                createEntry
            }

            ScrollView(.vertical, showsIndicators: false) {
                if directories.isEmpty {
                    Text(isLoading ? "加载中..." : "还没有收藏夹，先新建一个吧")
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.subColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Dimens.bigIcon)
                } else {
                    VStack(spacing: Dimens.middleMargin) {
                        ForEach(Array(directories.enumerated()), id: \.element.id) { index, directory in
                            VStack(spacing: Dimens.middleMargin) {
                                directoryRow(directory)

                                if index < directories.count - 1 {
                                    Rectangle()
                                        .fill(Colors.grayColor)
                                        .frame(height: 1)
                                }
                            }
                        }
                    }
                    .padding(Dimens.middleMargin)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            submitButton
        }
        .background(Colors.pageBackgroundColor)
        .onAppear(perform: load)
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

    /// 标题栏
    private var header: some View {
        ZStack {
            Text("收藏夹")
                .font(.system(size: Dimens.middleFont))
                .foregroundColor(Colors.blackColor)

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

    /// 「新建收藏夹」入口
    private var createEntry: some View {
        Button(action: {
            newDirectoryName = ""
            isCreating = true
        }) {
            HStack(spacing: Dimens.middleMargin) {
                Image("icon_add")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)

                Text("新建收藏夹")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.blackColor)

                Spacer()
            }
            .padding(Dimens.middleMargin)
            .background(Colors.whiteColor)
        }
        .buttonStyle(.plain)
    }

    /// 新建收藏夹输入行
    private var createRow: some View {
        HStack(spacing: Dimens.middleMargin) {
            TextField("收藏夹名称", text: $newDirectoryName)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .padding(.horizontal, Dimens.middleMargin)
                .frame(height: Dimens.smallBtnHeight)
                .background(Colors.pageBackgroundColor)
                .cornerRadius(Dimens.smallBtnHeight / 2)

            Button(action: createDirectory) {
                Text("确定")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.whiteColor)
                    .padding(.horizontal, Dimens.middleMargin)
                    .frame(height: Dimens.smallBtnHeight)
                    .background(newDirectoryName.isEmpty ? Colors.grayColor : Colors.primaryColor)
                    .cornerRadius(Dimens.smallBtnHeight / 2)
            }
            .buttonStyle(.plain)
            .disabled(newDirectoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button(action: { isCreating = false }) {
                Text("取消")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.subColor)
            }
            .buttonStyle(.plain)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
    }

    /// 单个收藏夹行（勾选框 + 封面/首字 + 名称 + N首）
    private func directoryRow(_ directory: FavoriteDirectory) -> some View {
        Button(action: { toggle(directory.id) }) {
            HStack(spacing: Dimens.middleMargin) {
                coverView(directory)

                VStack(alignment: .leading, spacing: Dimens.smallMargin) {
                    Text(directory.name)
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.blackColor)
                        .lineLimit(1)

                    Text("\(directory.total ?? 0)首")
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.subColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 勾选框
                Image(systemName: selectedIds.contains(directory.id)
                      ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: Dimens.middleIcon))
                    .foregroundColor(selectedIds.contains(directory.id)
                                     ? Colors.primaryColor : Colors.grayColor)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 收藏夹封面（无封面用首字兜底）
    private func coverView(_ directory: FavoriteDirectory) -> some View {
        ZStack {
            Colors.pageBackgroundColor

            if let urlString = MusicUtils.coverURL(directory.cover), let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        placeholderText(directory)
                    }
                }
            } else {
                placeholderText(directory)
            }
        }
        .frame(width: Dimens.middleIcon * 2, height: Dimens.middleIcon * 2)
        .clipShape(RoundedRectangle(cornerRadius: Dimens.borderRadius))
    }

    private func placeholderText(_ directory: FavoriteDirectory) -> some View {
        Text(directory.placeholderText)
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.subColor)
    }

    /// 底部提交按钮
    private var submitButton: some View {
        Button(action: submit) {
            Text(submitTitle)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.whiteColor)
                .frame(maxWidth: .infinity)
                .frame(height: Dimens.btnHeight)
                .background(isSubmitting ? Colors.grayColor : Colors.primaryColor)
                .cornerRadius(Dimens.btnHeight / 2)
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
    }

    // MARK: - 计算属性

    /// 按钮文案（对齐 uniapp：没有勾选且已收藏时为「取消收藏」）
    private var submitTitle: String {
        if isSubmitting {
            return "提交中..."
        }
        if selectedIds.isEmpty && isFavorite {
            return "取消收藏"
        }
        if selectedIds.isEmpty {
            return "添加"
        }
        return "添加（已选\(selectedIds.count)个）"
    }

    // MARK: - 数据

    /// 拉取收藏夹 + 收藏状态
    private func load() {
        isLoading = true
        HTTPClient.shared.getFavoriteDirectory(musicId: musicId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let list):
                    directories = list
                    selectedIds = Set(list.filter { ($0.checked ?? 0) == 1 }.map { $0.id })
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }

        HTTPClient.shared.isMusicFavorite(musicId: musicId) { result in
            DispatchQueue.main.async {
                if case .success(let value) = result {
                    isFavorite = value == 1
                }
            }
        }
    }

    // MARK: - 交互

    /// 勾选 / 取消勾选
    private func toggle(_ id: Int) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    /// 新建收藏夹
    private func createDirectory() {
        let name = newDirectoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        HTTPClient.shared.insertFavoriteDirectory(name: name) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    isCreating = false
                    newDirectoryName = ""
                    load()
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }
    }

    /// 提交勾选结果
    private func submit() {
        guard !isSubmitting else { return }
        isSubmitting = true

        let ids = Array(selectedIds)
        HTTPClient.shared.insertMusicFavorite(musicId: musicId, favoriteIds: ids) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    let favorite = !ids.isEmpty
                    isFavorite = favorite
                    onFavoriteChanged?(favorite)
                    dismiss()
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    FavoriteDirectoryDialogView(musicId: 64346)
}
