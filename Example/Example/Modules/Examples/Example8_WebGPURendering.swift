//
//  Example8_WebGPURendering.swift
//  Example
//
//  WebGPU/Metal direct rendering example
//  Demonstrates high-performance GPU rendering without CPU-GPU copy overhead
//

import SwiftUI
import DotLottie
import MetalKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct Example8_WebGPURendering: View {
    @State private var animationLoaded = false
    @State private var useWebGPU = true  // Now enabled: Fixed with wgpuSurfacePresent()
    @State private var renderTime: Double = 0
    @State private var actualRenderMode: String = "Unknown"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Example 8: WebGPU Direct Rendering")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("✅ Fixed: Added wgpuSurfacePresent() call")
                .font(.caption)
                .foregroundColor(.green)

            Text("Hardware-accelerated Metal rendering via WebGPU")
                .font(.caption)
                .foregroundColor(.secondary)

            // WebGPU Player View
            WebGPULottieView(
                useWebGPU: $useWebGPU,
                renderTime: $renderTime,
                actualRenderMode: $actualRenderMode
            ) { loaded in
                animationLoaded = loaded
            }
            .frame(height: 300)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            // Status indicators
            VStack(alignment: .leading, spacing: 4) {
                if animationLoaded {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Animation loaded")
                            .font(.caption)
                    }
                }

                HStack {
                    Image(systemName: actualRenderMode == "webgpu" ? "cpu.fill" : "memorychip.fill")
                        .foregroundColor(actualRenderMode == "webgpu" ? .green : .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mode: \(actualRenderMode == "webgpu" ? "WebGPU (GPU)" : "Software (CPU)")")
                            .font(.caption)
                        Text("Actual: \(actualRenderMode)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                if renderTime > 0 {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(.purple)
                        Text(String(format: "Render time: %.2f ms", renderTime))
                            .font(.caption)
                    }
                }
            }
            .padding(.top, 4)

            // Toggle button (disabled for now)
            Toggle("Use WebGPU Rendering", isOn: $useWebGPU)
                .font(.caption)
                .padding(.top, 8)
        }
        .padding(.horizontal)
    }
}

// Custom view that uses MTKView with WebGPU rendering
#if os(iOS) || os(tvOS) || os(visionOS)
struct WebGPULottieView: UIViewRepresentable {
    @Binding var useWebGPU: Bool
    @Binding var renderTime: Double
    @Binding var actualRenderMode: String
    var onLoadStatusChange: (Bool) -> Void

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.delegate = context.coordinator
        view.framebufferOnly = false
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.isPaused = false
        view.enableSetNeedsDisplay = false  // FALSE = continuous rendering
        view.preferredFramesPerSecond = 60
        view.isOpaque = false

        context.coordinator.mtkView = view

