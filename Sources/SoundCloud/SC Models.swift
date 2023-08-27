//
//  SoundCloudAPI Models.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-11.
//

import Foundation

public enum UserPlaylistId: Int {
    case likes = 0
    case myFollowingsRecentTracks = 1
}

public struct OAuthTokenResponse: Codable {
    public let accessToken: String
    public let expiresIn: Int
    public let refreshToken: String
    public let scope: String
    public let tokenType: String
    
    internal var expiryDate: Date? = nil // Set when persisting object
}

extension OAuthTokenResponse {
    public var isExpired: Bool {
        expiryDate == nil ? true : expiryDate! < Date()
    }
    public static var empty: Self { OAuthTokenResponse(accessToken: "", expiresIn: 0, refreshToken: "", scope: "", tokenType: "") }
    public static let codingKey = "\(OAuthTokenResponse.self)"
}

public struct Me: Codable {
    public let avatarUrl: String
    public let id: Int
    public let kind: String
    public let permalinkUrl: String
    public let uri: String
    public let username: String
    public let permalink: String
    public let createdAt: String
    public let lastModified: String
    public let firstName: String
    public let lastName: String
    public let fullName: String
    public let city: String?
    public let country: String?
    public let trackCount: Int
    public let publicFavoritesCount: Int
    public let repostsCount: Int
    public let followersCount: Int
    public let followingsCount: Int
    public let commentsCount: Int
    public let online: Bool
    public let likesCount: Int
    public let playlistCount: Int
    public let locale: String
    
    var user: User {
        User(
            avatarUrl: avatarUrl,
            id: id,
            permalinkUrl: permalink,
            uri: uri,
            username: username,
            createdAt: createdAt,
            firstName: firstName,
            lastName: lastName,
            fullName: fullName,
            city: city,
            country: country,
            description: "",
            trackCount: trackCount,
            repostsCount: repostsCount,
            followersCount: followersCount,
            followingsCount: followingsCount,
            commentsCount: commentsCount,
            online: online,
            likesCount: likesCount,
            playlistCount: playlistCount
        )
    }
}

public struct User: Decodable, Equatable {
    public let avatarUrl: String
    public let id: Int
    public let permalinkUrl: String
    public let uri: String
    public let username: String
    public let createdAt: String
    public let firstName: String?
    public let lastName: String?
    public let fullName: String
    public let city: String?
    public let country: String?
    public let description: String?
    public let trackCount: Int
    public let repostsCount: Int
    public let followersCount: Int
    public let followingsCount: Int
    public let commentsCount: Int
    public let online: Bool
    public let likesCount: Int
    public let playlistCount: Int
}

public struct Playlist: Decodable, Identifiable, Equatable {
    public let id: Int
    public let duration: Int
    public let genre: String
    public let permalink: String
    public let permalinkUrl: String
    public let description: String?
    public let uri: String
    public let tagList: String
    public let trackCount: Int
    public let lastModified: String
    public let license: String
    public let user: User
    public let likesCount: Int
    public let sharing: String // "public"
    public let createdAt: String
    public let tags: String
    public let kind: String
    public let title: String
    public let streamable: Bool?
    public let artworkUrl: String?
    public let tracksUri: String
    public var tracks: [Track]?
}

extension Playlist {
    public var durationInSeconds: Int {
        (tracks ?? []).reduce(into: 0, { $0 += $1.durationInSeconds})
    }
    
    public var artworkUrlWithUserFallback: URL {
        URL(string: artworkUrl ?? user.avatarUrl)!
    }
}

public struct Track: Decodable, Identifiable, Equatable {
    public let id: Int
    public let createdAt: String
    public let duration: Int
    public let commentCount: Int?
    public let sharing: String
    public let tagList: String
    public let streamable: Bool
    public let genre: String
    public let title: String
    public let description: String?
    public let license: String
    public let uri: String
    public let user: User
    public let permalinkUrl: String
    public let artworkUrl: String?
    public let streamUrl: String?
    public let downloadUrl: String?
    public let waveformUrl: String
    public let availableCountryCodes: String?
    public let userFavorite: Bool
    public let userPlaybackCount: Int
    public let playbackCount: Int?
    public let favoritingsCount: Int?
    public let repostsCount: Int?
    public let access: String // playable / preview / blocked
}

extension Track {
    public var durationInSeconds: Int { duration / 1000 }
    public var largerArtworkUrl: String? { artworkUrl?.replacingOccurrences(of: "large.jpg", with: "t500x500.jpg") }
}

//MARK: - Test objects
public let testUser = User(
    avatarUrl: "",
    id: 0,
    permalinkUrl: "",
    uri: "",
    username: "Rinse FM",
    createdAt: "",
    firstName: "",
    lastName: "",
    fullName: "",
    city: "",
    country: "",
    description: "",
    trackCount: 0,
    repostsCount: 0,
    followersCount: 0,
    followingsCount: 0,
    commentsCount: 0,
    online: false,
    likesCount: 0,
    playlistCount: 0
)

public let testPlaylist = Playlist(
    id: 1587600994,
    duration: 32367489,
    genre: "",
    permalink: "",
    permalinkUrl: "",
    description: nil,
    uri: "",
    tagList: "",
    trackCount: 7,
    lastModified: "023/08/10 20:27:42 +0000",
    license: "",
    user: testUser,
    likesCount: 20,
    sharing: "",
    createdAt: "2023/03/20 17:08:42 +0000",
    tags: "",
    kind: "",
    title: "RIZ LA TEEF on Rinse FM",
    streamable: true,
    artworkUrl: testTrack.artworkUrl,
    tracksUri: "https://api.soundcloud.com/playlists/1587600994/tracks",
    tracks: Array(repeating: testTrack, count: 10)
)

public let testTrack = Track(
    id: 1586682955,
    createdAt: "2023/08/08 08:24:13 +0000",
    duration: 3678067,
    commentCount: 0,
    sharing: "public",
    tagList: "FrazerRay RinseFM Breakbeat Garage Bass",
    streamable: true,
    genre: "",
    title: "Frazer Ray - 07 August 2023",
    description: "",
    license: "",
    uri: "https://api.soundcloud.com/tracks/1586682955",
    user: testUser,
    permalinkUrl: "",
    artworkUrl: "https://i1.sndcdn.com/artworks-5Ahdjl0532u9N1a2-zoAq3w-large.jpg",
    streamUrl: "https://api.soundcloud.com/tracks/1586682955/stream",
    downloadUrl: "",
    waveformUrl: "https://wave.sndcdn.com/ycxIIzLADTvQ_m.png",
    availableCountryCodes: "",
    userFavorite: false,
    userPlaybackCount: 0,
    playbackCount: 0,
    favoritingsCount: 0,
    repostsCount: 0,
    access: "playable"
)

/*
 API image sizes:
 
 t500x500:     500px×500px
 crop:         400px×400px
 t300x300:     300px×300px
 large:        100px×100px  (default)
 t67x67:       67px×67px    (only on artworks)
 badge:        47px×47px
 small:        32px×32px
 tiny:         20px×20px    (on artworks)
 tiny:         18px×18px    (on avatars)
 mini:         16px×16px
 original:     originally uploaded image
 */
