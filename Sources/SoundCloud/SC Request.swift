//
//  SoundCloud Request.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-12.
//

import Foundation

var apiURL = "https://api.soundcloud.com/"

// TODO: 🫨 Inject these in init instead of reading from info.plist here in module!
var clientId: String { Bundle.main.object(forInfoDictionaryKey: "SC_CLIENT_ID") as! String }
var clientSecret: String { Bundle.main.object(forInfoDictionaryKey: "SC_CLIENT_SECRET") as! String }
var redirectURI: String { Bundle.main.object(forInfoDictionaryKey: "SC_REDIRECT_URI") as! String }

let authorizeURL = apiURL
    + "connect"
    + "?client_id=\(clientId)"
    + "&redirect_uri=\(redirectURI)"
    + "&response_type=code"

extension SC {
    
    struct Request<T: Decodable> {
        
        var api: API
        
        enum API {
            case accessToken(_ accessCode: String)
            case refreshAccessToken(_ refreshToken: String)
            case me
            case myLikedTracks
            case myFollowingsRecentlyPosted
            case myLikedPlaylists
            case myPlaylists
            case tracksForPlaylist(_ id: Int)
            case streamInfoForTrack(_ id: Int)
            
            case likeTrack(_ id: Int)
            case unlikeTrack(_ id: Int)
        }
        
        static func accessToken(_ code: String) -> Request<OAuthTokenResponse> {
            Request<OAuthTokenResponse>(api: .accessToken(code))
        }
        
        static func refreshToken(_ refreshToken: String) -> Request<OAuthTokenResponse> {
            Request<OAuthTokenResponse>(api: .refreshAccessToken(refreshToken))
        }
        
        static func me() -> Request<User> {
            Request<User>(api: .me)
        }
        
        static func myLikedTracks() -> Request<[Track]> {
            Request<[Track]>(api: .myLikedTracks)
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
        
        static func tracksForPlaylist(_ id: Int) -> Request<[Track]> {
            Request<[Track]>(api: .tracksForPlaylist(id))
        }
        
        static func streamInfoForTrack(_ id: Int) -> Request<StreamInfo> {
            Request<StreamInfo>(api: .streamInfoForTrack(id))
        }
        
        static func likeTrack(_ id: Int) -> Request<Status> {
            Request<Status>(api: .likeTrack(id))
        }
        
        static func unlikeTrack(_ id: Int) -> Request<Status> {
            Request<Status>(api: .unlikeTrack(id))
        }
    }
}

// MARK: - Request Parameters
extension SC.Request {
    
    var path: String {
        switch api {
        
        case .accessToken: return "oauth2/token"
        case .refreshAccessToken: return "oauth2/token"
        case .me: return "me"
        case .myLikedTracks: return "me/likes/tracks"
        case .myFollowingsRecentlyPosted: return "me/followings/tracks"
        case .myLikedPlaylists: return "me/likes/playlists"
        case .myPlaylists: return "me/playlists"
        case .tracksForPlaylist(let id): return "playlists/\(id)/tracks"
        case .streamInfoForTrack(let id): return "tracks/\(id)/streams"
            
        case .likeTrack(let id), .unlikeTrack(let id): return "likes/tracks/\(id)"
        }
    }
    
    var queryParameters: [String : String]? {
        switch api {

        case .accessToken(let accessCode): return [
            "code" : accessCode,
            "grant_type" : "authorization_code",
            "client_id" : clientId,
            "client_secret" : clientSecret,
            "redirect_uri" : redirectURI
        ]
            
        case .refreshAccessToken(let refreshToken): return [
            "refresh_token" : refreshToken,
            "grant_type" : "refresh_token",
            "client_id" : clientId,
            "client_secret" : clientSecret,
            "redirect_uri" : redirectURI
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
        
        case .unlikeTrack: return "DELETE"
        
        default: return "GET"
        }
    }
}

// MARK: - Helpers
extension SC.Request {
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
}
