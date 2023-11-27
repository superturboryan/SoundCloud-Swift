//
//  StreamInfo.swift
//  
//
//  Created by Ryan Forsyth on 2023-10-03.
//

public struct StreamInfo: Decodable {
    public let httpMp3128URL: String
    public let hlsMp3128URL: String
}

extension StreamInfo {
    internal enum CodingKeys: String, CodingKey {
        case httpMp3128URL = "httpMp3128Url"
        case hlsMp3128URL = "hlsMp3128Url"
    }
}
