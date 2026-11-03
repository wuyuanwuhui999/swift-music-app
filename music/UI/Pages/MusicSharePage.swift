//
//  MusicSharePage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

extension Notification.Name {
    /// 音乐圈有一条新动态发布成功（用于通知列表刷新）
    static let musicCircleDidUpdate = Notification.Name("MUSIC_CIRCLE_DID_UPDATE")
}

/// 发布音乐圈动态页
///
/// 入口：播放页「分享」、音乐圈右下角「+」。
///
/// 对齐 flutter `MusicSharePage.dart` 与 uniapp `MusicSharePage.vue`：
/// - 顶部「取消 / 发布」两个按钮
/// - 文字输入区（占位「这一刻的想法」）
/// - 分享的歌曲卡片（封面 + 「歌手 - 歌名」）；没有歌曲时提示「请选择一首歌曲」
/// - 「谁可以看」：公开 / 私密，点开选择
///
/// 接口：`POST /service/circle/insertCircle`（content、imgs、relationId、type、permission）
struct MusicSharePage: View {
    /// 要分享的歌曲（nil 表示还没选歌，点歌曲行去选歌页挑）
    @State private var selectedMusic: Music?

    /// - Parameter music: 预填歌曲（播放页分享时带上当前歌曲）
    init(music: Music? = nil) {
        _selectedMusic = State(initialValue: music)
    }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appState = AppState.shared

    /// 文字内容
    @State private var content = ""
    /// 可见范围（1 公开 / 0 私密）
    @State private var permission = Constants.CircleConfig.permissionPublic
    /// 是否正在发布
    @State private var isPublishing = false
    /// 是否展示选歌页
    @State private var showChooseSong = false
    /// 是否展示可见范围选择
    @State private var showPermissionPicker = false
    /// 轻提示
    @State private var alertMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Dimens.middleMargin) {
                    textArea
                    songRow
                    permissionRow
                }
                .padding(Dimens.middleMargin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Colors.pageBackgroundColor)
        .fullScreenCover(isPresented: $showChooseSong) {
            MusicCirCleCheckPage(onSelect: { music in
                selectedMusic = music
                showChooseSong = false
            })
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

    // MARK: - 顶部按钮

    /// 顶部「取消 / 发布」
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Text("取消")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.blackColor)
                    .padding(.horizontal, Dimens.middleMargin)
                    .frame(height: Dimens.btnHeight)
                    .background(Colors.whiteColor)
                    .cornerRadius(Dimens.borderRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Dimens.borderRadius)
                            .stroke(Colors.grayColor, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: publish) {
                Text(isPublishing ? "发布中..." : "发布")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.whiteColor)
                    .padding(.horizontal, Dimens.middleMargin)
                    .frame(height: Dimens.btnHeight)
                    .background(Colors.primaryColor)
                    .cornerRadius(Dimens.borderRadius)
            }
            .buttonStyle(.plain)
            .disabled(isPublishing)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
    }

    // MARK: - 内容

    /// 文字输入区
    private var textArea: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $content)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .scrollContentBackground(.hidden)
                .frame(height: Dimens.shareTextAreaHeight)
                .padding(Dimens.smallMargin)

            // 占位文案（TextEditor 没有原生 placeholder）
            if content.isEmpty {
                Text("这一刻的想法")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.subColor)
                    .padding(.horizontal, Dimens.smallMargin + Dimens.smallMargin)
                    .padding(.vertical, Dimens.smallMargin + Dimens.smallMargin)
                    .allowsHitTesting(false)
            }
        }
        .background(Colors.grayColor)
        .cornerRadius(Dimens.borderRadius)
    }

    /// 分享的歌曲（没有歌时提示选择）
    private var songRow: some View {
        Group {
            if let music = selectedMusic {
                HStack(spacing: Dimens.middleMargin) {
                    MusicCoverView(cover: music.cover, size: Dimens.musicCover)

                    Text("\(music.displayAuthorName) - \(music.songName)")
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.blackColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(spacing: Dimens.middleMargin) {
                    Text("请选择一首歌曲")
                        .font(.system(size: Dimens.normalFont))
                        .foregroundColor(Colors.subColor)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image("icon_arrow")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
                        .opacity(0.5)
                }
            }
        }
        .padding(Dimens.middleMargin)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
        .contentShape(Rectangle())
        .onTapGesture {
            // 未选歌时提示去挑，已选歌时点一下可以换一首
            showChooseSong = true
        }
    }

    /// 「谁可以看」行
    private var permissionRow: some View {
        HStack(spacing: Dimens.middleMargin) {
            Image("icon_permission")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.middleIcon, height: Dimens.middleIcon)
                .opacity(0.5)

            Text("谁可以看")
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(Constants.CircleConfig.permissionName(permission))
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.subColor)

            Image("icon_arrow")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
                .opacity(0.5)
        }
        .padding(Dimens.middleMargin)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
        .contentShape(Rectangle())
        .onTapGesture { showPermissionPicker = true }
        .confirmationDialog("谁可以看", isPresented: $showPermissionPicker, titleVisibility: .visible) {
            Button("公开") { permission = Constants.CircleConfig.permissionPublic }
            Button("私密") { permission = Constants.CircleConfig.permissionPrivate }
            Button("取消", role: .cancel) {}
        }
    }

    // MARK: - 发布

    /// 发布动态
    private func publish() {
        guard !isPublishing else { return }

        // 必须有一首歌（对齐 uniapp：relationId 取所分享歌曲的 id）
        guard let music = selectedMusic else {
            alertMessage = "请先选择要分享的歌曲"
            return
        }

        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)

        isPublishing = true
        HTTPClient.shared.insertCircle(
            content: text,
            relationId: music.id,
            permission: permission
        ) { result in
            DispatchQueue.main.async {
                isPublishing = false
                switch result {
                case .success(let newId):
                    // 后端 insertCircle 没有写 create_time，新动态在列表里会排到最后，
                    // 所以这里本地构造一条动态随通知带过去，列表直接置顶展示（数据确实已入库）
                    let post = MusicCircle(
                        id: newId,
                        content: text,
                        username: appState.userData?.username,
                        useravater: appState.userData?.avater,
                        userId: appState.userData?.id,
                        createTime: DateUtils.nowString(),
                        type: Constants.CircleConfig.musicType,
                        musicSongName: music.songName,
                        musicAuthorName: music.authorName,
                        musicCover: music.cover,
                        musicPlayUrl: music.playUrl,
                        musicLocalPlayUrl: music.localPlayUrl
                    )
                    NotificationCenter.default.post(name: .musicCircleDidUpdate, object: post)
                    dismiss()
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    MusicSharePage(
        music: Music(
            id: 23,
            songName: "黄昏",
            authorName: "孙露",
            cover: ""
        )
    )
}
