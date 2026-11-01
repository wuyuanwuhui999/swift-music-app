//
//  AudioPlayerManager.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import Foundation
import AVFoundation
import Combine

/// 音频播放引擎（AVPlayer 薄封装）
///
/// 对应 uniapp 的 `store.audio`（innerAudioContext）/ flutter 的 `AudioPlayer`：
/// 只负责「加载音频、播放、暂停、跳转、上报进度」，业务状态（当前歌曲、歌单、循环模式）
/// 统一由 `PlayerState` 管理，避免两处状态打架。
final class AudioPlayerManager: NSObject, ObservableObject {
    /// 是否正在播放
    @Published private(set) var isPlaying = false
    /// 当前播放位置（秒）
    @Published private(set) var position: Double = 0
    /// 音频总时长（秒），未知时为 0
    @Published private(set) var duration: Double = 0
    /// 播放完成回调（由 PlayerState 接管，按循环模式决定下一首）
    var onFinish: (() -> Void)?

    /// 当前已加载的音频地址（用于判断是否需要重新加载）
    private(set) var loadedURL: URL?

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    deinit {
        removeObservers()
    }

    // MARK: - 播放控制

    /// 加载音频
    /// - Parameters:
    ///   - url: 音频地址
    ///   - autoPlay: 是否加载后立即播放
    func load(url: URL, autoPlay: Bool) {
        if loadedURL == url, player != nil {
            if autoPlay { play() }
            return
        }

        configureAudioSession()
        removeObservers()

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        loadedURL = url
        position = 0
        duration = 0

        // 播放完成通知
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isPlaying = false
            self.onFinish?()
        }

        // 进度回调（0.3s 一次，足够驱动进度条与歌词高亮）
        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.3, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            self.position = time.seconds.isFinite ? time.seconds : 0
            if let total = self.player?.currentItem?.duration.seconds, total.isFinite, total > 0 {
                self.duration = total
            }
        }

        if autoPlay {
            play()
        }
    }

    /// 播放
    func play() {
        guard let player = player else { return }
        configureAudioSession()
        player.play()
        isPlaying = true
    }

    /// 暂停
    func pause() {
        player?.pause()
        isPlaying = false
    }

    /// 跳转到指定秒数
    func seek(to seconds: Double) {
        guard let player = player else { return }
        let target = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
        player.seek(to: target) { [weak self] _ in
            self?.position = max(0, seconds)
        }
    }

    /// 停止并清空（切换歌曲 / 清空播放列表时使用）
    func stop() {
        player?.pause()
        removeObservers()
        player = nil
        loadedURL = nil
        isPlaying = false
        position = 0
        duration = 0
    }

    // MARK: - 私有

    /// 配置音频会话：保证静音键打开时也能出声，并支持与其他音频混合
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ 音频会话配置失败: \(error.localizedDescription)")
        }
    }

    /// 移除时间观察者与播放完成监听
    private func removeObservers() {
        if let timeObserver = timeObserver, let player = player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        if let endObserver = endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }
}