        // Setup player AFTER view is created
        context.coordinator.setupPlayer()

        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Switch rendering mode when toggle changes
        if context.coordinator.useWebGPU != useWebGPU {
            context.coordinator.useWebGPU = useWebGPU
            context.coordinator.switchRenderingMode(view: uiView)
        }
    }

    func makeCoordinator() -> WebGPUCoordinator {
        WebGPUCoordinator(
            useWebGPU: useWebGPU,
            renderTime: $renderTime,
            actualRenderMode: $actualRenderMode,
            onLoadStatusChange: onLoadStatusChange
        )
    }

    // MARK: - Coordinator

    class WebGPUCoordinator: NSObject, MTKViewDelegate {
        var player: Player?
        var useWebGPU: Bool
        var mtkView: MTKView?

        private var metalDevice: MTLDevice!
        private var metalCommandQueue: MTLCommandQueue!
        private var ciContext: CIContext!
        private var renderTimeBinding: Binding<Double>
        private var actualRenderModeBinding: Binding<String>
        private var onLoadStatusChange: (Bool) -> Void
        private var frameCount = 0

        init(useWebGPU: Bool, renderTime: Binding<Double>, actualRenderMode: Binding<String>, onLoadStatusChange: @escaping (Bool) -> Void) {
            self.useWebGPU = useWebGPU
            self.renderTimeBinding = renderTime
            self.actualRenderModeBinding = actualRenderMode
            self.onLoadStatusChange = onLoadStatusChange
            super.init()

            setupMetal()
            // Don't call setupPlayer() here - wait until mtkView is set
        }

        private func setupMetal() {
            guard let device = MTLCreateSystemDefaultDevice() else {
                print("Failed to create Metal device")
                return
            }

            metalDevice = device
            metalCommandQueue = device.makeCommandQueue()
            ciContext = CIContext(mtlDevice: device)
        }

        func setupPlayer() {
            // Only setup once
            guard player == nil else { return }

            // Create player with animation config
            let config = Config(
                autoplay: true,
                loopAnimation: true,
                mode: .forward,
                speed: 1.0
            )

            player = Player(config: config)

            // Enable WebGPU BEFORE loading (if requested)
            if useWebGPU {
                enableWebGPU()
            }

            // Load animation from bundle AFTER setting WebGPU target
            if let url = Bundle.main.url(forResource: "Flow 1", withExtension: "json"),
               let jsonData = try? Data(contentsOf: url),
               let jsonString = String(data: jsonData, encoding: .utf8) {

                do {
                    try player?.loadAnimationData(
                        animationData: jsonString,
                        width: 512,
                        height: 512
                    )

                    // Start playing the animation
                    player?.play()

                    print("✅ Animation loaded and playing")
                    onLoadStatusChange(true)

                } catch {
                    print("❌ Failed to load animation: \(error)")
                    onLoadStatusChange(false)
                }
            }
        }

        private func enableWebGPU() {
            guard let view = mtkView,
                  let metalLayer = view.layer as? CAMetalLayer,
                  let player = player else {
                print("❌ enableWebGPU failed: view=\(mtkView != nil), layer=\(mtkView?.layer != nil), player=\(player != nil)")
                return
            }

            let metalLayerPtr = Unmanaged.passUnretained(metalLayer).toOpaque()

            do {
                let success = try player.enableWebGPURendering(metalLayer: metalLayerPtr)
                if success {
                    print("✅ WebGPU rendering enabled successfully")
                } else {
                    print("❌ WebGPU rendering failed to enable (returned false)")
                }
            } catch {
                print("❌ Failed to enable WebGPU with error: \(error)")
            }
        }

        func switchRenderingMode(view: MTKView) {
            guard let player = player else { return }

            if useWebGPU {
                // Switch to WebGPU
                enableWebGPU()
                print("Switched to WebGPU rendering")
            } else {
                // Switch to software rendering
                player.disableWebGPURendering()

                // Re-allocate software buffer
                do {
                    // Trigger buffer reallocation by calling resize with current dimensions
                    try player.resize(width: 512, height: 512)
                    print("Switched to software rendering")
                } catch {
                    print("Failed to switch to software rendering: \(error)")
                }
            }
        }

        // MARK: - MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle size changes if needed
        }

        func draw(in view: MTKView) {
            let frameStart = CACurrentMediaTime()

            guard let drawable = view.currentDrawable,
                  let player = player else {
                return
            }

            guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
                return
            }

            if useWebGPU {
                // WebGPU mode: tick renders directly to Metal surface
                player.tick()

                // CRITICAL: Present WebGPU surface to display the rendered frame
                // Without this, rendering happens off-screen but never appears
                player.presentWebGPU()

                // Debug: Log every 60 frames and update UI
                frameCount += 1
                if frameCount % 60 == 0 {
                    let mode = "\(player.renderMode)"
                    print("✅ WebGPU Mode - Frame \(frameCount) - Render Mode: \(mode)")
                    DispatchQueue.main.async { [weak self] in
                        self?.actualRenderModeBinding.wrappedValue = mode
                    }
                }

                // Also present the Metal drawable
                commandBuffer.present(drawable)
                commandBuffer.commit()

            } else {
                // Software mode: traditional CGImage → CIImage → Metal pipeline
                if let cgImage = player.tick() {
                    // Debug: Log every 60 frames and update UI
                    frameCount += 1
                    if frameCount % 60 == 0 {
                        let mode = "\(player.renderMode)"
                        print("🔧 Software Mode - Frame \(frameCount) - Render Mode: \(mode) - CGImage: \(cgImage.width)x\(cgImage.height)")
                        DispatchQueue.main.async { [weak self] in
                            self?.actualRenderModeBinding.wrappedValue = mode
                        }
                    }
                    let inputImage = CIImage(cgImage: cgImage)

                    // Scale to view size
                    var bounds = view.bounds
                    bounds.size = view.drawableSize

                    let scaleX = bounds.size.width / inputImage.extent.size.width
                    let scaleY = bounds.size.height / inputImage.extent.size.height
                    let filteredImage = inputImage.transformed(by: CGAffineTransform(
                        scaleX: scaleX,
                        y: scaleY
                    ))

                    // Render to texture
                    ciContext.render(
                        filteredImage,
                        to: drawable.texture,
                        commandBuffer: commandBuffer,
                        bounds: CGRect(origin: .zero, size: view.drawableSize),
                        colorSpace: CGColorSpaceCreateDeviceRGB()
                    )

                    commandBuffer.present(drawable)
                    commandBuffer.commit()
                }
            }

            // Calculate render time
            let frameEnd = CACurrentMediaTime()
            let renderTime = (frameEnd - frameStart) * 1000.0  // Convert to milliseconds

            DispatchQueue.main.async { [weak self] in
                self?.renderTimeBinding.wrappedValue = renderTime
            }
        }

        deinit {
            player?.disableWebGPURendering()
        }
    }
}
#elseif os(macOS)
struct WebGPULottieView: NSViewRepresentable {
    @Binding var useWebGPU: Bool
    @Binding var renderTime: Double
    @Binding var actualRenderMode: String
    var onLoadStatusChange: (Bool) -> Void

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.delegate = context.coordinator
        view.framebufferOnly = false
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.isPaused = false
        view.enableSetNeedsDisplay = false  // FALSE = continuous rendering
        view.preferredFramesPerSecond = 60
        view.layer?.isOpaque = false

