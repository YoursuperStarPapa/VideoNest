import Foundation
import Combine

// MARK: - Search ViewModel
@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var results: [VideoItem] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchHistory: [String] = []
    @Published var hotSearches: [String] = ["庆余年", "繁花", "三体", "狂飙", "长相思", "莲花楼", "漫长的季节", "狂飙"]
    
    private let api = TVBoxAPIClient.shared
    var sourceManager: SourceManager
    private var searchTask: Task<Void, Never>?
    private let defaults = UserDefaults.standard
    private let historyKey = "search_history"
    
    init(sourceManager: SourceManager) {
        self.sourceManager = sourceManager
        loadSearchHistory()
    }
    
    func search(keyword: String) async {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 保存搜索历史
        addToHistory(trimmed)
        
        searchTask?.cancel()
        isLoading = true
        error = nil
        
        searchTask = Task {
            guard let source = sourceManager.activeSource else {
                error = "请先配置视频源"
                isLoading = false
                return
            }
            
            do {
                let items = try await api.search(from: source, keyword: trimmed)
                if !Task.isCancelled {
                    results = items
                    if items.isEmpty {
                        error = "未找到相关内容"
                    }
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                }
            }
            
            isLoading = false
        }
        
        await searchTask?.value
    }
    
    func clearResults() {
        results = []
        searchText = ""
    }
    
    func clearHistory() {
        searchHistory = []
        defaults.removeObject(forKey: historyKey)
    }
    
    // MARK: - History
    private func addToHistory(_ keyword: String) {
        searchHistory.removeAll { $0 == keyword }
        searchHistory.insert(keyword, at: 0)
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        saveHistory()
    }
    
    private func loadSearchHistory() {
        searchHistory = defaults.stringArray(forKey: historyKey) ?? []
    }
    
    private func saveHistory() {
        defaults.set(searchHistory, forKey: historyKey)
    }
}
