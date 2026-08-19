import Foundation

// MARK: - TVBox API Client
class TVBoxAPIClient {
    static let shared = TVBoxAPIClient()
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - 获取分类列表
    func fetchCategories(from source: VideoSource) async throws -> [VideoCategory] {
        let response = try await makeRequest(source: source, params: ["ac": "list", "pg": "1"])
        return response.categories ?? []
    }
    
    // MARK: - 获取分类影片列表
    func fetchVideoList(
        from source: VideoSource,
        categoryID: String? = nil,
        page: Int = 1,
        filters: [String: String] = [:]
    ) async throws -> CategoryResult {
        var params: [String: String] = ["ac": "detail", "pg": "\(page)"]
        if let tid = categoryID {
            params["t"] = tid
        }
        filters.forEach { params[$0.key] = $0.value }
        
        let response = try await makeRequest(source: source, params: params)
        return CategoryResult(
            list: response.list ?? [],
            page: page,
            pagecount: 100,
            limit: 20,
            total: response.list?.count ?? 0,
            filters: nil
        )
    }
    
    // MARK: - 搜索影片
    func search(
        from source: VideoSource,
        keyword: String,
        page: Int = 1
    ) async throws -> [VideoItem] {
        let params: [String: String] = [
            "ac": "detail",
            "wd": keyword,
            "pg": "\(page)"
        ]
        let response = try await makeRequest(source: source, params: params)
        return response.list ?? []
    }
    
    // MARK: - 获取影片详情
    func fetchDetail(from source: VideoSource, videoID: String) async throws -> VideoItem? {
        let params: [String: String] = ["ac": "detail", "ids": videoID]
        let response = try await makeRequest(source: source, params: params)
        return response.list?.first
    }
    
    // MARK: - 解析播放地址（嗅探）
    func resolvePlayURL(_ url: String) async throws -> String {
        // 对于直接的 m3u8/mp4 链接直接返回
        if url.contains(".m3u8") || url.contains(".mp4") || url.contains(".flv") {
            return url
        }
        
        // 尝试嗅探真实地址
        guard let requestURL = URL(string: url) else { return url }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await session.data(for: request)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        // 从 HTML 中提取视频地址
        let patterns = [
            #"https?://[^\s"']+\.m3u8[^\s"']*"#,
            #"https?://[^\s"']+\.mp4[^\s"']*"#,
            #"url\s*[:=]\s*['"]([^'"]+)['"]"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) {
                let matched = String(html[Range(match.range, in: html)!])
                return matched.replacingOccurrences(of: "'", with: "")
                    .replacingOccurrences(of: "\"", with: "")
            }
        }
        
        return url
    }
    
    // MARK: - Private
    private func makeRequest(
        source: VideoSource,
        params: [String: String]
    ) async throws -> TVBoxResponse {
        guard var components = URLComponents(string: source.apiURL) else {
            throw APIError.invalidURL
        }
        
        let queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        if components.queryItems == nil {
            components.queryItems = queryItems
        } else {
            components.queryItems?.append(contentsOf: queryItems)
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }
        
        do {
            return try JSONDecoder().decode(TVBoxResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的接口地址"
        case .serverError: return "服务器错误"
        case .decodingError(let err): return "数据解析失败: \(err.localizedDescription)"
        case .networkError(let err): return "网络错误: \(err.localizedDescription)"
        }
    }
}
