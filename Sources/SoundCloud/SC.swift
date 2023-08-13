//
//  SoundCloudAuthentication.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-10.
//

import AuthenticationServices

enum SCError: Error {
    case failedLoadingPersistedTokens
}

@MainActor public class SC: ObservableObject {
    
    private var asyncNetworkService: (URLRequest) async throws -> (Data, URLResponse)
    
    @Published public var me: Me? = nil
    @Published public var isLoggedIn: Bool = true
    
    private var authTokens: OAuthTokenResponse = .empty {
        didSet {
            isLoggedIn = !authTokens.accessToken.isEmpty
            persistAuthTokens(authTokens)
        }
    }
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private var authHeader: [String : String] {
        ["Authorization" : "Bearer " + authTokens.accessToken]
    }
    
    ///  Use this initializer to optionally inject a custom network service for accessing the SoundCloud API.
    ///
    ///  If you need to use this initializer for a **SwiftUI ObservableObject**, you can return a closure that
    ///  injects the dependencies:
    ///  ```swift
    ///  @StateObject var sc: SC = { () -> SC in
    ///     let dependency = URLSession.shared.data(for:)
    ///     return SC(asyncNetworkService: dependency)
    ///  }() // Don't forget to execute the closure!
    ///  ```
    /// - Parameter asyncNetworkService: Service to use for making requests to the SoundCloud API. **Defaults to URLSession**
    public init(asyncNetworkService: @escaping (URLRequest) async throws -> (Data, URLResponse) = URLSession.shared.data) {
        self.asyncNetworkService = asyncNetworkService
        
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do { try loadPersistedAuthTokens() }
        catch { print("❌ 💾 🔑") }
    }
        
    public func login() async {
        //TODO: Handle try! errors
        do {
            let authCode = try await getAuthCode()
            let newAuthTokens = try await getNewAuthTokens(using: authCode)
            authTokens = newAuthTokens
        } catch {
            print("❌ Failed to login")
        }
    }
    
    public func logout() {
        authTokens = .empty
        deletePersistedAuthTokens()
    }
}

//MARK: - API
public extension SC {
    func loadMyProfile() async throws {
        me = try await get(.me())
    }
    
    func getMyLikedTracks() async throws -> [Track] {
        try await get(.myLikedTracks())
    }
}

//MARK: - Authentication
extension SC {
    private func getAuthCode() async throws -> String {
        try await ASWebAuthenticationSession.getAuthCode(
            from: authorizeURL,
            ephemeralSession: false
        )
    }
    
    private func getNewAuthTokens(using authCode: String) async throws -> (OAuthTokenResponse) {
        let tokenResponse = try await get(.accessToken(authCode))
        print("✅ access, refresh tokens: \n \(tokenResponse.accessToken) \n \(tokenResponse.refreshToken)")
        return tokenResponse
    }
    
    private func refreshAuthTokens() async throws {
        let tokenResponse = try await get(.refreshToken(authTokens.refreshToken))
        print("♻️  Refreshed oauth, refresh tokens: \n \(tokenResponse.accessToken) \n \(tokenResponse.refreshToken)")
        authTokens = tokenResponse
    }
    
    private func persistAuthTokens(_ authTokens: OAuthTokenResponse) {
        let authTokensData = try! encoder.encode(authTokens)
        UserDefaults.standard.set(authTokensData, forKey: OAuthTokenResponse.codingKey)
    }
    
    private func loadPersistedAuthTokens() throws {
        guard
            let persistedData = UserDefaults.standard.object(forKey: OAuthTokenResponse.codingKey) as? Data,
            let decodedAuthTokens = try? decoder.decode(OAuthTokenResponse.self, from: persistedData)
        else { throw SCError.failedLoadingPersistedTokens }
        
        authTokens = decodedAuthTokens
    }
    
    private func deletePersistedAuthTokens() {
        UserDefaults.standard.set(nil, forKey: OAuthTokenResponse.codingKey)
    }
}

// MARK: - API request
extension SC {
    private func get<T: Decodable>(_ request: SCRequest<T>) async throws -> T {
        // ⚠️ Check that this isn't a request to refresh the token
        if authTokens.isExpired && isLoggedIn && !request.isToRefresh {
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
    
    private func authorized<T>(_ scRequest: SCRequest<T>) -> URLRequest {
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