        context.coordinator.mtkView = view

        // Setup player AFTER view is created
        context.coordinator.setupPlayer()

        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        // Switch rendering mode when toggle changes
        if context.coordinator.useWebGPU != useWebGPU {
            context.coordinator.useWebGPU = useWebGPU
            context.coordinator.switchRenderingMode(view: nsView)
        }
    }

    func makeCoordinator() -> WebGPUCoordinator {
        WebGPUCoordinator(
            useWebGPU: useWebGPU,
            renderTime: $renderTime,
            actualRenderMode: $actualRenderMode,
            onLoadStatusChange: onLoadStatusChange
        )
    }

    // MARK: - Coordinator (same as iOS)

    class WebGPUCoordinator: NSObject, MTKViewDelegate {
        var player: Player?
        var useWebGPU: Bool
        var mtkView: MTKView?

        private var metalDevice: MTLDevice!
        private var metalCommandQueue: MTLCommandQueue!
        private var ciContext: CIContext!
        private var renderTimeBinding: Binding<Double>
        private var actualRenderModeBinding: Binding<String>
        private var onLoadStatusChange: (Bool) -> Void
        private var frameCount = 0

        init(useWebGPU: Bool, renderTime: Binding<Double>, actualRenderMode: Binding<String>, onLoadStatusChange: @escaping (Bool) -> Void) {
            self.useWebGPU = useWebGPU
            self.renderTimeBinding = renderTime
            self.actualRenderModeBinding = actualRenderMode
            self.onLoadStatusChange = onLoadStatusChange
            super.init()

            setupMetal()
            // Don't call setupPlayer() here - wait until mtkView is set
        }

        private func setupMetal() {
            guard let device = MTLCreateSystemDefaultDevice() else {
                print("Failed to create Metal device")
                return
            }

            metalDevice = device
            metalCommandQueue = device.makeCommandQueue()
            ciContext = CIContext(mtlDevice: device)
        }

        func setupPlayer() {
            // Only setup once
            guard player == nil else { return }

            let config = Config(
                autoplay: true,
                loopAnimation: true,
                mode: .forward,
                speed: 1.0
            )

            player = Player(config: config)

            // Enable WebGPU BEFORE loading (if requested)
            if useWebGPU {
                enableWebGPU()
            }

            // Load animation from bundle AFTER setting WebGPU target
            if let url = Bundle.main.url(forResource: "Flow 1", withExtension: "json"),
               let jsonData = try? Data(contentsOf: url),
               let jsonString = String(data: jsonData, encoding: .utf8) {

                do {
                    try player?.loadAnimationData(
                        animationData: jsonString,
                        width: 512,
                        height: 512
                    )

                    // Start playing the animation
                    player?.play()

                    print("✅ Animation loaded and playing")
                    onLoadStatusChange(true)

                } catch {
                    print("❌ Failed to load animation: \(error)")
                    onLoadStatusChange(false)
                }
            }
        }

        private func enableWebGPU() {
            guard let view = mtkView,
                  let metalLayer = view.layer as? CAMetalLayer,
                  let player = player else {
                print("❌ enableWebGPU failed: view=\(mtkView != nil), layer=\(mtkView?.layer != nil), player=\(player != nil)")
                return
            }

            let metalLayerPtr = Unmanaged.passUnretained(metalLayer).toOpaque()

            do {
                let success = try player.enableWebGPURendering(metalLayer: metalLayerPtr)
                if success {
                    print("✅ WebGPU rendering enabled successfully")
                } else {
                    print("❌ WebGPU rendering failed to enable (returned false)")
                }
            } catch {
                print("❌ Failed to enable WebGPU with error: \(error)")
            }
        }

        func switchRenderingMode(view: MTKView) {
            guard let player = player else { return }

            if useWebGPU {
                enableWebGPU()
                print("Switched to WebGPU rendering")
            } else {
                player.disableWebGPURendering()

                do {
                    try player.resize(width: 512, height: 512)
                    print("Switched to software rendering")
                } catch {
                    print("Failed to switch to software rendering: \(error)")
                }
            }
        }

        // MARK: - MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle size changes if needed
        }

        func draw(in view: MTKView) {
            let frameStart = CACurrentMediaTime()

            guard let drawable = view.currentDrawable,
                  let player = player else {
                return
            }

            guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
                return
            }

            if useWebGPU {
                player.tick()

                // CRITICAL: Present WebGPU surface to display the rendered frame
                player.presentWebGPU()

                // Debug: Log every 60 frames and update UI
                frameCount += 1
                if frameCount % 60 == 0 {
                    let mode = "\(player.renderMode)"
                    print("✅ WebGPU Mode - Frame \(frameCount) - Render Mode: \(mode)")
                    DispatchQueue.main.async { [weak self] in
                        self?.actualRenderModeBinding.wrappedValue = mode
                    }
                }

                commandBuffer.present(drawable)
                commandBuffer.commit()

            } else {
                if let cgImage = player.tick() {
                    // Debug: Log every 60 frames and update UI
                    frameCount += 1
                    if frameCount % 60 == 0 {
                        let mode = "\(player.renderMode)"
                        print("🔧 Software Mode - Frame \(frameCount) - Render Mode: \(mode) - CGImage: \(cgImage.width)x\(cgImage.height)")
                        DispatchQueue.main.async { [weak self] in
                            self?.actualRenderModeBinding.wrappedValue = mode
                        }
                    }

                    let inputImage = CIImage(cgImage: cgImage)

                    var bounds = view.bounds
                    bounds.size = view.drawableSize

                    let scaleX = bounds.size.width / inputImage.extent.size.width
                    let scaleY = bounds.size.height / inputImage.extent.size.height
                    let filteredImage = inputImage.transformed(by: CGAffineTransform(
                        scaleX: scaleX,
                        y: scaleY
                    ))

                    ciContext.render(
                        filteredImage,
                        to: drawable.texture,
                        commandBuffer: commandBuffer,
                        bounds: CGRect(origin: .zero, size: view.drawableSize),
                        colorSpace: CGColorSpaceCreateDeviceRGB()
                    )

                    commandBuffer.present(drawable)
                    commandBuffer.commit()
                }
            }

            let frameEnd = CACurrentMediaTime()
            let renderTime = (frameEnd - frameStart) * 1000.0

            DispatchQueue.main.async { [weak self] in
                self?.renderTimeBinding.wrappedValue = renderTime
            }
        }

        deinit {
            player?.disableWebGPURendering()
        }
    }
}
#endif

#Preview {
    Example8_WebGPURendering()
}
