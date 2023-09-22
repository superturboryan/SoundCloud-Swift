//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-14.
//

import SwiftUI

public extension Image {
    
    static var poweredBySoundCloud: Image {
        Image("powered_by_sc", bundle: .module)
    }
    
    static var connectSC: Image {
        Image("connect_sc", bundle: .module)
    }
    
    static var diconnectSC: Image {
        Image("disconnect_sc", bundle: .module)
    }
    
    static var scLogoVertical: Image {
        Image("sc_logo_vertical", bundle: .module)
    }
    
    internal static var testWaveForm: Image {
        Image("test_waveform", bundle: .module)
    }
}
