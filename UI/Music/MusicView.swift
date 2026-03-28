import SwiftUI
import AppKit
import AVKit

struct MusicView: View {
    @StateObject private var player = SpotifyPlayer.shared
    @State private var sliderValue: Double = 0.35
    @State private var isSliding = false
    @State private var showSettings = false

    private func haptic(_ pattern: NSHapticFeedbackManager.FeedbackPattern = .generic) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regular)
                .frame(width: 300, height: 300)
                .shadow(radius: 12)
                .overlay {
                    if let art = player.albumArt {
                        Image(nsImage: art)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 75))
                            .foregroundStyle(.secondary)
                    }
                }
                .draggable("\(player.trackName) - \(player.artistName)", preview: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Material.regular)
                        .frame(width: 300, height: 300)
                        .shadow(radius: 12)
                        .overlay {
                            if let art = player.albumArt {
                                Image(nsImage: art)
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                Image(systemName: "music.note")
                                    .font(.system(size: 75))
                                    .foregroundStyle(.secondary)
                            }
                        }
                })

            Spacer()

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.trackName)
                        .font(.system(size: 18)).fontWeight(.semibold)
                        .foregroundStyle(Color.primary).lineLimit(1)
                    Text(player.artistName)
                        .font(.system(size: 16)).foregroundStyle(Color.secondary).lineLimit(1)
                }
                Spacer()
                AirPlayButton()
                    .frame(width: 40, height: 40)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 4) {
                Slider(value: $sliderValue, in: 0...1) { editing in
                    isSliding = editing
                    if !editing { player.seek(to: sliderValue) }
                }
                .tint(Color.accentColor)
                .onChange(of: player.progress) { newVal in
                    if !isSliding { sliderValue = newVal }
                }
                HStack {
                    Text(player.formattedTime(player.positionMs))
                    Spacer()
                    Text(player.remainingTime)
                }
                .font(.system(size: 12)).foregroundStyle(Color.secondary)
            }
            .padding(.horizontal, 24)

            Spacer()

            HStack {
                Button { haptic(.generic); player.toggleShuffle() } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 16))
                        .foregroundStyle(player.shuffleOn ? Color.primary : Color.secondary)
                }.buttonStyle(.plain)

                Spacer().frame(width: 30)

                Button { haptic(.generic); player.previousTrack() } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 24)).foregroundStyle(Color.primary)
                }.buttonStyle(.plain)

                Spacer().frame(width: 16)

                Button { haptic(.levelChange); player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60)).foregroundStyle(Color.primary)
                }.buttonStyle(.plain)

                Spacer().frame(width: 16)

                Button { haptic(.generic); player.nextTrack() } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24)).foregroundStyle(Color.primary)
                }.buttonStyle(.plain)

                Spacer().frame(width: 30)

                Button { haptic(.generic); player.cycleRepeat() } label: {
                    Image(systemName: player.repeatMode == "track" ? "repeat.1" : "repeat")
                        .font(.system(size: 16))
                        .foregroundStyle(player.repeatMode == "off" ? Color.secondary : Color.primary)
                }.buttonStyle(.plain)
            }

            Spacer().frame(height: 30)

            if !player.isAuthenticated {
                Button("Log in with Spotify") { player.login() }
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { if player.isAuthenticated { player.startPolling() } }
        .onDisappear { player.stopPolling() }
    }
}
