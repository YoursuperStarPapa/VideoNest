import Foundation
import AVFoundation
import AVKit
import MediaPlayer
import Combine

// MARK: - Player Manager
class PlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playbackSpeed: Double = 1.0
    @Published var isAirPlayActive = false
    @Published var selectedSubtitle: SubtitleTrack?
    @Published var selectedAudioTrack: AudioTrack?
    @Published var subtitles: [SubtitleTrack] = []
    @Published var audioTracks: [AudioTrack] = []
    
    var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Playback Control
    func setupPlayer(url: URL) {
        // 配置音频会话
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = true
        
        // 时间观察
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        // 监听时长
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .readyToPlay {
                    self?.duration = playerItem.duration.seconds.isFinite ? playerItem.duration.seconds : 0
                }
            }
            .store(in: &cancellables)
        
        // 监听播放结束
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPlaying = false
            }
            .store(in: &cancellables)
        
        // 提取字幕和音轨
        extractMediaSelection()
    }
    
    func play() {
        player?.play()
        player?.rate = Float(playbackSpeed)
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func togglePlay() {
        isPlaying ? pause() : play()
    }
    
    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func seekForward(_ seconds: Double = 15) {
        seek(to: min(currentTime + seconds, duration))
    }
    
    func seekBackward(_ seconds: Double = 15) {
        seek(to: max(currentTime - seconds, 0))
    }
    
    func setSpeed(_ speed: Double) {
        playbackSpeed = speed
        if isPlaying {
            player?.rate = Float(speed)
        }
    }
    
    // MARK: - Subtitle & Audio Track
    func selectSubtitle(_ track: SubtitleTrack?) {
        guard let player = player, let item = player.currentItem else { return }
        selectedSubtitle = track
        
        if let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            if let track = track, let option = group.options.first(where: { $0.displayName == track.name }) {
                item.select(option, in: group)
            } else {
                item.select(nil, in: group)
            }
        }
    }
    
    func selectAudioTrack(_ track: AudioTrack?) {
        guard let player = player, let item = player.currentItem else { return }
        selectedAudioTrack = track
        
        if let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
            if let track = track, let option = group.options.first(where: { $0.displayName == track.name }) {
                item.select(option, in: group)
            }
        }
    }
    
    private func extractMediaSelection() {
        guard let item = player?.currentItem else { return }
        
        // 字幕
        if let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            subtitles = group.options.map { SubtitleTrack(name: $0.displayName, languageCode: $0.extendedLanguageTag ?? "") }
        }
        
        // 音轨
        if let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
            audioTracks = group.options.map { AudioTrack(name: $0.displayName, languageCode: $0.extendedLanguageTag ?? "") }
        }
    }
    
    // MARK: - Picture in Picture
    func setupPiP(controller: AVPlayerViewController) {
        if AVPictureInPictureController.isPictureInPictureSupported() {
            controller.allowsPictureInPicturePlayback = true
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player?.pause()
        player = nil
        cancellables.removeAll()
        isPlaying = false
        currentTime = 0
        duration = 0
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - Media Tracks
struct SubtitleTrack: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let languageCode: String
}

struct AudioTrack: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let languageCode: String
}
