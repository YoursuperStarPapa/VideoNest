import SwiftUI

// MARK: - Favorites View
struct FavoritesView: View {
    @EnvironmentObject var appState: AppState
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationStack {
            Group {
                if appState.dataStore.favorites.isEmpty {
                    emptyView
                } else {
                    favoritesList
                }
            }
            .navigationTitle("我的收藏")
            .navigationBarTitleDisplayMode(.large)
            .environment(\.editMode, $editMode)
            .toolbar {
                if !appState.dataStore.favorites.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                    }
                }
            }
        }
    }
    
    // MARK: - Favorites List
    private var favoritesList: some View {
        List {
            ForEach(appState.dataStore.favorites) { favorite in
                NavigationLink {
                    // 从收藏创建 VideoItem 用于详情页
                    let video = VideoItem(
                        vod_id: favorite.videoId,
                        vod_name: favorite.videoName,
                        vod_pic: favorite.videoPic,
                        vod_remarks: nil,
                        vod_year: nil,
                        vod_area: nil,
                        vod_director: nil,
                        vod_actor: nil,
                        vod_content: nil,
                        type_name: nil,
                        vod_play_from: nil,
                        vod_play_url: nil,
                        vod_class: nil
                    )
                    DetailView(video: video)
                } label: {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: favorite.videoPic ?? "")) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color(.systemGray5))
                        }
                        .frame(width: 60, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(favorite.videoName)
                                .font(.headline)
                                .lineLimit(1)
                            Text("收藏于 \(favorite.addedDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    let fav = appState.dataStore.favorites[index]
                    appState.dataStore.removeFavorite(videoId: fav.videoId)
                }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("还没有收藏")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("浏览影片时点击 ❤️ 添加收藏")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            Group {
                if appState.dataStore.watchHistory.isEmpty {
                    emptyView
                } else {
                    historyList
                }
            }
            .navigationTitle("观看历史")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !appState.dataStore.watchHistory.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("清空") {
                            appState.dataStore.clearHistory()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }
    
    private var historyList: some View {
        List {
            ForEach(appState.dataStore.watchHistory) { history in
                NavigationLink {
                    let video = VideoItem(
                        vod_id: history.videoId,
                        vod_name: history.videoName,
                        vod_pic: history.videoPic,
                        vod_remarks: nil,
                        vod_year: nil,
                        vod_area: nil,
                        vod_director: nil,
                        vod_actor: nil,
                        vod_content: nil,
                        type_name: nil,
                        vod_play_from: nil,
                        vod_play_url: nil,
                        vod_class: nil
                    )
                    DetailView(video: video)
                } label: {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: history.videoPic ?? "")) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color(.systemGray5))
                        }
                        .frame(width: 60, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(history.videoName)
                                .font(.headline)
                                .lineLimit(1)
                            
                            HStack {
                                Text("第 \(history.lastEpisodeIndex + 1) 集")
                                    .font(.caption)
                                    .foregroundStyle(.accentColor)
                                
                                if history.isFinished {
                                    Text("已看完")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                            
                            Text(history.lastPlayTime.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete { offsets in
                appState.dataStore.removeHistory(at: offsets)
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("暂无观看记录")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
