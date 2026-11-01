//
//  PlayerState.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation
import Combine

/// 循环播放模式（与 uniapp 版本 `LoopModeEnum` 一致）
enum LoopMode: String, CaseIterable {
    case order      // 顺序播放
    case random     // 随机播放
    case repeatOne  // 单曲循环

    var title: String {
        switch self {
        case .order: return "顺序播放"
        case .random: return "随机播放"
        case .repeatOne: return "单曲循环"
        }
    }
}

/// 播放状态（全局单例）
///
/// 对应 uniapp 版本的 `useStore().music` / flutter 版本的 `PlayerMusicProvider`：
/// 只保存「当前歌曲 + 播放列表 + 播放状态 + 循环模式」这些跨页面共享的状态，
/// 真正的音频播放引擎在播放页阶段接入，这里先保证状态与本地缓存打通，
/// 底部 MiniPlayer 的封面、旋转动画都由它驱动。
final class PlayerState: ObservableObject {
    static let shared = PlayerState()

    /// 当前播放的歌曲（为空表示还没有播放过任何歌）
    @Published private(set) var currentMusic: Music?
    /// 播放列表
    @Published private(set) var musicList: [Music] = []
    /// 是否正在播放（驱动 MiniPlayer 唱片旋转）
    @Published private(set) var isPlaying: Bool = false
    /// 循环模式
    @Published private(set) var loopMode: LoopMode = .order
    /// 当前播放列表所属模块名（对齐 uniapp `store.classifyName`）
    @Published private(set) var classifyName: String = ""

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - 读写

    /// 设置当前歌曲
    /// - Parameters:
    ///   - music: 歌曲，nil 表示清空
    ///   - autoPlay: 是否自动播放（从缓存恢复时传 false，与 uniapp `store.setMusic(item, false)` 一致）
    func setMusic(_ music: Music?, autoPlay: Bool) {
        currentMusic = music
        isPlaying = autoPlay && music != nil
        saveMusicToCache(music)
    }

    /// 设置播放列表
    func setMusicList(_ list: [Music]) {
        musicList = list
        saveListToCache(list)
    }

    /// 设置循环模式
    func setLoopMode(_ mode: LoopMode) {
        loopMode = mode
        defaults.set(mode.rawValue, forKey: Constants.StorageKey.loopMode)
    }

    /// 更新播放状态（播放器接入后由播放引擎回调）
    func setPlaying(_ playing: Bool) {
        isPlaying = playing
    }

    /// 更新当前播放列表所属模块名
    /// 对齐 uniapp `store.classifyName`：列表行据此判断「本模块是否有歌正在播放」
    func setClassifyName(_ name: String) {
        classifyName = name
    }

    // MARK: - 本地缓存

    /// 从本地缓存恢复「当前歌曲 / 播放列表 / 循环模式」
    /// 进入首页时调用一次即可（对齐 uniapp `MusicIndexPage.onMounted` 里的 useStorage）
    func restoreFromCache() {
        if let music = loadMusicFromCache() {
            currentMusic = music
        }
        if let list = loadListFromCache() {
            musicList = list
        }
        if let raw = defaults.string(forKey: Constants.StorageKey.loopMode),
           let mode = LoopMode(rawValue: raw) {
            loopMode = mode
        }
    }

    private func saveMusicToCache(_ music: Music?) {
        guard let music = music, let data = try? JSONEncoder().encode(music) else {
            defaults.removeObject(forKey: Constants.StorageKey.music)
            return
        }
        defaults.set(data, forKey: Constants.StorageKey.music)
    }

    private func loadMusicFromCache() -> Music? {
        guard let data = defaults.data(forKey: Constants.StorageKey.music) else { return nil }
        return try? JSONDecoder().decode(Music.self, from: data)
    }

    private func saveListToCache(_ list: [Music]) {
        guard let data = try? JSONEncoder().encode(list) else {
            defaults.removeObject(forKey: Constants.StorageKey.musicList)
            return
        }
        defaults.set(data, forKey: Constants.StorageKey.musicList)
    }

    private func loadListFromCache() -> [Music]? {
        guard let data = defaults.data(forKey: Constants.StorageKey.musicList) else { return nil }
        return try? JSONDecoder().decode([Music].self, from: data)
    }
}
