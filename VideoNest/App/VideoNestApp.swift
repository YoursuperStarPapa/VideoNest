import SwiftUI

@main
struct VideoNestApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    var body: some Scene {
        WindowGroup {
            Group {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    iPadRootView()
                } else {
                    iPhoneRootView()
                }
            }
            .environmentObject(appState)
            .preferredColorScheme(appState.colorScheme)
            .tint(.accentColor)
        }
    }
}

// MARK: - iPhone Root
struct iPhoneRootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(AppTab.home)
            
            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
                .tag(AppTab.search)
            
            FavoritesView()
                .tabItem {
                    Label("收藏", systemImage: "heart.fill")
                }
                .tag(AppTab.favorites)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
    }
}

// MARK: - iPad Root
struct iPadRootView: View {
    @EnvironmentObject var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(AppTab.allCases, selection: $appState.selectedTab) { tab in
                Label(tab.title, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            switch appState.selectedTab {
            case .home:
                HomeContentView()
            case .search:
                SearchView()
            case .favorites:
                FavoritesView()
            case .settings:
                SettingsView()
            }
        } detail: {
            if let video = appState.selectedVideo {
                DetailView(video: video)
            } else {
                ContentUnavailableView(
                    "选择影片",
                    systemImage: "film",
                    description: Text("从左侧列表中选择一部影片查看详情")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
