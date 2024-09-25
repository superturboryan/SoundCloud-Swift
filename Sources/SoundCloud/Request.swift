//
//  SoundCloud Request.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-12.
//

import Foundation

extension SoundCloud {
    
    struct Request<T: Decodable> {
        
        private let api: API
        
        private enum API {
            
            case accessToken(
                _ accessCode: String,
                _ clientId: String,
                _ clientSecret: String,
                _ redirectURI: String,
                _ codeVerifier: String
            )
            case refreshAccessToken(
                _ refreshToken: String,
                _ clientId: String,
                _ clientSecret: String,
                _ redirectURI: String
            )
            
            case myUser
            case myLikedTracks(_ limit: Int)
            case myFollowingsRecentlyPosted(_ limit: Int)
            case myLikedPlaylists
            case myPlaylists
            case tracksForPlaylist(_ id: Int, _ limit: Int)
            case tracksForUser(_ id: Int, _ limit: Int)
            case likedTracksForUser(_ id: Int, _ limit: Int)
            case relatedTracks(_ tracksRelatedToId: Int, _ limit: Int)
            case streamInfoForTrack(_ id: Int)
            case usersImFollowing
            
            case likeTrack(_ id: Int)
            case unlikeTrack(_ id: Int)
            case likePlaylist(_ id: Int)
            case unlikePlaylist(_ id: Int)
            case followUser(_ id: Int)
            case unfollowUser(_ id: Int)
            
            case searchTracks(_ query: String, _ limit: Int)
            case searchPlaylists(_ query: String, _ limit: Int)
            case searchUsers(_ query: String, _ limit: Int)

            case nextPage(_ href: String)
        }
        
        static func accessToken(
            _ code: String,
            _ clientId: String,
            _ clientSecret: String,
            _ redirectURI: String,
            _ codeVerifier: String
        ) -> Request<TokenResponse> {
            .init(api: .accessToken(code, clientId, clientSecret, redirectURI, codeVerifier))
        }
        
        static func refreshToken(
            _ refreshToken: String,
            _ clientId: String,
            _ clientSecret: String,
            _ redirectURI: String
        ) -> Request<TokenResponse> {
            .init(api: .refreshAccessToken(refreshToken, clientId, clientSecret, redirectURI))
        }
        
        static func myUser() -> Request<User> {
            .init(api: .myUser)
        }
        
        static func myLikedTracks(_ limit: Int = 100) -> Request<Page<Track>> {
            .init(api: .myLikedTracks(limit))
        }
        
        static func myFollowingsRecentlyPosted(_ limit: Int = 100) -> Request<[Track]> {
            .init(api: .myFollowingsRecentlyPosted(limit))
        }
        
        static func myLikedPlaylists() -> Request<[Playlist]> {
            .init(api: .myLikedPlaylists)
        }
        
        static func myPlaylists() -> Request<[Playlist]> {
            .init(api: .myPlaylists)
        }
        
        static func tracksForPlaylist(_ id: Int, _ limit: Int = 1000) -> Request<Page<Track>> {
            .init(api: .tracksForPlaylist(id, limit))
        }
        
        static func tracksForUser(_ id: Int, _ limit: Int = 20) -> Request<Page<Track>> {
            .init(api: .tracksForUser(id, limit))
        }
        
        static func likedTracksForUser(_ id: Int, _ limit: Int = 20) -> Request<Page<Track>> {
            .init(api: .likedTracksForUser(id, limit))
        }
        
        static func relatedTracks(_ tracksRelatedToId: Int, _ limit: Int = 20) -> Request<Page<Track>> {
            .init(api: .relatedTracks(tracksRelatedToId, limit))
        }

        static func streamInfoForTrack(_ id: Int) -> Request<StreamInfo> {
            .init(api: .streamInfoForTrack(id))
        }
        
        static func usersImFollowing() -> Request<Page<User>> {
            .init(api: .usersImFollowing)
        }
        
        static func likeTrack(_ id: Int) -> Request<Status> {
            .init(api: .likeTrack(id))
        }
        
        static func unlikeTrack(_ id: Int) -> Request<Status> {
            .init(api: .unlikeTrack(id))
        }
        
        static func likePlaylist(_ id: Int) -> Request<Status> {
            .init(api: .likePlaylist(id))
        }
        
        static func unlikePlaylist(_ id: Int) -> Request<Status> {
            .init(api: .unlikePlaylist(id))
        }
        
        static func followUser(_ id: Int) -> Request<User> {
            .init(api: .followUser(id))
        }

        static func unfollowUser(_ id: Int) -> Request<Status> {
            .init(api: .unfollowUser(id))
        }
        
        static func searchTracks(_ query: String, _ limit: Int) -> Request<Page<Track>> {
            .init(api: .searchTracks(query, limit))
        }
        
        static func searchPlaylists(_ query: String, _ limit: Int) -> Request<Page<Playlist>> {
            .init(api: .searchPlaylists(query, limit))
        }
        
        static func searchUsers(_ query: String, _ limit: Int) -> Request<Page<User>> {
            .init(api: .searchUsers(query, limit))
        }

        static func getNextPage<ItemType: Decodable>(_ href: String) -> Request<Page<ItemType>> {
            .init(api: .nextPage(href))
        }
    }
}

extension String {
    var urlEncoded: String? {
        let allowedCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "~-_."))
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    }
}

extension SoundCloud.Request {
    
