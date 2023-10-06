//
//  SoundCloud Request.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-12.
//
// https://developers.soundcloud.com/docs/api/explorer/open-api#/

import Foundation

extension SoundCloud {
    
    struct Request<T: Decodable> {
        
        var api: API
        
        enum API {
            case accessToken(_ accessCode: String, _ clientId: String, _ clientSecret: String, _ redirectURI: String)
            case refreshAccessToken(_ refreshToken: String, _ clientId: String, _ clientSecret: String, _ redirectURI: String)
            case me
            case myLikedTracks
            case myFollowingsRecentlyPosted
            case myLikedPlaylists
            case myPlaylists
            case tracksForPlaylist(_ id: Int, _ limit: Int)
            case tracksForUser(_ id: Int, _ limit: Int)
            case likedTracksForUser(_ id: Int, _ limit: Int)
            case streamInfoForTrack(_ id: Int)
            case usersImFollowing
            
            case likeTrack(_ id: Int)
            case unlikeTrack(_ id: Int)
            
            case followUser(_ id: Int)
            case unfollowUser(_ id: Int)
            
            case searchTracks(_ query: String)
            case searchPlaylists(_ query: String)
            case searchUsers(_ query: String)

            case nextPage(_ href: String)
        }
        
        static func accessToken(_ code: String, _ clientId: String, _ clientSecret: String, _ redirectURI: String) -> Request<TokenResponse> {
            Request<TokenResponse>(api: .accessToken(code, clientId, clientSecret, redirectURI))
        }
        
        static func refreshToken(_ refreshToken: String, _ clientId: String, _ clientSecret: String, _ redirectURI: String) -> Request<TokenResponse> {
            Request<TokenResponse>(api: .refreshAccessToken(refreshToken, clientId, clientSecret, redirectURI))
        }
        
        static func me() -> Request<User> {
            Request<User>(api: .me)
        }
        
        static func myLikedTracks() -> Request<Page<Track>> {
            Request<Page<Track>>(api: .myLikedTracks)
        }
        
        static func myFollowingsRecentlyPosted() -> Request<[Track]> {
            Request<[Track]>(api: .myFollowingsRecentlyPosted)
        }
        
        static func myLikedPlaylists() -> Request<[Playlist]> {
            Request<[Playlist]>(api: .myLikedPlaylists)
        }
        
        static func myPlaylists() -> Request<[Playlist]> {
            Request<[Playlist]>(api: .myPlaylists)
        }
        
        static func tracksForPlaylist(_ id: Int, _ limit: Int = 20) -> Request<Page<Track>> {
            Request<Page<Track>>(api: .tracksForPlaylist(id, limit))
        }
        
        static func tracksForUser(_ id: Int, _ limit: Int = 20) -> Request<Page<Track>> {
            Request<Page<Track>>(api: .tracksForUser(id, limit))
        }
        
        static func likedTracksForUser(_ id: Int, _ limit: Int = 20) -> Request<Page<Track>> {
            Request<Page<Track>>(api: .likedTracksForUser(id, limit))
        }

        static func streamInfoForTrack(_ id: Int) -> Request<StreamInfo> {
            Request<StreamInfo>(api: .streamInfoForTrack(id))
        }
        
        static func usersImFollowing() -> Request<Page<User>> {
            Request<Page<User>>(api: .usersImFollowing)
        }
        
        static func likeTrack(_ id: Int) -> Request<Status> {
            Request<Status>(api: .likeTrack(id))
        }
        
        static func unlikeTrack(_ id: Int) -> Request<Status> {
            Request<Status>(api: .unlikeTrack(id))
        }
        
        static func followUser(_ id: Int) -> Request<User> {
            Request<User>(api: .followUser(id))
        }

        static func unfollowUser(_ id: Int) -> Request<Status> {
            Request<Status>(api: .unfollowUser(id))
        }
        
        static func searchTracks(_ query: String) -> Request<Page<Track>> {
            Request<Page<Track>>(api: .searchTracks(query))
        }
        
        static func searchPlaylists(_ query: String) -> Request<Page<Playlist>> {
            Request<Page<Playlist>>(api: .searchPlaylists(query))
        }
        
        static func searchUsers(_ query: String) -> Request<Page<User>> {
            Request<Page<User>>(api: .searchUsers(query))
        }

