//
//  ASWebAuthenticationSession.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-11.
//

import AuthenticationServices
import Foundation

#if os(watchOS)
public typealias WebAuthContextProvider = Never
#else
public typealias WebAuthContextProvider = ASWebAuthenticationPresentationContextProviding
#endif

public extension ASWebAuthenticationSession {
    /// Async-await wrapper for ASWebAuthenticationSession. Presents a webpage for authenticating using SSO and returns the authorization code after the user successfully signs in
    /// - Parameters:
    ///   - from: Authentication URL to present for SSO
    ///   - with: URI for OAuth web page to use to redirect back to your app. Should take the form "<your app scheme>://<path>"
    ///   - contextProvider: Delegate object specifying how to present the web page (ignored on watchOS)
    ///   - ephemeralSession: If true, no cookies or browsing data are shared with Safari.
    /// - Returns: Authorization code from callback URL
    @MainActor
    static func getAuthorizationCode(
        from url: URL,
        with redirectURI: String,
        contextProvider: WebAuthContextProvider? = nil,
        ephemeralSession: Bool = false
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: String(redirectURI.split(separator: ":").first!)
            ) { url, error in
                if let error {
                    let code = (error as NSError).code
                    if code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        return continuation.resume(throwing: Error.cancelledLogin)
                    }
                    return continuation.resume(throwing: error)
                }
                guard let authorizationCode = url?.queryParameters?["code"] else {
                    return continuation.resume(throwing: Error.noCode)
                }
                continuation.resume(returning: authorizationCode)
            }
            #if !os(watchOS)
            let provider = contextProvider ?? DefaultPresentationContextProvider()
            session.presentationContextProvider = provider
            #endif
            session.prefersEphemeralWebBrowserSession = ephemeralSession
            session.start()
        }
    }

    #if !os(watchOS)
    final class DefaultPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
        public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            #if os(iOS)
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: \.isKeyWindow)
            else {
                fatalError("No key window available for ASWebAuthenticationSession")
            }
            return window
            #elseif os(macOS)
            guard let window = NSApplication.shared.windows.first(where: \.isKeyWindow)
            else {
                fatalError("No key window available for ASWebAuthenticationSession")
            }
            return window
            #endif
        }
    }
    #endif
}

public extension ASWebAuthenticationSession {
    enum Error: LocalizedError {
        case noCode
        case cancelledLogin
        
        public var errorDescription: String? {
            switch self {
            case .noCode: return "Authorization code missing from callback URL."
            case .cancelledLogin: return "The user canceled the login process."
            }
        }
    }
}
