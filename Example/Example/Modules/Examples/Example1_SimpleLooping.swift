//
//  Example1_SimpleLooping.swift
//  DotLottieIosTestApp
//
//  Simple looping animation example
//

import SwiftUI
import DotLottie

struct Example1_SimpleLooping: View {
    @State private var animationLoaded = false
    
    let animation = DotLottieAnimation(
        fileName: "Flow 1",
        config: AnimationConfig(
            autoplay: false,
            loop: false,
            speed: 1.0
        )
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Example 1: Simple Looping")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LottiePlayerView(animation: animation)
                .looping()
                .animationDidLoad { _ in
                    animationLoaded = true
                }
                .frame(height: 200)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            if animationLoaded {
                Text("✓ Animation loaded and looping")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
    }
}

