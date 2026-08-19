import SwiftUI
import AVKit

// MARK: - Player Container View
struct PlayerContainerView: View {
    @ObservedObject var viewModel: DetailViewModel
    @Binding var showPlayer: Bool
    @EnvironmentObject var appState: AppState
    @StateObject private var playerManager = PlayerManager()
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Video Player
            if let urlString = viewModel.playURL, let url = URL(string: urlString) {
                VideoPlayerLayer(playerManager: playerManager, url: url)
                    .ignoresSafeArea()
            }
            
            // Controls Overlay
            if showControls {
                playerControls
                    .transition(.opacity)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls.toggle()
            }
            resetControlsTimer()
        }
        .onAppear {
            if let urlString = viewModel.playURL, let url = URL(string: urlString) {
                playerManager.setupPlayer(url: url)
                playerManager.play()
            }
            resetControlsTimer()
        }
        .onDisappear {
            // 保存播放进度
            playerManager.pause()
            viewModel.updateProgress(
                position: playerManager.currentTime,
                duration: playerManager.duration
            )
            playerManager.cleanup()
        }
        .statusBarHidden(showControls == false)
    }
    
    // MARK: - Player Controls
    private var playerControls: some View {
        VStack {
            // Top Bar
            topBar
            
            Spacer()
            
            // Center Controls
            centerControls
            
            Spacer()
            
            // Bottom Bar
            bottomBar
        }
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .clear, .clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                showPlayer = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(12)
            }
            
            Spacer()
            
            Text(viewModel.video.vod_name)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
            
            Spacer()
            
            // AirPlay
            AirPlayButton()
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Center Controls
    private var centerControls: some View {
        HStack(spacing: 60) {
            // 上一集
            Button {
                Task {
                    if viewModel.selectedEpisodeIndex > 0 {
                        await viewModel.playEpisode(
                            sourceIndex: viewModel.selectedPlaySourceIndex,
                            episodeIndex: viewModel.selectedEpisodeIndex - 1
                        )
                    }
                }
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            .disabled(viewModel.selectedEpisodeIndex <= 0)
            
            // 后退 15s
            Button { playerManager.seekBackward() } label: {
                Image(systemName: "gobackward.15")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            
            // 播放/暂停
            Button { playerManager.togglePlay() } label: {
                Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
            }
            
            // 前进 15s
            Button { playerManager.seekForward() } label: {
                Image(systemName: "goforward.15")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            
            // 下一集
            Button {
                Task {
                    if let source = viewModel.currentPlaySource,
                       viewModel.selectedEpisodeIndex < source.episodes.count - 1 {
                        await viewModel.playEpisode(
                            sourceIndex: viewModel.selectedPlaySourceIndex,
                            episodeIndex: viewModel.selectedEpisodeIndex + 1
                        )
                    }
                }
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            .disabled(viewModel.currentPlaySource == nil ||
                     viewModel.selectedEpisodeIndex >= (viewModel.currentPlaySource?.episodes.count ?? 1) - 1)
        }
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 8) {
            // Progress Bar
            HStack {
                Text(formatTime(playerManager.currentTime))
                    .font(.caption)
                    .foregroundStyle(.white)
                    .monospacedDigit()
                
                Slider(
                    value: Binding(
                        get: { playerManager.currentTime },
                        set: { playerManager.seek(to: $0) }
                    ),
                    in: 0...max(playerManager.duration, 1)
                )
                .tint(.white)
                
                Text(formatTime(playerManager.duration))
                    .font(.caption)
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal)
            
            // Bottom Actions
            HStack(spacing: 20) {
                // 倍速
                Menu {
                    ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0], id: \.self) { speed in
                        Button {
                            playerManager.setSpeed(speed)
                        } label: {
                            HStack {
                                Text("\(speed, specifier: "%.2g")x")
                                if playerManager.playbackSpeed == speed {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                        Text("\(playerManager.playbackSpeed, specifier: "%.2g")x")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                }
                
                Spacer()
                
                // 字幕
                if !playerManager.subtitles.isEmpty {
                    Menu {
                        Button("关闭字幕") { playerManager.selectSubtitle(nil) }
                        ForEach(playerManager.subtitles) { sub in
                            Button(sub.name) { playerManager.selectSubtitle(sub) }
                        }
                    } label: {
                        Image(systemName: playerManager.selectedSubtitle != nil ? "captions.bubble.fill" : "captions.bubble")
                            .foregroundStyle(.white)
                    }
                }
                
                // 音轨
                if !playerManager.audioTracks.isEmpty {
                    Menu {
                        ForEach(playerManager.audioTracks) { track in
                            Button(track.name) { playerManager.selectAudioTrack(track) }
                        }
                    } label: {
                        Image(systemName: "waveform")
                            .foregroundStyle(.white)
                    }
                }
                
                // PiP
                Button {
                    // PiP handled by AVPlayerViewController
                } label: {
                    Image(systemName: "pip")
                        .foregroundStyle(.white)
                }
                
                // 选集
                Menu {
                    if let source = viewModel.currentPlaySource {
                        ForEach(Array(source.episodes.enumerated()), id: \.offset) { idx, ep in
                            Button {
                                Task {
                                    await viewModel.playEpisode(
                                        sourceIndex: viewModel.selectedPlaySourceIndex,
                                        episodeIndex: idx
                                    )
                                }
                            } label: {
                                HStack {
                                    Text(ep.name)
                                    if viewModel.selectedEpisodeIndex == idx {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "00:00" }
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            withAnimation { showControls = false }
        }
    }
}

// MARK: - Video Player Layer (UIKit Bridge)
struct VideoPlayerLayer: UIViewControllerRepresentable {
    let playerManager: PlayerManager
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = playerManager.player
        controller.showsPlaybackControls = false
        controller.allowsPictureInPicturePlayback = true
        controller.videoGravity = .resizeAspect
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = playerManager.player
    }
}

// MARK: - AirPlay Button (UIKit Bridge)
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.activeTintColor = .systemBlue
        picker.prioritizesVideoDevices = true
        return picker
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
