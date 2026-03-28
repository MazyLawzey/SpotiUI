//
//  SpotifyModels.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//

import Foundation

struct SpotifyTrack: Codable {
    let id: String
    let name: String
    let durationMs: Int
    let uri: String
    let album: SpotifyAlbum
    let artists: [SpotifyArtist]

    enum CodingKeys: String, CodingKey {
        case id, name, uri, album, artists
        case durationMs = "duration_ms"
    }

    var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }
}

struct SpotifyAlbum: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]

    var bestImage: SpotifyImage? { images.first }
}

struct SpotifyArtist: Codable {
    let id: String
    let name: String
}

struct SpotifyImage: Codable {
    let url: String
    let width: Int?
    let height: Int?
}

struct SpotifyPlaybackState: Codable {
    let isPlaying: Bool
    let progressMs: Int?
    let item: SpotifyTrack?
    let shuffleState: Bool
    let repeatState: String // "off" | "track" | "context"

    enum CodingKeys: String, CodingKey {
        case isPlaying    = "is_playing"
        case progressMs   = "progress_ms"
        case item
        case shuffleState = "shuffle_state"
        case repeatState  = "repeat_state"
    }
}

struct SpotifyTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case tokenType    = "token_type"
        case expiresIn    = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}
