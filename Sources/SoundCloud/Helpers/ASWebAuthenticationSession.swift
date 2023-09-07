//
//  ASWebAuthenticationSession.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-11.
//

import AuthenticationServices
import Foundation

public extension ASWebAuthenticationSession {
    
    #if os(iOS)
    /// Async-await wrapper for ASWebAuthenticationSession. Presents a webpage for authenticating using SSO and returns the authorization code after the user successfully signs in
    /// - Parameters:
    ///   - from: Authentication URL to present for SSO
    ///   - context: Delegate object that specifies how to present web page. Defaults to UIApplication.shared.keyWindow
    ///   - ephemeralSession: 🍪❓
    /// - Returns: Authorization code from callback URL
    @MainActor static func getAuthCode(
        from url: String,
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
                continuation.resume(returning: url!.queryParameters!["code"]!)
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
    #endif
    
    #if os(watchOS)
    @MainActor static func getAuthCode(
        from url: String,
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
                continuation.resume(returning: url!.queryParameters!["code"]!)
            }
            session.prefersEphemeralWebBrowserSession = ephemeralSession
            session.start()
        }
    }
    #endif
}
