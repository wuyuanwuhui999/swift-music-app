//
//  MusicApp.swift
//  music
//
//  Created by 吴文强 on 2026/11/1.
//

import SwiftUI

/// 应用入口：根视图为 WelcomePage（校验登录态后分流到 MusicIndexPage / LoginPage）
@main
struct MusicApp: App {
    var body: some Scene {
        WindowGroup {
            WelcomePage()
        }
    }
}
