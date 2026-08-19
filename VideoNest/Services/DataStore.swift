import Foundation

// MARK: - Data Store (本地数据持久化)
class DataStore: ObservableObject {
    static let shared = DataStore()
    
    @Published var watchHistory: [WatchHistory] = []
    @Published var favorites: [Favorite] = []
    
    private let defaults = UserDefaults.standard
    private let historyKey = "watch_history"
    private let favoritesKey = "favorites"
    
    init() {
        loadHistory()
        loadFavorites()
    }
    
    // MARK: - Watch History
    func addToHistory(_ history: WatchHistory) {
        // 移除旧记录，添加新的到最前面
        watchHistory.removeAll { $0.videoId == history.videoId }
        watchHistory.insert(history, at: 0)
        
        // 最多保留 200 条
        if watchHistory.count > 200 {
            watchHistory = Array(watchHistory.prefix(200))
        }
        saveHistory()
    }
    
    func getHistory(for videoId: String) -> WatchHistory? {
        watchHistory.first { $0.videoId == videoId }
    }
    
    func clearHistory() {
        watchHistory.removeAll()
        saveHistory()
    }
    
    func removeHistory(at offsets: IndexSet) {
        watchHistory.remove(atOffsets: offsets)
        saveHistory()
    }
    
    // MARK: - Favorites
    func addFavorite(_ favorite: Favorite) {
        guard !isFavorited(videoId: favorite.videoId) else { return }
        favorites.insert(favorite, at: 0)
        saveFavorites()
    }
    
    func removeFavorite(videoId: String) {
        favorites.removeAll { $0.videoId == videoId }
        saveFavorites()
    }
    
    func toggleFavorite(video: VideoItem, sourceId: String) {
        if isFavorited(videoId: video.vod_id) {
            removeFavorite(videoId: video.vod_id)
        } else {
            let fav = Favorite(
                videoId: video.vod_id,
                videoName: video.vod_name,
                videoPic: video.vod_pic,
                sourceId: sourceId,
                addedDate: Date()
            )
            addFavorite(fav)
        }
    }
    
    func isFavorited(videoId: String) -> Bool {
        favorites.contains { $0.videoId == videoId }
    }
    
    // MARK: - Persistence
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(watchHistory) {
            defaults.set(data, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        guard let data = defaults.data(forKey: historyKey),
              let loaded = try? JSONDecoder().decode([WatchHistory].self, from: data) else { return }
        watchHistory = loaded
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favorites) {
            defaults.set(data, forKey: favoritesKey)
        }
    }
    
    private func loadFavorites() {
        guard let data = defaults.data(forKey: favoritesKey),
              let loaded = try? JSONDecoder().decode([Favorite].self, from: data) else { return }
        favorites = loaded
    }
}
