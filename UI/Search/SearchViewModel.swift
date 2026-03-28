//
//  SearchViewModel.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//

import Foundation
import Combine

struct SearchHistoryItem: Identifiable, Codable {
    let id: UUID
    let trackName: String
    let artistName: String
    let trackURI: String
    let albumImageURL: String?
    let addedAt: Date

    init(track: SpotifyTrack) {
        self.id = UUID()
        self.trackName = track.name
        self.artistName = track.artistNames
        self.trackURI = track.uri
        self.albumImageURL = track.album.bestImage?.url
        self.addedAt = Date()
    }
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [SpotifyTrack] = []
    @Published var history: [SearchHistoryItem] = []
    @Published var isLoading: Bool = false
    @Published var offset: Int = 0
    @Published var hasMore: Bool = true

    private var searchTask: Task<Void, Never>?
    private let historyKey = "search_history"
    private let maxHistory = 50

    init() {
        loadHistory()
    }

    // MARK: - Search

    func onQueryChange() {
        searchTask?.cancel()
        if query.isEmpty {
            results = []
            offset = 0
            hasMore = true
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            if !Task.isCancelled { search() }
        }
    }

    func search() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        searchTask?.cancel()
        offset = 0
        hasMore = true
        results = []
        isLoading = true

        searchTask = Task {
            do {
                let tracks = try await SpotifyAPIClient.shared.search(query: query, offset: 0)
                results = tracks
                hasMore = tracks.count == 50
            } catch {
                print("Search error: \(error)")
                results = []
            }
            isLoading = false
        }
    }

    func loadMore() {
        guard hasMore, !isLoading else { return }
        offset += 50

        Task {
            do {
                let more = try await SpotifyAPIClient.shared.search(query: query, offset: offset)
                results.append(contentsOf: more)
                hasMore = more.count == 50
            } catch {
                print("LoadMore error: \(error)")
            }
        }
    }

    // MARK: - Play

    func play(track: SpotifyTrack) {
        addToHistory(track)
        Task {
            try? await SpotifyAPIClient.shared.play(uri: track.uri)
            try? await Task.sleep(nanoseconds: 800_000_000)
            SpotifyPlayer.shared.startPolling()
        }
    }

    // MARK: - History

    private func addToHistory(_ track: SpotifyTrack) {
        history.removeAll { $0.trackURI == track.uri }
        let item = SearchHistoryItem(track: track)
        history.insert(item, at: 0)
        if history.count > maxHistory {
            history = Array(history.prefix(maxHistory))
        }
        saveHistory()
    }

    func removeHistory(_ item: SearchHistoryItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearAllHistory() {
        history = []
        saveHistory()
    }

    // MARK: - Persistence

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([SearchHistoryItem].self, from: data)
        else { return }
        history = items
    }
}
