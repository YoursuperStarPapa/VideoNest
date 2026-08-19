import Foundation
import Combine

// MARK: - Detail ViewModel
@MainActor
class DetailViewModel: ObservableObject {
    @Published var video: VideoItem
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedPlaySourceIndex = 0
    @Published var selectedEpisodeIndex = 0
    @Published var isFavorited = false
    @Published var watchHistory: WatchHistory?
    @Published var playURL: String?
    
    private let api = TVBoxAPIClient.shared
    var sourceManager: SourceManager
    private var dataStore: DataStore
    
    init(video: VideoItem, sourceManager: SourceManager, dataStore: DataStore) {
        self.video = video
        self.sourceManager = sourceManager
        self.dataStore = dataStore
        self.isFavorited = dataStore.isFavorited(videoId: video.vod_id)
        self.watchHistory = dataStore.getHistory(for: video.vod_id)
    }
    
    var playSources: [PlaySource] {
        video.playSources
    }
    
    var currentPlaySource: PlaySource? {
        guard selectedPlaySourceIndex < playSources.count else { return nil }
        return playSources[selectedPlaySourceIndex]
    }
    
    var currentEpisode: Episode? {
        guard let source = currentPlaySource,
              selectedEpisodeIndex < source.episodes.count else { return nil }
        return source.episodes[selectedEpisodeIndex]
    }
    
    // MARK: - Load Detail
    func loadDetail() async {
        guard let source = sourceManager.activeSource else { return }
        isLoading = true
        
        do {
            if let detail = try await api.fetchDetail(from: source, videoID: video.vod_id) {
                video = detail
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Play Episode
    func playEpisode(sourceIndex: Int, episodeIndex: Int) async {
        selectedPlaySourceIndex = sourceIndex
        selectedEpisodeIndex = episodeIndex
        
        guard let episode = currentEpisode, let url = URL(string: episode.url) else {
            error = "无效的播放地址"
            return
        }
        
        // 解析播放地址
        do {
            let resolved = try await api.resolvePlayURL(episode.url)
            playURL = resolved
            
            // 更新观看历史
            let history = WatchHistory(
                videoId: video.vod_id,
                videoName: video.vod_name,
                videoPic: video.vod_pic,
                sourceId: sourceManager.activeSource?.id ?? "",
                lastEpisodeIndex: episodeIndex,
                lastPlayPosition: 0,
                lastPlayTime: Date(),
                isFinished: false
            )
            dataStore.addToHistory(history)
            watchHistory = history
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Resume Play
    func resumePlay() async {
        guard let history = watchHistory else { return }
        await playEpisode(sourceIndex: selectedPlaySourceIndex, episodeIndex: history.lastEpisodeIndex)
    }
    
    // MARK: - Favorite
    func toggleFavorite() {
        guard let source = sourceManager.activeSource else { return }
        dataStore.toggleFavorite(video: video, sourceId: source.id)
        isFavorited.toggle()
    }
    
    // MARK: - Update Progress
    func updateProgress(position: Double, duration: Double) {
        guard let source = sourceManager.activeSource else { return }
        let history = WatchHistory(
            videoId: video.vod_id,
            videoName: video.vod_name,
            videoPic: video.vod_pic,
            sourceId: source.id,
            lastEpisodeIndex: selectedEpisodeIndex,
            lastPlayPosition: position,
            lastPlayTime: Date(),
            isFinished: position >= duration * 0.95
        )
        dataStore.addToHistory(history)
        watchHistory = history
    }
}
