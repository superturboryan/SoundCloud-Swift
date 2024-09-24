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
//        var buffer = [UInt8](repeating: 0, count: 32)
//        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
//        return Data(buffer).base64URLEncodedString()
        return "caea98dae163649fb30fb54d0beca1c2bdf9c4d20fafec80bf34461a"
    }
    
    static func generateCodeChallenge(using codeVerifier: String) throws -> String {
//        guard let data = codeVerifier.data(using: .utf8) else {
//            throw Error.generatingCodeChallenge
//        }
//        let dataHash = SHA256.hash(data: data)
//        return Data(dataHash).base64URLEncodedString()
        return "9f8UAB61ANLyvyEG1Fx1_BCe33sQNRESz7tlrmybJns"
    }
}

extension PKCE {
    
    enum Error: Swift.Error {
        case generatingCodeChallenge
    }
}
