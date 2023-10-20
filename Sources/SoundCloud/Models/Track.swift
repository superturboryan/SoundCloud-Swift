//
//  Track.swift
//
//
//  Created by Ryan Forsyth on 2023-10-03.
//

import Foundation

public struct Track: Codable, Identifiable {
    public let id: Int
    public let createdAt: String
    public let duration: Int
    public let commentCount: Int?
    public let sharing: String
    public let tagList: String
    public let streamable: Bool?
    public let genre: String?
    public let title: String
    public let description: String?
    public let license: String
    public let uri: String
    public let user: User
    public let permalinkUrl: String
    public let artworkUrl: String?
    public var streamUrl: String?
    public let downloadUrl: String?
    public let waveformUrl: String
    public let availableCountryCodes: [String]?
    public var userFavorite: Bool
    public let userPlaybackCount: Int
    public let playbackCount: Int?
    public let favoritingsCount: Int?
    public let repostsCount: Int?
    public let access: String // playable / preview / blocked
    
    public var localFileUrl: String? = nil // For downloaded tracks
}

public extension Track {
    var playbackUrl: String? { localFileUrl ?? streamUrl }
    var durationInSeconds: Int { duration / 1000 }
    var largerArtworkUrl: String? { artworkUrl?.replacingOccurrences(of: "large.jpg", with: "t500x500.jpg") }
    var fileSizeInMb: Double {
        let fileSizeInKb = durationInSeconds * 16 // Based on 128 bitrate
        return Double(fileSizeInKb) / Double(1024)
    }
    
    func localFileUrl(withExtension extension: String) -> URL {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsUrl.appendingPathComponent("\(id).\(`extension`)")
    }
}

extension Track: Equatable {
    public static func ==(lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
}

extension Track: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

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
