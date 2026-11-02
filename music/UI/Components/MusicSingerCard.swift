//
//  MusicSingerCard.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 首页「推荐歌手」模块卡片
///
/// 对齐 uniapp `MusicSingerComponent`：标题栏（可折叠 + 更多）+ 一行歌手头像（默认 4 个）。
/// 接口：`GET /service/music/getMusicAuthorListByCategoryId?categoryId=0&pageSize=4`
struct MusicSingerCard: View {
    /// 分类信息（category 为「推荐歌手」）
    let category: MusicCategory
    /// 点「更多」
    let onMore: () -> Void
    /// 点某个歌手
    let onAuthorTap: (MusicAuthor) -> Void

    /// 歌手列表
    @State private var authors: [MusicAuthor] = []
    /// 是否折叠
    @State private var isFold = false

    var body: some View {
        VStack(alignment: .leading, spacing: Dimens.middleMargin) {
            MusicModuleHeader(
                title: category.category,
                isFold: isFold,
                onFold: { isFold.toggle() },
                onMore: onMore
            )

            if !isFold && !authors.isEmpty {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(authors) { author in
                        Button(action: { onAuthorTap(author) }) {
                            VStack(spacing: Dimens.smallMargin) {
                                MusicAuthorAvatarView(author: author, size: Dimens.musicSingerAvatar)
                                Text(author.authorName)
                                    .font(.system(size: Dimens.normalFont))
                                    .foregroundColor(Colors.blackColor)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Dimens.middleMargin)
        .background(Colors.whiteColor)
        .cornerRadius(Dimens.borderRadius)
        .onAppear(perform: loadAuthors)
    }

    // MARK: - 数据

    /// 加载推荐歌手
    private func loadAuthors() {
        guard authors.isEmpty else { return }
        HTTPClient.shared.getMusicAuthorListByCategoryId(
            categoryId: 0,
            pageNum: 1,
            pageSize: Constants.MusicConfig.homeSingerCount
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (list, _)):
                    authors = list
                case .failure(let error):
                    print("❌ 获取推荐歌手失败: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    MusicSingerCard(
        category: MusicCategory(id: 1, category: "推荐歌手", classify: "推荐歌手"),
        onMore: {},
        onAuthorTap: { _ in }
    )
    .padding()
    .background(Colors.pageBackgroundColor)
}
