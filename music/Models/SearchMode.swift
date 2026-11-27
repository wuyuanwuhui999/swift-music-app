//
//  SearchMode.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation

/// 搜索模式（对齐后端 `searchMusic` 的 `searchMode` 参数）
///
/// - `normal`：普通模糊搜索（默认）
/// - `smart`：大模型智能搜索（需要额外传 `modelId` 与 `searchId`）
enum SearchMode: String, CaseIterable, Identifiable {
    case normal = "normal"
    case smart = "smart"

    var id: String { rawValue }

    /// 导航栏 / 弹层里展示的文案
    var title: String {
        switch self {
        case .normal: return "普通搜索"
        case .smart: return "智能搜索"
        }
    }
}
