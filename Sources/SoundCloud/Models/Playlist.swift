//
//  Playlist.swift
//
//
//  Created by Ryan Forsyth on 2023-10-03.
//

public struct Playlist: Decodable, Identifiable, Equatable {
    public let id: Int
    public let genre: String
    public let permalink: String
    public let permalinkUrl: String
    public let description: String?
    public let uri: String
    public let tagList: String
    public var trackCount: Int
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
    public var nextPageUrl: String?
    public init(
        id: Int,
        genre: String = "",
        permalink: String = "",
        permalinkUrl: String = "https://soundcloud.com",
        description: String? = nil,
        uri: String = "",
        tagList: String = "",
        trackCount: Int = 0,
        lastModified: String = "",
        license: String = "",
        user: User,
        likesCount: Int = 0,
        sharing: String = "",
        createdAt: String = "",
        tags: String = "",
        kind: String = "",
        title: String,
        streamable: Bool? = true,
        artworkUrl: String? = nil,
        tracksUri: String = "",
        tracks: [Track],
        nextPageUrl: String? = nil
    ) {
        self.id = id
        self.genre = genre
        self.permalink = permalink
        self.permalinkUrl = permalinkUrl
        self.description = description
        self.uri = uri
        self.tagList = tagList
        self.trackCount = trackCount
        self.lastModified = lastModified
        self.license = license
        self.user = user
        self.likesCount = likesCount
        self.sharing = sharing
        self.createdAt = createdAt
        self.tags = tags
        self.kind = kind
        self.title = title
        self.streamable = streamable
        self.artworkUrl = artworkUrl
        self.tracksUri = tracksUri
        self.tracks = tracks
        self.nextPageUrl = nextPageUrl
    }
}

extension Playlist {
    var largerArtworkUrl: String? { artworkUrl?.replacingOccurrences(of: "large.jpg", with: "t500x500.jpg") }
    
    public var durationInSeconds: Int {
        (tracks ?? []).reduce(into: 0, { $0 += $1.durationInSeconds})
    }
    
    public var largerArtworkUrlWithTrackAndUserFallback: String {
        largerArtworkUrl ?? tracks?.first?.largerArtworkUrl ?? user.largerAvatarUrl
    }
    
    public var hasNextPage: Bool {
        nextPageUrl != nil
    }
    
    public mutating func updateWith(_ page: Page<Track>) {
        if var tracks, !tracks.isEmpty {
            tracks += page.items
        } else { //
            tracks = page.items
        }
        nextPageUrl = page.nextPageURL
    }
}

public enum PlaylistType: Int, CaseIterable {
    case nowPlaying = 1
    case downloads
    case likes
    case recentlyPosted // By people current user follows
    case relatedTracks
    
    public var title: String {
        switch self {
        case .nowPlaying: String(localized: "Now Playing", bundle: .module, comment: "Noun")
        case .downloads: String(localized:"Downloads", bundle: .module, comment: "Plural noun")
        case .likes:  String(localized:"Likes", bundle: .module, comment: "Plural noun")
        case .recentlyPosted: String(localized:"Recently Posted", bundle: .module, comment: "User playlist - Noun")
        case .relatedTracks: String(localized:"Related Tracks", bundle: .module, comment: "Playlist title - Noun")
        }
    }
}