    var urlRequest: URLRequest {
        let urlWithPath = URL(string: baseURL + path)!
        var components = URLComponents(url: urlWithPath, resolvingAgainstBaseURL: false)!
        components.queryItems = queryParameters?.map { URLQueryItem(name: $0, value: $1) }
        
        var request = URLRequest(url: components.url!)
        
        if isNextPageRequest {
            request = URLRequest(url: URL(string: path)!)
        }
        
        if let body {
            var urlComponents = URLComponents()
            urlComponents.queryItems = body
            request.httpBody = urlComponents.query?.data(using: .utf8)
        }

        request.httpMethod = httpMethod
        return request
    }
    
    var baseURL: String {
        
        switch api {
            
        case .accessToken, .refreshAccessToken:
            SoundCloud.Config.authURL
        default:
            SoundCloud.Config.apiURL
        }
    }
    
    var path: String {
        
        switch api {
            
        case .accessToken: "oauth/token"
        case .refreshAccessToken: "oauth/token"
        
        case .myUser: "me"
        case .myLikedTracks: "me/likes/tracks"
        case .myFollowingsRecentlyPosted: "me/followings/tracks"
        case .myLikedPlaylists: "me/likes/playlists"
        case .myPlaylists: "me/playlists"
        case .tracksForPlaylist(let id, _): "playlists/\(id)/tracks"
        case .tracksForUser(let id, _): "users/\(id)/tracks"
        case .likedTracksForUser(let id, _): "users/\(id)/likes/tracks"
        case .relatedTracks(let id, _): "tracks/\(id)/related"
        case .streamInfoForTrack(let id): "tracks/\(id)/streams"
        case .usersImFollowing: "me/followings"
        case .likeTrack(let id), .unlikeTrack(let id): "likes/tracks/\(id)"
        case .likePlaylist(let id), .unlikePlaylist(let id): "likes/playlists/\(id)"
        case .followUser(let id), .unfollowUser(let id): "me/followings/\(id)"
            
        case .searchTracks: "tracks"
        case .searchPlaylists: "playlists"
        case .searchUsers: "users"
            
        case .nextPage(let href): href
        }
    }
    
    var queryParameters: [String : String]? {
        
        switch api {
                        
        case let .myLikedTracks(limit): [
            "limit" : "\(limit)",
            "access" : "playable",
            "linked_partitioning" : "true"
        ]
        
        case let .myFollowingsRecentlyPosted(limit): [
            "limit" : "\(limit)",
            "access" : "playable",
        ]
            
        case let .tracksForPlaylist(_, limit): [
            "access" : "playable",
            "limit" : "\(limit)",
            "linked_partitioning" : "true"
        ]
            
        case let .tracksForUser(_, limit): [
            "access" : "playable",
            "limit" : "\(limit)",
            "linked_partitioning" : "true"
        ]
            
        case let .likedTracksForUser(_, limit): [
            "access" : "playable",
            "limit" : "\(limit)",
            "linked_partitioning" : "true"
        ]

        case let .relatedTracks(_, limit): [
            "access" : "playable",
            "limit" : "\(limit)",
            "linked_partitioning" : "true"
        ]
            
        case .usersImFollowing: [
            "limit" : "1000", // Page size
            "linked_partitioning" : "true"
        ]
            
        case let .searchTracks(query, limit): [
            "q" : query,
            "access" : "playable",
            "limit" : "\(limit)",
            "linked_partitioning" : "true"
        ]
            
        case let .searchPlaylists(query, limit): [
            "q" : query,
            "show_tracks" : "false",
            "limit" : "\(limit)",
            "linked_partitioning" : "true"
        ]
            
        case let .searchUsers(query, limit): [
            "q" : query,
            "limit" : "\(limit)",
            "linked_partitioning" : "true"
        ]
            
        default: 
            nil
        }
    }
    
    var body: [URLQueryItem]? {
        
        switch api {
        
        case let .accessToken(accessCode, clientId, clientSecret, redirectURI, codeVerifier): [
            URLQueryItem(name:"code", value: accessCode),
            URLQueryItem(name:"grant_type", value: "authorization_code"),
            URLQueryItem(name:"client_id", value: clientId),
            URLQueryItem(name:"client_secret", value: clientSecret),
            URLQueryItem(name:"redirect_uri", value: redirectURI),
            URLQueryItem(name:"code_verifier", value: codeVerifier),
        ]
            
        case let .refreshAccessToken(refreshToken, clientId, clientSecret, redirectURI): [
            URLQueryItem(name:"refresh_token", value: refreshToken),
            URLQueryItem(name:"grant_type", value: "refresh_token"),
            URLQueryItem(name:"client_id", value: clientId),
            URLQueryItem(name:"client_secret", value: clientSecret),
            URLQueryItem(name:"redirect_uri", value: redirectURI),
        ]
        
        default: nil
        }
    }
    
    var httpMethod: String {
        
        switch api {

        case .accessToken,
             .refreshAccessToken,
             .likeTrack,
             .likePlaylist:
            "POST"
        
        case .unlikeTrack,
             .unlikePlaylist,
             .unfollowUser:
            "DELETE"

        case .followUser:
            "PUT"
        
        default: 
            "GET"
        }
    }
}

// MARK: - Helpers 🤝
extension SoundCloud.Request {
    
    var shouldUseAuthHeader: Bool {
        
        switch api {
        case .accessToken, .refreshAccessToken: false
        default: true
        }
    }
        
    var isNextPageRequest: Bool {
        
        switch api {
            case .nextPage: true
            default: false
        }
    }
}
