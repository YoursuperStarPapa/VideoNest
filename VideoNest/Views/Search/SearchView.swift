import SwiftUI

// MARK: - Search View
struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SearchViewModel(sourceManager: SourceManager())
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索框
                searchBar
                
                // 内容
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.results.isEmpty {
                    resultsList
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    suggestionsView
                }
            }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.sourceManager = appState.sourceManager
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("搜索影片、演员、导演...", text: $searchText)
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await viewModel.search(keyword: searchText) }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.clearResults()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            if !searchText.isEmpty {
                Button("取消") {
                    searchText = ""
                    viewModel.clearResults()
                    isSearchFocused = false
                }
                .foregroundStyle(.accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Suggestions
    private var suggestionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 搜索历史
                if !viewModel.searchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("搜索历史")
                                .font(.headline)
                            Spacer()
                            Button("清除") { viewModel.clearHistory() }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.searchHistory, id: \.self) { keyword in
                                Button {
                                    searchText = keyword
                                    Task { await viewModel.search(keyword: keyword) }
                                } label: {
                                    Text(keyword)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray6))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 热门搜索
                VStack(alignment: .leading, spacing: 10) {
                    Text("热门搜索")
                        .font(.headline)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.hotSearches, id: \.self) { keyword in
                            Button {
                                searchText = keyword
                                Task { await viewModel.search(keyword: keyword) }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                    Text(keyword)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }
    
    // MARK: - Results
    private var resultsList: some View {
        List(viewModel.results) { video in
            NavigationLink {
                DetailView(video: video)
            } label: {
                VideoListItem(video: video)
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Loading & Error
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("搜索中...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }
        
        return (CGSize(width: maxX, height: y + rowHeight), frames)
    }
}