        static func getNextPage<ItemType: Decodable>(_ href: String) -> Request<Page<ItemType>> {
            Request<Page<ItemType>>(api: .nextPage(href))
        }
    }
}

// MARK: - Request Parameters
extension SoundCloud.Request {
    
    var path: String {
        switch api {
        
        case .accessToken: 
            return "oauth2/token"
        case .refreshAccessToken: 
            return "oauth2/token"
        case .me: 
            return "me"
        case .myLikedTracks: 
            return "me/likes/tracks"
        case .myFollowingsRecentlyPosted: 
            return "me/followings/tracks"
        case .myLikedPlaylists:
            return "me/likes/playlists"
        case .myPlaylists:
            return "me/playlists"
        case .tracksForPlaylist(let id, _):
            return "playlists/\(id)/tracks"
        case .tracksForUser(let id, _):
            return "users/\(id)/tracks"
        case .likedTracksForUser(let id, _):
            return "users/\(id)/likes/tracks"
        case .streamInfoForTrack(let id):
            return "tracks/\(id)/streams"
        case .usersImFollowing:
            return "me/followings"

        case .likeTrack(let id), 
             .unlikeTrack(let id):
            return "likes/tracks/\(id)"
            
        case .followUser(let id), 
             .unfollowUser(let id):
            return "me/followings/\(id)"
            
        case .searchTracks:
            return "tracks"
        case .searchPlaylists:
            return "playlists"
        case .searchUsers:
            return "users"
            
        case .nextPage(let href): 
            return href
        }
    }
    
    var queryParameters: [String : String]? {
        switch api {

        case let .accessToken(accessCode, clientId, clientSecret, redirectURI): return [
            "code" : accessCode,
            "grant_type" : "authorization_code",
            "client_id" : clientId,
            "client_secret" : clientSecret,
            "redirect_uri" : redirectURI
        ]
            
        case let .refreshAccessToken(refreshToken, clientId, clientSecret, redirectURI): return [
            "refresh_token" : refreshToken,
            "grant_type" : "refresh_token",
            "client_id" : clientId,
            "client_secret" : clientSecret,
            "redirect_uri" : redirectURI
        ]
            
        case .myLikedTracks: return [
            "limit" : "20",
            "access" : "playable",
            "linked_partitioning" : "true"
        ]
            
        case let .tracksForPlaylist(_, limit): return [
            "access" : "playable",
            "limit" : "\(limit)",
            "linked_partitioning" : "true"
        ]
            
        case let .tracksForUser(_, limit): return [
            "access" : "playable",
            "limit" : "\(limit)",
            "linked_partitioning" : "true"
        ]
            
        case let .likedTracksForUser(_, limit): return [
            "access" : "playable",
            "limit" : "\(limit)",
            "linked_partitioning" : "true"
        ]

        case .usersImFollowing: return [
            "limit" : "1000", // Page size
            "linked_partitioning" : "true"
        ]
            
        case .searchTracks(let query): return [
            "q" : query,
            "access" : "playable",
            "limit" : "20",
            "linked_partitioning" : "true"
        ]
            
        case .searchPlaylists(let query): return [
            "q" : query,
            "show_tracks" : "false",
            "limit" : "20",
            "linked_partitioning" : "true"
        ]
            
        case .searchUsers(let query): return [
            "q" : query,
            "limit" : "20",
            "linked_partitioning" : "true"
        ]
            
        default: return nil
        }
    }
    
    var httpMethod: String {
        switch api {

        case .accessToken,
             .refreshAccessToken,
             .likeTrack:
            return "POST"
        
        case .unlikeTrack,
             .unfollowUser:
            return "DELETE"

        case .followUser:
            return "PUT"
        
        default: return "GET"
        }
    }
}

// MARK: - Helpers
extension SoundCloud.Request {
    var shouldUseAuthHeader: Bool {
        switch api {
        case .accessToken, .refreshAccessToken: return false
        default: return true
        }
    }
    
    var isToRefresh: Bool {
        switch api {
            case .refreshAccessToken: return true
            default: return false
        }
    }
    
    var isForHref: Bool {
        switch api {
            case .nextPage: return true
            default: return false
        }
    }
}
