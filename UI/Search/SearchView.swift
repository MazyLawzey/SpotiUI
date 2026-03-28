//
//  SearchView.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.secondary)

                TextField("Artists, tracks...", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Color.primary)
                    .focused($isFocused)
                    .onSubmit { viewModel.search() }
                    .onChange(of: viewModel.query) { _ in viewModel.onQueryChange() }

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                        viewModel.results = []
                    } label: {
                            Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.top, 16)

            
            if viewModel.isLoading {
                Spacer()
                ProgressView().padding()
                Spacer()
            } else if !viewModel.results.isEmpty {
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.results, id: \.id) { track in
                            TrackRow(track: track) {
                                viewModel.play(track: track)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            } else if viewModel.query.isEmpty && !viewModel.history.isEmpty {
                // История
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Recently played")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Button("Clear all") {
                            viewModel.clearAllHistory()
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.history) { item in
                                HistoryRow(item: item) {
                                    viewModel.query = item.trackName
                                    viewModel.search()
                                } onDelete: {
                                    viewModel.removeHistory(item)
                                }
                            }
                        }
                    }
                }
            } else if viewModel.query.isEmpty {
                Spacer()
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .padding(.bottom, 12)
                Text("Find something")
                    .foregroundStyle(Color.secondary)
                Spacer()
            } else {
                Spacer()
                Text("Nothing found")
                    .foregroundStyle(Color.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - TrackRow

struct TrackRow: View {
    let track: SpotifyTrack
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: track.album.bestImage?.url ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.08))
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundStyle(Color.secondary)
                        }
                }
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 3) {
                    Text(track.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                    Text(track.artistNames)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(formatMs(track.durationMs))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.001))
    }

    private func formatMs(_ ms: Int) -> String {
        let s = ms / 1000
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - HistoryRow

struct HistoryRow: View {
    let item: SearchHistoryItem
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    if let urlString = item.albumImageURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primary.opacity(0.08))
                                .overlay {
                                    Image(systemName: "clock")
                                    .foregroundStyle(Color.secondary)
                                }
                        }
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 46, height: 46)
                            .overlay {
                                Image(systemName: "clock")
                                    .foregroundStyle(Color.secondary)
                            }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.trackName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                        Text(item.artistName)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
