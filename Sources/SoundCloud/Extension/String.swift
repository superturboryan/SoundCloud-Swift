//
//  String.swift
//  SoundCloud
//
//  Created by Ryan on 2026-02-09.
//

import Foundation

extension String {
    
    var urlEncoded: String? {
        let allowedCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "~-_."))
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    }
}
