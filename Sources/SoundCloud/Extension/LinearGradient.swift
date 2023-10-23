//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-09-03.
//

import SwiftUI

public extension LinearGradient {
    enum GradientDirection {
        case horizontal
        case vertical
    }
    
    @ViewBuilder
    static func scOrange(
        _ direction: GradientDirection = .vertical,
        reversed: Bool = false
    ) -> LinearGradient {
        let stops = [
            Gradient.Stop.init(color: .scOrangeLight, location: direction == .vertical ? 0 : 1),
            Gradient.Stop.init(color: .scOrangeDark, location: direction == .vertical ? 1 : 0)
        ]
        LinearGradient(
            gradient: Gradient(stops: direction == .vertical ? stops : stops.reversed()),
            startPoint: direction == .vertical ? (reversed ? .bottom : .top) : (reversed ? .trailing: .leading),
            endPoint: direction == .vertical ? (reversed ? .top : .bottom) : (reversed ? .leading : .trailing)
        )
    }
    
    static var empty: LinearGradient {
        LinearGradient(stops: [], startPoint: .top, endPoint: .top)
    }
}

struct LinearGradient_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Image(systemName: "playpause.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(LinearGradient.scOrange(.vertical))

            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(LinearGradient.scOrange(.horizontal))
        }
        .padding(10)
    }
}
