//
//  ASWebAuthenticationSession.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-11.
//

import AuthenticationServices
import Foundation

#if os(iOS)
public extension ASWebAuthenticationSession {
    /// Async-await wrapper for ASWebAuthenticationSession. Presents a webpage for authenticating using SSO and returns the authorization code after the user successfully signs in
    /// - Parameters:
    ///   - from: Authentication URL to present for SSO
    ///   - with: URI for OAuth web page to use to redirect back to your app. Should take the form "<your app scheme>://<path>"
    ///   - context: Delegate object that specifies how to present web page. Defaults to UIApplication.shared.keyWindow
    ///   - ephemeralSession: 🍪❓
    /// - Returns: Authorization code from callback URL
    @MainActor static func getAuthCode(
        from url: String,
        with redirectURI: String,
        context: ASWebAuthenticationPresentationContextProviding = ApplicationWindowContextProvider(),
        ephemeralSession: Bool // Use cookies
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: URL(string: url)!,
                callbackURLScheme: String(redirectURI.split(separator: ":").first!)
            ) { url, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let code = url?.queryParameters?["code"] else {
                    continuation.resume(throwing: SoundCloud.Error.loggingIn)
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = context
            session.prefersEphemeralWebBrowserSession = ephemeralSession
            session.start()
        }
    }
    
    final class ApplicationWindowContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
        public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            return UIApplication.shared.keyWindow!
        }
    }
}
#endif
    
#if os(watchOS)
public extension ASWebAuthenticationSession {
    /// Async-await wrapper for ASWebAuthenticationSession. Presents a webpage for authenticating using SSO and returns the authorization code after the user successfully signs in
    /// - Parameters:
    ///   - from: Authentication URL to present for SSO
    ///   - with: URI for OAuth web page to use to redirect back to your app. Should take the form "<your app scheme>://<path>"
    ///   - ephemeralSession: 🍪❓
    /// - Returns: Authorization code from callback URL
    @MainActor static func getAuthCode(
        from url: String,
        with redirectURI: String,
        ephemeralSession: Bool = false
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: URL(string: url)!,
                callbackURLScheme: String(redirectURI.split(separator: ":").first!)
            ) { url, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let code = url?.queryParameters?["code"] else {
                    continuation.resume(throwing: SoundCloud.Error.loggingIn)
                    return
                }
                continuation.resume(returning: code)
            }
            session.prefersEphemeralWebBrowserSession = ephemeralSession
            session.start()
        }
    }
}
#endif
