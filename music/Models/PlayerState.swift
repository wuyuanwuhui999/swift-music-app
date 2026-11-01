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

    /// 循环模式图标资源名
    var icon: String {
        switch self {
        case .order: return "icon_music_order"
        case .random: return "icon_music_random"
        case .repeatOne: return "icon_music_loop"
        }
    }
}

/// 播放状态（全局单例）
///
/// 对应 uniapp 的 `useStore()`（musicItem / musicList / isPlaying / loop）+ `store.audio`、
/// flutter 的 `PlayerMusicProvider` + `AudioPlayer`：
/// 这里把「业务状态」和「播放引擎」收在一个门面上，UI 只观察 `PlayerState.shared`，
/// 真正发声的 AVPlayer 封装在 `AudioPlayerManager` 里。
final class PlayerState: ObservableObject {
    static let shared = PlayerState()

    /// 当前播放的歌曲（为空表示还没有播放过任何歌）
    @Published private(set) var currentMusic: Music?
    /// 播放列表
    @Published private(set) var musicList: [Music] = []
    /// 是否正在播放（驱动 MiniPlayer 唱片旋转、播放页按钮）
    @Published private(set) var isPlaying: Bool = false
    /// 循环模式
    @Published private(set) var loopMode: LoopMode = .order
    /// 当前播放列表所属模块名（对齐 uniapp `store.classifyName`）
    @Published private(set) var classifyName: String = ""
    /// 当前播放进度（秒）
    @Published private(set) var position: Double = 0
    /// 当前音频总时长（秒），未知时为 0
    @Published private(set) var duration: Double = 0

    private let engine = AudioPlayerManager()
    private let defaults = UserDefaults.standard

    private init() {
        // 把播放引擎的状态桥接出来，UI 只依赖 PlayerState
        engine.$isPlaying
            .receive(on: RunLoop.main)
            .assign(to: &$isPlaying)
        engine.$position
            .receive(on: RunLoop.main)
            .assign(to: &$position)
        engine.$duration
            .receive(on: RunLoop.main)
            .assign(to: &$duration)

        // 一首播完：按循环模式决定重播 / 下一首
        engine.onFinish = { [weak self] in
            self?.handleTrackFinished()
        }
    }

    // MARK: - 设置数据

    /// 设置当前歌曲
    /// - Parameters:
    ///   - music: 歌曲，nil 表示清空
    ///   - autoPlay: 是否立即播放（从缓存恢复、首页推荐关键词时传 false）
    func setMusic(_ music: Music?, autoPlay: Bool) {
        currentMusic = music
        saveMusicToCache(music)

        guard let music = music, let url = audioURL(for: music) else {
            engine.stop()
            return
        }
        engine.load(url: url, autoPlay: autoPlay)
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

    /// 更新当前播放列表所属模块名
    func setClassifyName(_ name: String) {
        classifyName = name
    }

    /// 更新当前歌曲的喜欢状态（点赞接口回调后同步）
    func updateLike(isLike: Int) {
        guard var music = currentMusic else { return }
        music.isLike = isLike
        currentMusic = music
        if let index = musicList.firstIndex(where: { $0.id == music.id }) {
            musicList[index].isLike = isLike
        }
    }

    // MARK: - 播放控制

    /// 播放
    func play() {
        guard let music = currentMusic else { return }
        ensureLoaded(music)
        engine.play()
    }

    /// 暂停
    func pause() {
        engine.pause()
    }

    /// 播放 / 暂停切换
    func togglePlay() {
        isPlaying ? pause() : play()
    }

    /// 直接设置播放状态（等价于 play / pause）
    func setPlaying(_ playing: Bool) {
        playing ? play() : pause()
    }

    /// 跳转到指定秒数（拖动进度条）
    func seek(to seconds: Double) {
        engine.seek(to: seconds)
    }

    /// 下一首（顺序播放到末尾回到第一首；随机播放随机取一首）
    func playNext() {
        guard !musicList.isEmpty else {
            // 没有播放列表时，把当前这首重头播
            engine.seek(to: 0)
            engine.play()
            return
        }
        let nextIndex: Int
        switch loopMode {
        case .random:
            nextIndex = Int.random(in: 0..<musicList.count)
        case .order, .repeatOne:
            nextIndex = (currentIndex() + 1) % musicList.count
        }
        switchTo(index: nextIndex)
    }

    /// 上一首（顺序播放到开头回到最后一首；随机播放随机取一首）
    func playPrevious() {
        guard !musicList.isEmpty else {
            engine.seek(to: 0)
            engine.play()
            return
        }
        let prevIndex: Int
        switch loopMode {
        case .random:
            prevIndex = Int.random(in: 0..<musicList.count)
        case .order, .repeatOne:
            prevIndex = (currentIndex() - 1 + musicList.count) % musicList.count
        }
        switchTo(index: prevIndex)
    }

    // MARK: - 本地缓存

    /// 从本地缓存恢复「当前歌曲 / 播放列表 / 循环模式」
    /// 只恢复数据不自动播放，进入播放页时再真正发声
    func restoreFromCache() {
        if let music = loadMusicFromCache(), currentMusic == nil {
            currentMusic = music
        }
        if let list = loadListFromCache(), musicList.isEmpty {
            musicList = list
        }
        if let raw = defaults.string(forKey: Constants.StorageKey.loopMode),
           let mode = LoopMode(rawValue: raw) {
            loopMode = mode
        }
    }

    // MARK: - 私有

    /// 当前歌曲在播放列表中的下标
    private func currentIndex() -> Int {
        guard let current = currentMusic,
              let index = musicList.firstIndex(where: { $0.id == current.id }) else { return 0 }
        return index
    }

    /// 切歌并播放
    private func switchTo(index: Int) {
        guard musicList.indices.contains(index) else { return }
        let music = musicList[index]
        currentMusic = music
        saveMusicToCache(music)
        if let url = audioURL(for: music) {
            engine.load(url: url, autoPlay: true)
        }
    }

    /// 确保音频已加载（首次进入播放页时还没加载过）
    private func ensureLoaded(_ music: Music) {
        guard let url = audioURL(for: music) else { return }
        if engine.loadedURL != url {
            engine.load(url: url, autoPlay: false)
        }
    }

    /// 一首播完后的处理
    private func handleTrackFinished() {
        switch loopMode {
        case .repeatOne:
            engine.seek(to: 0)
            engine.play()
        case .order, .random:
            playNext()
        }
    }

    /// 歌曲的真实播放地址
    /// 优先用后端转发的 `localPlayUrl`（uniapp / flutter 都是这么放的），其次用外网 `playUrl`
    private func audioURL(for music: Music) -> URL? {
        if let local = music.localPlayUrl, !local.isEmpty {
            if local.hasPrefix("http://") || local.hasPrefix("https://") {
                return URL(string: local)
            }
            return URL(string: Constants.baseURL + local)
        }
        if let playUrl = music.playUrl, !playUrl.isEmpty {
            return URL(string: playUrl)
        }
        return nil
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
