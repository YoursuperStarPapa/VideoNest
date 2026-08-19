import Foundation

// MARK: - Video Source (影视源)
struct VideoSource: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var apiURL: String
    var isActive: Bool = true
    var group: String = "默认"
    var sortOrder: Int = 0
    var apiType: ApiType = .json
    
    enum ApiType: String, Codable, CaseIterable {
        case json
        case xml
        case spider
    }
}

// MARK: - Video Category
struct VideoCategory: Codable, Identifiable, Hashable {
    var id: String { type_id }
    let type_id: String
    let type_name: String
}

// MARK: - Video Item
struct VideoItem: Codable, Identifiable, Hashable {
    var id: String { vod_id }
    let vod_id: String
    let vod_name: String
    let vod_pic: String?
    let vod_remarks: String?
    let vod_year: String?
    let vod_area: String?
    let vod_director: String?
    let vod_actor: String?
    let vod_content: String?
    let type_name: String?
    let vod_play_from: String?
    let vod_play_url: String?
    let vod_class: String?
    
    var playSources: [PlaySource] {
        guard let from = vod_play_from, let url = vod_play_url else { return [] }
        let separator = "$$$"
        let froms = from.components(separatedBy: separator)
        let urlGroups = url.components(separatedBy: separator)
        
        return zip(froms, urlGroups).map { fromName, group in
            let episodes = group.components(separatedBy: "#").compactMap { ep -> Episode? in
                let parts = ep.components(separatedBy: "$")
                guard parts.count >= 2 else { return nil }
                return Episode(name: parts[0], url: parts[1])
            }
            return PlaySource(name: fromName, episodes: episodes)
        }
    }
}

// MARK: - Play Source
struct PlaySource: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    let name: String
    let episodes: [Episode]
}

// MARK: - Episode
struct Episode: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    let name: String
    let url: String
}

// MARK: - API Response
struct TVBoxResponse: Codable {
    let code: Int?
    let msg: String?
    let categories: [VideoCategory]?
    let list: [VideoItem]?
    let filters: [String: [FilterGroup]]?
    
    enum CodingKeys: String, CodingKey {
        case code, msg, list, filters
        case classes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(Int.self, forKey: .code)
        msg = try container.decodeIfPresent(String.self, forKey: .msg)
        categories = try container.decodeIfPresent([VideoCategory].self, forKey: .classes)
        list = try container.decodeIfPresent([VideoItem].self, forKey: .list)
        filters = try? container.decode([String: [FilterGroup]].self, forKey: .filters)
    }
}

// MARK: - Filter
struct FilterGroup: Codable, Identifiable {
    var id: String { key }
    let key: String
    let name: String
    let value: [FilterValue]
}

struct FilterValue: Codable, Identifiable {
    var id: String { n }
    let n: String
    let v: String
}

// MARK: - Watch History
struct WatchHistory: Codable, Identifiable {
    var id: String { videoId }
    let videoId: String
    let videoName: String
    let videoPic: String?
    let sourceId: String
    var lastEpisodeIndex: Int
    var lastPlayPosition: Double
    var lastPlayTime: Date
    var isFinished: Bool
}

// MARK: - Favorite
struct Favorite: Codable, Identifiable {
    var id: String { videoId }
    let videoId: String
    let videoName: String
    let videoPic: String?
    let sourceId: String
    let addedDate: Date
}
