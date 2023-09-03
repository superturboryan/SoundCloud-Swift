//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-09-03.
//

import SwiftUI

extension LinearGradient {
    enum GradientDirection {
        case horizontal
        case vertical
    }
    
    static func scOrangeGradient(_ direction: GradientDirection) -> LinearGradient {
        LinearGradient(gradient: Gradient(stops: [
            .init(color: .scOrange, location: 0),
            .init(color: .orange, location: 1)
        ]),
        startPoint: direction == .vertical ? .top : .leading,
        endPoint: direction == .vertical ? .bottom : .trailing)
    }
}

struct LinearGradient_Previews: PreviewProvider {

    static var previews: some View {
        VStack(spacing: 20) {
            LinearGradient.scOrangeGradient(.vertical)
                .mask(Image(systemName: "playpause.fill")
                    .resizable()
                    .scaledToFit()
                )
            LinearGradient.scOrangeGradient(.horizontal)
                .mask(RoundedRectangle(cornerRadius: 8))
        }
        .padding(10)
    }
}
