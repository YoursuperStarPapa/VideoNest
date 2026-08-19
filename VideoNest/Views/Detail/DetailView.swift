import SwiftUI

// MARK: - Detail View
struct DetailView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: DetailViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showPlayer = false
    @State private var showEpisodeSheet = false
    
    let video: VideoItem
    
    init(video: VideoItem) {
        self.video = video
        // ViewModel will be initialized in onAppear with proper dependencies
        _viewModel = StateObject(wrappedValue: DetailViewModel(
            video: video,
            sourceManager: SourceManager(),
            dataStore: .shared
        ))
    }
    
    var body: some View {
        ScrollView {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .navigationTitle(video.vod_name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isFavorited ? .red : .primary)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: video.vod_name)
            }
        }
        .sheet(isPresented: $showPlayer) {
            PlayerContainerView(
                viewModel: viewModel,
                showPlayer: $showPlayer
            )
            .ignoresSafeArea()
        }
        .task {
            viewModel.sourceManager = appState.sourceManager
            await viewModel.loadDetail()
        }
    }
    
    // MARK: - iPhone Layout
    private var iPhoneLayout: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 海报 + 基本信息
            headerSection
            
            // 继续观看 / 播放按钮
            actionButtons
            
            // 剧情简介
            if let content = video.vod_content, !content.isEmpty {
                synopsisSection(content)
            }
            
            // 播放源 & 选集
            playSourceSection
            
            // 相关推荐（占位）
            Spacer(minLength: 100)
        }
    }
    
    // MARK: - iPad Layout
    private var iPadLayout: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                // 左侧海报
                AsyncImage(url: URL(string: video.vod_pic ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .aspectRatio(2/3, contentMode: .fit)
                }
                .frame(width: 250)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 8)
                
                // 右侧信息
                VStack(alignment: .leading, spacing: 12) {
                    Text(video.vod_name)
                        .font(.title.bold())
                    
                    infoRow
                    
                    if let content = video.vod_content {
                        Text(content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(6)
                    }
                    
                    actionButtons
                }
            }
            .padding(.horizontal)
            
            // 播放源
            playSourceSection
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // 海报
            AsyncImage(url: URL(string: video.vod_pic ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .aspectRatio(2/3, contentMode: .fit)
            }
            .frame(width: 130)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 4)
            
            // 信息
            VStack(alignment: .leading, spacing: 8) {
                Text(video.vod_name)
                    .font(.title2.bold())
                
                if let remark = video.vod_remarks {
                    Text(remark)
                        .font(.subheadline)
                        .foregroundStyle(.accentColor)
                }
                
                infoRow
            }
        }
        .padding(.horizontal)
    }
    
    private var infoRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let type = video.type_name {
                Label(type, systemImage: "film")
            }
            if let year = video.vod_year {
                Label(year, systemImage: "calendar")
            }
            if let area = video.vod_area {
                Label(area, systemImage: "globe")
            }
            if let director = video.vod_director, !director.isEmpty {
                Label(director, systemImage: "person")
                    .lineLimit(1)
            }
            if let actor = video.vod_actor, !actor.isEmpty {
                Label(actor, systemImage: "person.2")
                    .lineLimit(1)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // 播放按钮
            Button {
                Task {
                    if viewModel.playSources.count == 1,
                       let firstSource = viewModel.playSources.first,
                       firstSource.episodes.count == 1 {
                        // 单集直接播放
                        await viewModel.playEpisode(sourceIndex: 0, episodeIndex: 0)
                        showPlayer = true
                    } else if let history = viewModel.watchHistory {
                        // 有历史记录，继续播放
                        await viewModel.resumePlay()
                        showPlayer = true
                    } else {
                        // 显示选集
                        showEpisodeSheet = true
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text(viewModel.watchHistory != nil ? "继续播放" : "立即播放")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // 选集按钮
            if !viewModel.playSources.isEmpty {
                Button {
                    showEpisodeSheet = true
                } label: {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("选集")
                    }
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showEpisodeSheet) {
            episodeSheet
        }
    }
    
    // MARK: - Synopsis
    private func synopsisSection(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("剧情简介")
                .font(.headline)
            Text(content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Play Source Section
    private var playSourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 源切换
            if viewModel.playSources.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewModel.playSources.enumerated()), id: \.offset) { idx, source in
                            Button {
                                viewModel.selectedPlaySourceIndex = idx
                            } label: {
                                Text(source.name)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(viewModel.selectedPlaySourceIndex == idx ? Color.accentColor : Color(.systemGray6))
                                    .foregroundStyle(viewModel.selectedPlaySourceIndex == idx ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 选集网格
            if let source = viewModel.currentPlaySource {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 70, maximum: 100))
                ], spacing: 10) {
                    ForEach(Array(source.episodes.enumerated()), id: \.offset) { idx, episode in
                        Button {
                            Task {
                                await viewModel.playEpisode(
                                    sourceIndex: viewModel.selectedPlaySourceIndex,
                                    episodeIndex: idx
                                )
                                showPlayer = true
                            }
                        } label: {
                            Text(episode.name)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.selectedEpisodeIndex == idx
                                    ? Color.accentColor
                                    : Color(.systemGray6)
                                )
                                .foregroundStyle(viewModel.selectedEpisodeIndex == idx ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Episode Sheet
    private var episodeSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // 源选择
                if viewModel.playSources.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(viewModel.playSources.enumerated()), id: \.offset) { idx, source in
                                Button {
                                    viewModel.selectedPlaySourceIndex = idx
                                } label: {
                                    Text(source.name)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(viewModel.selectedPlaySourceIndex == idx ? Color.accentColor : Color(.systemGray6))
                                        .foregroundStyle(viewModel.selectedPlaySourceIndex == idx ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 选集列表
                if let source = viewModel.currentPlaySource {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 70, maximum: 100))
                        ], spacing: 10) {
                            ForEach(Array(source.episodes.enumerated()), id: \.offset) { idx, episode in
                                Button {
                                    Task {
                                        await viewModel.playEpisode(
                                            sourceIndex: viewModel.selectedPlaySourceIndex,
                                            episodeIndex: idx
                                        )
                                        showEpisodeSheet = false
                                        showPlayer = true
                                    }
                                } label: {
                                    Text(episode.name)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            viewModel.selectedEpisodeIndex == idx
                                            ? Color.accentColor
                                            : Color(.systemGray6)
                                        )
                                        .foregroundStyle(viewModel.selectedEpisodeIndex == idx ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("选集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { showEpisodeSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
