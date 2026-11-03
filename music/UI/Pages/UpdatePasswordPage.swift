//
//  UpdatePasswordPage.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 修改密码页
///
/// 入口：个人信息页「修改密码」。
///
/// 对齐 uniapp `UpdatePasswordPage.vue`：原密码 + 新密码 + 确认新密码，校验一致后提交。
///
/// 接口：`PUT /service/user/updatePassword`（oldPassword、newPassword，均为 MD5）
struct UpdatePasswordPage: View {
    @Environment(\.dismiss) private var dismiss

    /// 原密码
    @State private var oldPassword = ""
    /// 新密码
    @State private var newPassword = ""
    /// 确认新密码
    @State private var confirmPassword = ""
    /// 是否正在提交
    @State private var isSubmitting = false
    /// 轻提示
    @State private var alertMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            MusicNavBar(title: "修改密码")

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Dimens.middleMargin) {
                    passwordCard
                    submitButton
                }
                .padding(Dimens.middleMargin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Colors.pageBackgroundColor)
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

    private var passwordCard: some View {
        VStack(spacing: Dimens.middleMargin) {
            secureField("原密码", text: $oldPassword)
            secureField("新密码", text: $newPassword)
            secureField("确认新密码", text: $confirmPassword)
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
    }

    private func secureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField("", text: text, prompt: Text(placeholder)
            .foregroundColor(Colors.grayColor))
            .font(.system(size: Dimens.normalFont))
            .foregroundColor(Colors.blackColor)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, Dimens.middleMargin)
            .frame(height: Dimens.inputHeight)
            .background(Colors.pageBackgroundColor)
            .cornerRadius(Dimens.borderRadius)
    }

    private var submitButton: some View {
        Button(action: submit) {
            Text(isSubmitting ? "提交中..." : "确定修改")
                .font(.system(size: Dimens.normalFont))
                .foregroundColor(Colors.whiteColor)
                .frame(maxWidth: .infinity)
                .frame(height: Dimens.btnHeight)
                .background(canSubmit ? Colors.primaryColor : Colors.grayColor)
                .cornerRadius(Dimens.btnHeight / 2)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || isSubmitting)
    }

    // MARK: - 计算属性

    private var canSubmit: Bool {
        !oldPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty
    }

    // MARK: - 交互

    private func submit() {
        guard newPassword == confirmPassword else {
            alertMessage = "两次输入的新密码不一致"
            return
        }
        guard newPassword != oldPassword else {
            alertMessage = "新密码不能与原密码相同"
            return
        }
        guard !isSubmitting else { return }

        isSubmitting = true
        HTTPClient.shared.updatePassword(oldPassword: oldPassword, newPassword: newPassword) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    oldPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    alertMessage = "密码修改成功"
                case .failure(let error):
                    alertMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    UpdatePasswordPage()
}
