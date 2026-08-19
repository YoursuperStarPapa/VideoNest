import SwiftUI

// MARK: - Video Card
struct VideoCard: View {
    let video: VideoItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面图
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: video.vod_pic ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fill)
                    case .failure:
                        placeholderImage
                    case .empty:
                        placeholderImage
                            .overlay(ProgressView())
                    @unknown default:
                        placeholderImage
                    }
                }
                .frame(height: 200)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // 标签
                if let remark = video.vod_remarks, !remark.isEmpty {
                    Text(remark)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(6)
                }
            }
            
            // 标题
            Text(video.vod_name)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .foregroundStyle(.primary)
            
            // 元信息
            HStack(spacing: 4) {
                if let year = video.vod_year, !year.isEmpty {
                    Text(year)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let type = video.type_name, !type.isEmpty {
                    Text(type)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(.systemGray5), Color(.systemGray6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(2/3, contentMode: .fill)
            .overlay {
                Image(systemName: "film")
                    .font(.title)
                    .foregroundStyle(.tertiary)
            }
    }
}

// MARK: - Video List Item (Horizontal)
struct VideoListItem: View {
    let video: VideoItem
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: video.vod_pic ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color(.systemGray5))
            }
            .frame(width: 80, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(video.vod_name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let remark = video.vod_remarks {
                    Text(remark)
                        .font(.caption)
                        .foregroundStyle(.accentColor)
                }
                
                if let director = video.vod_director, !director.isEmpty {
                    Text("导演: \(director)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if let actor = video.vod_actor, !actor.isEmpty {
                    Text("主演: \(actor)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 6) {
                    if let year = video.vod_year {
                        Text(year)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    if let area = video.vod_area {
                        Text(area)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            
            Spacer()
        }
    }
}
