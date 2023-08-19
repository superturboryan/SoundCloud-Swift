//
//  SoundCloudAuthentication.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-10.
//

import Foundation
import AuthenticationServices

@MainActor
public class SC: ObservableObject {
    
    @Published public var me: Me? = nil
    @Published public private(set) var isLoggedIn: Bool = true
    
    private var persistenceService: AuthTokenPersisting
    private var asyncNetworkService: (URLRequest) async throws -> (Data, URLResponse)
    
    private var authTokens: OAuthTokenResponse? {
        get {
            persistenceService.loadAuthTokens()
        }
        set {
            isLoggedIn = newValue != nil
            if let newValue {
                persistenceService.saveAuthTokens(newValue)
                print("✅ 💾 🔑 Tokens saved to persistence \n\(newValue)")
            } else {
                persistenceService.deleteAuthTokens()
            }
        }
    }
    
    private let decoder = JSONDecoder()
    
    private var authHeader: [String : String] {
        ["Authorization" : "Bearer " + (authTokens?.accessToken ?? "")]
    }
    
    /// Use this initializer to optionally inject persistence and networking services to use when interacting with the SoundCloud API.
    ///
    /// If you need to assign the SC instance to a **SwiftUI ObservableObject** variable, you can use a closure to inject
    /// the dependencies and then return the SC instance:
    /// ```swift
    /// @StateObject var sc: SC = { () -> SC in
    ///    let dependency = URLSession.shared.data(for:)
    ///    return SC(asyncNetworkService: dependency)
    /// }() // Don't forget to execute the closure!
    /// ```
    ///  - Parameter asyncNetworkService: Service to use for making requests to the SoundCloud API. **Defaults to URLSession**
    ///  - Parameter persistenceService: Serivce to use for persisting OAuthTokens. **Defaults to UserDefaults**
    public init(
        persistenceService: AuthTokenPersisting = UserDefaultsService(),
        asyncNetworkService: @escaping (URLRequest) async throws -> (Data, URLResponse) = URLSession.shared.data
    ) {
        self.persistenceService = persistenceService
        self.asyncNetworkService = asyncNetworkService
        
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        if authTokens == nil { 
            logout()
        }
    }
}

//MARK: - API
public extension SC {
    func login() async {
        //TODO: Handle try! errors
        do {
            let authCode = try await getAuthCode()
            print("✅ 🔊 ☁️")
            let newAuthTokens = try await getNewAuthTokens(using: authCode)
            authTokens = newAuthTokens
        } catch {
            print("❌ 🔊 ☁️ \(error.localizedDescription)")
        }
    }
    
    func logout() {
        authTokens = nil
    }
    
    func loadMyProfile() async throws {
        me = try await get(.me())
    }
    
    func getMyLikedTracks() async throws -> [Track] {
        try await get(.myLikedTracks())
    }
    
    func getMyFollowingsRecentTracks() async throws -> [Track] {
        try await get(.myFollowingsRecentTracks())
    }
    
    func getMyLikedPlaylists() async throws -> [Playlist] {
        try await get(.myLikedPlaylists())
    }
    
    func getTracksForPlaylists(_ id: Int) async throws -> [Track] {
        try await get(.tracksForPlaylist(id))
    }
}

//MARK: - Authentication
extension SC {
    private func getAuthCode() async throws -> String {
        #if os(iOS)
        try await ASWebAuthenticationSession.getAuthCode(
            from: authorizeURL,
            ephemeralSession: false
        )
        #else
        try await ASWebAuthenticationSession.getAuthCode(
            from: authorizeURL
        )
        #endif
    }
    
    private func getNewAuthTokens(using authCode: String) async throws -> (OAuthTokenResponse) {
        let tokenResponse = try await get(.accessToken(authCode))
        print("✅ Received new tokens:")
        dump(tokenResponse)
        return tokenResponse
    }
    
    private func refreshAuthTokens() async throws {
        let tokenResponse = try await get(.refreshToken(authTokens?.refreshToken ?? ""))
        print("♻️  Refreshed tokens:")
        dump(tokenResponse)
        authTokens = tokenResponse
    }
}

// MARK: - API request
extension SC {
    private func get<T: Decodable>(_ request: Request<T>) async throws -> T {
        // ⚠️ Check that this isn't a request to refresh the token
        if authTokens?.isExpired ?? true && isLoggedIn && !request.isToRefresh {
            try await refreshAuthTokens()
        }
        return try await fetchData(from: authorized(request))
    }
    
    private func fetchData<T: Decodable>(from request: URLRequest) async throws -> T {
        let (data, response) = try await asyncNetworkService(request)
        // TODO: Handle response
        let decodedObject = try decoder.decode(T.self, from: data)
        return decodedObject
    }
    
    private func authorized<T>(_ scRequest: Request<T>) -> URLRequest {
        let urlWithPath = URL(string: apiURL + scRequest.path)!
        var components = URLComponents(url: urlWithPath, resolvingAgainstBaseURL: false)!
        components.queryItems = scRequest.queryParameters?.map { name, value in URLQueryItem(name: name, value: value) }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = scRequest.httpMethod
        // ⚠️ Don't apply authHeader if access token is being requested
        if scRequest.useAuthHeader {
            request.allHTTPHeaderFields = authHeader
        }
        return request
    }
}
