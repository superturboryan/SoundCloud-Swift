//
//  SwiftUIView.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-24.
//

import SwiftUI

#if os(watchOS) || os(iOS)

public struct WaveformView: View {
    
    @Binding var progress: CGFloat
    @Binding var waveform: UIImage
    
    public init(progress: Binding<CGFloat>, waveform: Binding<UIImage>) {
        _progress = progress
        _waveform = waveform
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                ZStack {
                    Color.secondary.opacity(0.3)
                    Image(uiImage: waveform)
                       .resizable()
                       .renderingMode(.template)
                       .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(height: geo.size.height)
                .frame(height: geo.size.height / 2, alignment: .top)
                .clipped()
                
                ZStack {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .scOrange, location: 0),
                            .init(color: .gray, location: 2.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Image(uiImage: waveform)
                       .resizable()
                       .renderingMode(.template)
                       .blendMode(.destinationOut)
                       
                }
                .compositingGroup()
                .frame(height: geo.size.height)
                .frame(height: geo.size.height / 2, alignment: .top)
                .mask(Rectangle().padding(.trailing, geo.size.width * progress))
                .clipped()
            }
       }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    @State static var progress: CGFloat = 0.5
    @State static var waveform: UIImage = UIImage(named: "test_waveform", in: .module, with: nil)!
    
    static var previews: some View {
        WaveformView(progress: $progress, waveform: $waveform)
//            .frame(height: 30)
    }
}

#endif
