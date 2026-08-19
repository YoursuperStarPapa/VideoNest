import Foundation
import SwiftUI

// MARK: - App Tab
enum AppTab: String, CaseIterable, Identifiable {
    case home, search, favorites, settings
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .home: return "首页"
        case .search: return "搜索"
        case .favorites: return "收藏"
        case .settings: return "设置"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .favorites: return "heart.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var selectedVideo: VideoItem?
    @Published var colorScheme: ColorScheme? = nil
    
    let sourceManager = SourceManager()
    let playerManager = PlayerManager()
    let dataStore = DataStore.shared
    
    init() {
        loadDefaultSources()
    }
    
    private func loadDefaultSources() {
        if sourceManager.sources.isEmpty {
            sourceManager.addDefaultSources()
        }
    }
}
