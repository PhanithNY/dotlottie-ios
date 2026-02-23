#if canImport(UIKit)
import Foundation
import UIKit
import Metal
import MetalKit
import CoreImage
import AVFoundation
import Combine

public typealias PlatformViewBase = UIView
#elseif canImport(AppKit)
import Foundation
import AppKit
import Metal
import MetalKit
import CoreImage
import AVFoundation
import Combine

public typealias PlatformViewBase = NSView
#endif

#if canImport(UIKit) || canImport(AppKit)

// Platform animation view for UIKit/AppKit
public class DotLottieAnimationView: PlatformViewBase, DotLottie {
    private var mtkView: MTKView!
    private var coordinator: Coordinator!
    private var cancellableBag = Set<AnyCancellable>()
    
    public var dotLottieViewModel: DotLottieAnimation
    
    public init(dotLottieViewModel: DotLottieAnimation) {
        self.dotLottieViewModel = dotLottieViewModel
        
        super.init(frame: .zero)
        
        dotLottieViewModel.$framerate.sink { value in
            if self.mtkView != nil {
                self.mtkView.preferredFramesPerSecond = dotLottieViewModel.framerate
            }
        }.store(in: &cancellableBag)
        
        
        setupMetalView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMetalView() {
        mtkView = MTKView(frame: bounds)
        
        self.coordinator = Coordinator(self, mtkView: mtkView)
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        // Set up Metal-related configurations for your MTKView
        mtkView.device = MTLCreateSystemDefaultDevice()
        
#if canImport(UIKit)
        mtkView.isOpaque = false
#else
        mtkView.layer?.isOpaque = false
        mtkView.layer?.backgroundColor = NSColor.clear.cgColor
#endif
        
        mtkView.framebufferOnly = false
        
        mtkView.delegate = self.coordinator
        
        mtkView.preferredFramesPerSecond = self.dotLottieViewModel.framerate
        
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        mtkView.enableSetNeedsDisplay = true
        
        mtkView.isPaused = false
        
        addSubview(mtkView)
    }
    
#if canImport(UIKit)
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Always fill the bounds
        if mtkView.frame != bounds {
            mtkView.frame = bounds
            mtkView.setNeedsDisplay()
        }
    }
#else
    public override func layout() {
        super.layout()
        
        // Always fill the bounds
        if mtkView.frame != bounds {
            mtkView.frame = bounds
            mtkView.setNeedsDisplay(bounds)
        }
    }
#endif
    
    public func subscribe(observer: Observer) {
        self.dotLottieViewModel.subscribe(observer: observer)
    }
}

#endif
