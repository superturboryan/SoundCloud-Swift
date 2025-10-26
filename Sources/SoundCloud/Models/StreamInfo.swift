//
//  StreamInfo.swift
//
//  Created by Ryan Forsyth on 2023-10-03.
//

/// Response from API containing URLs which the authenticated client can use to stream.
///
/// - Important: Some older tracks may not have HLS AAC transcodings available, you may need to fallback to the HLS MP3 URL for streaming. See [deprecation notice on SoundCloud API repo](https://github.com/soundcloud/api/issues/441).
public struct StreamInfo: Decodable {
    @available(*, deprecated, message: "Use AAC transcodings.")
    public let httpMp3128URL: String?
    
    @available(*, deprecated, message: "Use AAC transcodings.")
    public let hlsMp3128URL: String?
    
    /// "Optional, depending on availability"
    public let hlsAAC96URL: String?
    
    public let hlsAAC160URL: String?
}

extension StreamInfo {
    internal enum CodingKeys: String, CodingKey {
        case httpMp3128URL = "httpMp3128Url"
        case hlsMp3128URL = "hlsMp3128Url"
        case hlsAAC96URL = "hlsAac96Url"
        case hlsAAC160URL = "hlsAac160Url"
    }
}
