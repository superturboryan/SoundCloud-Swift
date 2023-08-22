//
//  SoundCloud Request.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-12.
//

import Foundation

var apiURL = "https://api.soundcloud.com/"
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
            case myFollowingsRecentTracks
            case myLikedPlaylists
            case myPlaylists
            case tracksForPlaylist(_ id: Int)
        }
        
        static func accessToken(_ code: String) -> Request<OAuthTokenResponse> {
            Request<OAuthTokenResponse>(api: .accessToken(code))
        }
        
        static func refreshToken(_ refreshToken: String) -> Request<OAuthTokenResponse> {
            Request<OAuthTokenResponse>(api: .refreshAccessToken(refreshToken))
        }
        
        static func me() -> Request<Me> {
            Request<Me>(api: .me)
        }
        
        static func myLikedTracks() -> Request<[Track]> {
            Request<[Track]>(api: .myLikedTracks)
        }
        
        static func myFollowingsRecentTracks() -> Request<[Track]> {
            Request<[Track]>(api: .myFollowingsRecentTracks)
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
    }
}

//MARK: - Request Parameters
extension SC.Request {
    
    var path: String {
        switch api {
        
        case .accessToken: return "oauth2/token"
        case .refreshAccessToken: return "oauth2/token"
        case .me: return "me"
        case .myLikedTracks: return "me/likes/tracks"
        case .myFollowingsRecentTracks: return "me/followings/tracks"
        case .myLikedPlaylists: return "me/likes/playlists"
        case .myPlaylists: return "me/playlists"
        case .tracksForPlaylist(let id): return "playlists/\(id)/tracks"
        }
    }
    
    var queryParameters: [String : String]? { // Remove @MainActor
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

        case .accessToken: fallthrough
        case .refreshAccessToken: return "POST"
        
        default: return "GET"
        }
    }
}

//MARK: - Helpers
extension SC.Request {
    var useAuthHeader: Bool {
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
