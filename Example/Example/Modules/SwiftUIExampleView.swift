//
//  SwiftUIExampleView.swift
//  DotLottieIosTestApp
//
//  Example of using DotLottiePlayerView (SwiftUI approach similar to LottieView)
//

import SwiftUI
import DotLottie

struct SwiftUIExampleView: View {
    @State private var showInfo = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("SwiftUI DotLottiePlayerView Examples")
                    .font(.headline)
                    .padding(.top)
                
                Example1_SimpleLooping()
                    .onAppear {
                        showInfo = true
                    }
                
                Example2_WithControls()
                
                Example3_ProgressScrubbing()
                
                Example4_AsyncLoading()
                
                Example5_CustomConfiguration()
                
                Example6_MultipleAnimations()

                if showInfo {
                    AnimationInfoView(
                        animation: DotLottieAnimation(
                            fileName: "Flow 1",
                            config: AnimationConfig()
                        )
                    )
                }
                
                Spacer(minLength: 24)
            }
        }
        .navigationTitle("SwiftUI Examples")
    }
}

struct SwiftUIExampleView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIExampleView()
    }
}
