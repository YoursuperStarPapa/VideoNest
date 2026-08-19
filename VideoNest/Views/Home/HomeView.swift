import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            HomeContentView()
                .navigationTitle("VideoNest")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Home Content (shared between iPhone & iPad)
struct HomeContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel(sourceManager: SourceManager())
    @State private var hasLoaded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 源切换
            sourceSelector
            
            if viewModel.isLoading && viewModel.videos.isEmpty {
                loadingView
            } else if let error = viewModel.error, viewModel.videos.isEmpty {
                errorView(error)
            } else {
                contentView
            }
        }
        .task {
            if !hasLoaded {
                viewModel.sourceManager = appState.sourceManager
                await viewModel.loadCategories()
                hasLoaded = true
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Source Selector
    private var sourceSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(appState.sourceManager.sources.filter(\.isActive)) { source in
                    Button {
                        appState.sourceManager.setActive(source)
                        Task { await viewModel.loadCategories() }
                    } label: {
                        Text(source.name)
                            .font(.subheadline)
                            .fontWeight(appState.sourceManager.activeSource?.id == source.id ? .bold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                appState.sourceManager.activeSource?.id == source.id
                                ? Color.accentColor
                                : Color(.systemGray5)
                            )
                            .foregroundStyle(appState.sourceManager.activeSource?.id == source.id ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Content
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Banner
                if !viewModel.bannerVideos.isEmpty {
                    bannerView
                }
                
                // 分类标签
                categoryTabs
                
                // 影片列表
                videoGrid
            }
        }
    }
    
    // MARK: - Banner
    private var bannerView: some View {
        TabView {
            ForEach(viewModel.bannerVideos) { video in
                NavigationLink {
                    DetailView(video: video)
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: video.vod_pic ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                        }
                        .frame(height: 220)
                        .clipped()
                        
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(video.vod_name)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            if let remark = video.vod_remarks {
                                Text(remark)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: 220)
        .padding(.horizontal)
    }
    
    // MARK: - Category Tabs
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.categories) { category in
                    Button {
                        viewModel.selectedCategory = category
                        Task { await viewModel.loadVideos(for: category, refresh: true) }
                    } label: {
                        Text(category.type_name)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.selectedCategory?.id == category.id
                                ? Color.accentColor
                                : Color(.systemGray6)
                            )
                            .foregroundStyle(viewModel.selectedCategory?.id == category.id ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Video Grid
    private var videoGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
        ], spacing: 12) {
            ForEach(viewModel.videos) { video in
                NavigationLink {
                    DetailView(video: video)
                } label: {
                    VideoCard(video: video)
                }
                .buttonStyle(.plain)
                .onAppear {
                    if video.id == viewModel.videos.last?.id {
                        if let category = viewModel.selectedCategory {
                            Task { await viewModel.loadMore(for: category) }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Loading & Error
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载中...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("重试") {
                Task { await viewModel.loadCategories() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
