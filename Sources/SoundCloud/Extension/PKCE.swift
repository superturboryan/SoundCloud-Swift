//
//  PKCE.swift
//  SoundCloud
//
//  Created by Ryan on 2024-09-24.
//

import CryptoKit
import Foundation

enum PKCE {
    
    static func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64URLEncodedString()
    }
    
    static func generateCodeChallenge(using codeVerifier: String) throws -> String {
        guard let data = codeVerifier.data(using: .utf8) else {
            throw Error.generatingCodeChallenge
        }
        let dataHash = SHA256.hash(data: data)
        return Data(dataHash).base64URLEncodedString()
    }
}

extension PKCE {
    
    enum Error: Swift.Error {
        case generatingCodeChallenge
    }
}

private extension Data {
    
  func base64URLEncodedString() -> String {
    base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
      .trimmingCharacters(in: .whitespaces)
  }
}
