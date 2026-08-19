import Foundation
import Combine

// MARK: - Home ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    @Published var categories: [VideoCategory] = []
    @Published var videos: [VideoItem] = []
    @Published var selectedCategory: VideoCategory?
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentPage = 1
    @Published var hasMorePages = true
    @Published var bannerVideos: [VideoItem] = []
    
    private let api = TVBoxAPIClient.shared
    var sourceManager: SourceManager
    
    init(sourceManager: SourceManager) {
        self.sourceManager = sourceManager
    }
    
    var activeSource: VideoSource? {
        sourceManager.activeSource
    }
    
    func loadCategories() async {
        guard let source = activeSource else { return }
        isLoading = true
        error = nil
        
        do {
            categories = try await api.fetchCategories(from: source)
            if let first = categories.first {
                selectedCategory = first
                await loadVideos(for: first)
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadVideos(for category: VideoCategory, refresh: Bool = false) async {
        guard let source = activeSource else { return }
        if refresh { currentPage = 1 }
        isLoading = true
        error = nil
        
        do {
            let result = try await api.fetchVideoList(
                from: source,
                categoryID: category.type_id,
                page: currentPage
            )
            
            if refresh || currentPage == 1 {
                videos = result.list
                bannerVideos = Array(result.list.prefix(5))
            } else {
                videos.append(contentsOf: result.list)
            }
            
            hasMorePages = currentPage < result.pagecount
            currentPage += 1
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMore(for category: VideoCategory) async {
        guard hasMorePages, !isLoading else { return }
        await loadVideos(for: category)
    }
    
    func refresh() async {
        guard let category = selectedCategory else { return }
        await loadVideos(for: category, refresh: true)
    }
}
