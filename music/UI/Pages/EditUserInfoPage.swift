//
//  EditUserInfoPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI
import PhotosUI

/// 个人信息页（头像 / 昵称 / 邮箱 / 性别 / 个性签名 + 修改密码 + 退出登录）
///
/// 入口：「我的」页用户卡片右上角的编辑按钮。
///
/// 对齐 uniapp `UserPage.vue`：
/// - 头像：点一下从相册选图上传（`POST /service/user/updateAvater`）
/// - 昵称 / 邮箱 / 个性签名：弹窗输入后立即保存
/// - 性别：弹层选择男 / 女
/// - 底部「修改密码」进修改密码页，「退出登录」清登录态回到欢迎页
///
/// 接口：
/// - `PUT /service/user/updateUser` 更新资料
/// - `POST /service/user/updateAvater` 上传头像
struct EditUserInfoPage: View {
    @ObservedObject private var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss

    /// 正在编辑的字段
    @State private var editingField: EditField?
    /// 编辑框内容
    @State private var editingText = ""
    /// 是否展示性别选择
    @State private var showSexPicker = false
    /// 选中的相册图片
    @State private var photoItem: PhotosPickerItem?
    /// 是否正在保存
    @State private var isSaving = false
    /// 是否展示修改密码页
    @State private var showUpdatePassword = false
    /// 是否展示退出确认
    @State private var showLogoutConfirm = false
    /// 是否展示文本编辑弹窗
    @State private var showEditAlert = false
    /// 轻提示
    @State private var alertMessage: String?

    /// 可编辑字段
    enum EditField: String, Identifiable {
        case username
        case email
        case sign

        var id: String { rawValue }

        var title: String {
            switch self {
            case .username: return "昵称"
            case .email: return "邮箱"
            case .sign: return "个性签名"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            MusicNavBar(title: "个人信息")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Dimens.middleMargin) {
                    infoCard
                    actionCard
                }
                .padding(Dimens.middleMargin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Colors.pageBackgroundColor)
        .fullScreenCover(isPresented: $showUpdatePassword) {
            UpdatePasswordPage()
        }
        .task(id: photoItem) {
            await uploadAvatarIfNeeded()
        }
        .alert(editingField?.title ?? "", isPresented: $showEditAlert) {
            TextField("", text: $editingText)
            Button("取消", role: .cancel) {}
            Button("确定") {
                if let field = editingField { save(field: field) }
            }
        }
        .confirmationDialog("性别", isPresented: $showSexPicker, titleVisibility: .visible) {
            Button("男") { saveSex("0") }
            Button("女") { saveSex("1") }
            Button("取消", role: .cancel) {}
        }
        .confirmationDialog("确定退出登录？", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("退出登录", role: .destructive) { logout() }
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
    }

    // MARK: - 子视图

    /// 资料卡片
    private var infoCard: some View {
        VStack(spacing: 0) {
            // 头像
            HStack(spacing: Dimens.middleMargin) {
                Text("头像")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.blackColor)

                Spacer()

                PhotosPicker(selection: $photoItem, matching: .images) {
                    avatarView
                }

                Image("icon_arrow")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
            }
            .padding(Dimens.middleMargin)

            divider

            editRow(title: "昵称", value: appState.userData?.username ?? "", field: .username)
            divider
            editRow(title: "邮箱", value: appState.userData?.email ?? "", field: .email)
            divider

            // 性别
            Button(action: { showSexPicker = true }) {
                rowContent(title: "性别", value: sexText)
            }
            .buttonStyle(.plain)

            divider
            editRow(title: "个性签名", value: appState.userData?.sign ?? "", field: .sign)
        }
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    /// 修改密码 / 退出登录
    private var actionCard: some View {
        VStack(spacing: Dimens.middleMargin) {
            Button(action: { showUpdatePassword = true }) {
                Text("修改密码")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.blackColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: Dimens.btnHeight)
                    .background(Colors.whiteColor)
                    .cornerRadius(Dimens.borderRadius)
            }
            .buttonStyle(.plain)

            Button(action: { showLogoutConfirm = true }) {
                Text("退出登录")
                    .font(.system(size: Dimens.normalFont))
                    .foregroundColor(Colors.primaryColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: Dimens.btnHeight)
                    .background(Colors.whiteColor)
                    .cornerRadius(Dimens.borderRadius)
            }
            .buttonStyle(.plain)
        }
    }

    /// 单行编辑项
    private func editRow(title: String, value: String, field: EditField) -> some View {
        Button(action: {
            editingText = value
            editingField = field
            showEditAlert = true
        }) {
            rowContent(title: title, value: value)
        }
        .buttonStyle(.plain)
    }

    private func rowContent(title: String, value: String) -> some View {
        HStack(spacing: Dimens.middleMargin) {
            Text(title)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.blackColor)

            Spacer()

            Text(value.isEmpty ? "未设置" : value)
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.subColor)
                .lineLimit(1)

            Image("icon_arrow")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Dimens.smallIcon, height: Dimens.smallIcon)
        }
        .padding(Dimens.middleMargin)
        .contentShape(Rectangle())
    }

    private var divider: some View {
        Rectangle()
            .fill(Colors.grayColor)
            .frame(height: 1)
            .padding(.leading, Dimens.middleMargin)
    }

    /// 头像
    private var avatarView: some View {
        ZStack {
            Colors.pageBackgroundColor

            if let avater = appState.userData?.avater,
               let urlString = MusicUtils.coverURL(avater),
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: Dimens.bigAvater, height: Dimens.bigAvater)
        .clipShape(Circle())
    }

    private var avatarPlaceholder: some View {
        Text(String(appState.userData?.username.prefix(1) ?? "我"))
            .font(.system(size: Dimens.middleFont))
            .foregroundColor(Colors.subColor)
    }

    // MARK: - 计算属性

    private var sexText: String {
        switch appState.userData?.sex {
        case "0": return "男"
        case "1": return "女"
        default: return "未设置"
        }
    }

    // MARK: - 交互

    /// 保存文本字段
    private func save(field: EditField) {
        guard var user = appState.userData else { return }
        let value = editingText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch field {
        case .username:
            guard !value.isEmpty else {
                alertMessage = "昵称不能为空"
                return
            }
            user.username = value
        case .email:
            user.email = value
        case .sign:
            user.sign = value
        }

        submit(user)
    }

    /// 保存性别
    private func saveSex(_ sex: String) {
        guard var user = appState.userData else { return }
        user.sex = sex
        submit(user)
    }

    /// 提交资料更新
    private func submit(_ user: User) {
        guard !isSaving else { return }
        isSaving = true

        HTTPClient.shared.updateUser(userData: user) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success(let updated):
                    appState.updateUserData(updated)
                    alertMessage = "保存成功"
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }
    }

    /// 选完图后上传头像
    @MainActor
    private func uploadAvatarIfNeeded() async {
        guard let photoItem = photoItem else { return }
        guard let data = try? await photoItem.loadTransferable(type: Data.self) else { return }

        HTTPClient.shared.updateAvatar(imageData: data) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let avater):
                    if var user = appState.userData {
                        user.avater = avater
                        appState.updateUserData(user)
                    }
                    alertMessage = "头像已更新"
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
                self.photoItem = nil
            }
        }
    }

    /// 退出登录
    private func logout() {
        PlayerState.shared.pause()
        appState.clearUserData()
        dismiss()
    }
}

#Preview {
    EditUserInfoPage()
}
