import Foundation
import Combine

// MARK: - Source Manager (接口管理)
class SourceManager: ObservableObject {
    @Published var sources: [VideoSource] = []
    @Published var activeSource: VideoSource?
    
    private let defaults = UserDefaults.standard
    private let sourcesKey = "saved_sources"
    private let activeKey = "active_source"
    
    init() {
        loadSources()
    }
    
    func addDefaultSources() {
        let defaults = [
            VideoSource(name: "酷点资源", apiURL: "https://kudian10.com/api.php/provide/vod/", group: "推荐"),
            VideoSource(name: "闪电资源", apiURL: "https://sdzyapi.com/api.php/provide/vod/", group: "推荐"),
            VideoSource(name: "光速资源", apiURL: "https://api.guangsuapi.com/api.php/provide/vod/", group: "推荐"),
            VideoSource(name: "红牛资源", apiURL: "https://www.hongniuzy2.com/api.php/provide/vod/", group: "推荐"),
            VideoSource(name: "无尽资源", apiURL: "https://api.wujinapi.me/api.php/provide/vod/", group: "推荐"),
            VideoSource(name: "量子资源", apiURL: "https://cj.lziapi.com/api.php/provide/vod/", group: "备用"),
            VideoSource(name: "淘片资源", apiURL: "https://taopianapi.com/home/cjapi/as/mc/vd/json/", group: "备用"),
        ]
        sources = defaults
        activeSource = defaults.first
        saveSources()
    }
    
    func addSource(_ source: VideoSource) {
        sources.append(source)
        if activeSource == nil { activeSource = source }
        saveSources()
    }
    
    func removeSource(at offsets: IndexSet) {
        sources.remove(atOffsets: offsets)
        if let active = activeSource, !sources.contains(where: { $0.id == active.id }) {
            activeSource = sources.first
        }
        saveSources()
    }
    
    func removeSource(_ source: VideoSource) {
        sources.removeAll { $0.id == source.id }
        if activeSource?.id == source.id {
            activeSource = sources.first
        }
        saveSources()
    }
    
    func setActive(_ source: VideoSource) {
        activeSource = source
        defaults.set(source.id, forKey: activeKey)
    }
    
    func toggleSource(_ source: VideoSource) {
        if let idx = sources.firstIndex(where: { $0.id == source.id }) {
            sources[idx].isActive.toggle()
            saveSources()
        }
    }
    
    // MARK: - Import from URL (多仓支持)
    func importFromURL(_ urlString: String) async throws -> [VideoSource] {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // 尝试解析为多仓格式
        if let multiRepo = try? JSONDecoder().decode(MultiRepo.self, from: data) {
            return multiRepo.urls.map { item in
                VideoSource(name: item.name, apiURL: item.url, group: item.group ?? "导入")
            }
        }
        
        // 尝试解析为单仓 JSON 数组
        if let sources = try? JSONDecoder().decode([VideoSource].self, from: data) {
            return sources
        }
        
        // 尝试作为纯文本（每行一个URL）
        if let text = String(data: data, encoding: .utf8) {
            return text.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .enumerated()
                .map { idx, line in
                    VideoSource(name: "导入源\(idx + 1)", apiURL: line.trimmingCharacters(in: .whitespaces))
                }
        }
        
        throw APIError.decodingError(NSError(domain: "import", code: -1))
    }
    
    // MARK: - Persistence
    private func saveSources() {
        if let data = try? JSONEncoder().encode(sources) {
            defaults.set(data, forKey: sourcesKey)
        }
    }
    
    private func loadSources() {
        guard let data = defaults.data(forKey: sourcesKey),
              let loaded = try? JSONDecoder().decode([VideoSource].self, from: data) else { return }
        sources = loaded
        if let activeId = defaults.string(forKey: activeKey) {
            activeSource = sources.first { $0.id == activeId }
        }
        activeSource = activeSource ?? sources.first
    }
}

// MARK: - Multi Repo Format (多仓格式)
struct MultiRepo: Codable {
    let urls: [RepoItem]
    
    struct RepoItem: Codable {
        let name: String
        let url: String
        let group: String?
    }
}
