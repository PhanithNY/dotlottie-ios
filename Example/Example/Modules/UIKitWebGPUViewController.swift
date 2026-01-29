//
//  UIKitWebGPUViewController.swift
//  Example
//
//  UIKit example demonstrating WebGPU/Metal direct rendering
//  Shows low-level integration with MTKView for maximum performance
//

#if canImport(UIKit)
import UIKit
import DotLottie
import MetalKit

class UIKitWebGPUViewController: UIViewController {

    private var mtkView: MTKView!
    private var player: Player!
    private var coordinator: WebGPUCoordinator!

    private var playPauseButton: UIButton!
    private var modeSegmentedControl: UISegmentedControl!
    private var statusLabel: UILabel!
    private var renderTimeLabel: UILabel!

    private var useWebGPU = true
    private var lastRenderTime: Double = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "UIKit WebGPU Example"

        setupMTKView()
        setupPlayer()
        setupControls()
        setupConstraints()
    }

    private func setupMTKView() {
        mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = true
        mtkView.preferredFramesPerSecond = 60
        mtkView.backgroundColor = .systemGray6
        mtkView.layer.cornerRadius = 12
        mtkView.clipsToBounds = true

        view.addSubview(mtkView)
    }

    private func setupPlayer() {
        // Create player with config
        let config = Config(
            autoplay: true,
            loopAnimation: true,
            mode: .forward,
            speed: 1.0
        )

        player = Player(config: config)

        // Load animation from bundle
        if let url = Bundle.main.url(forResource: "Flow 1", withExtension: "json"),
           let jsonData = try? Data(contentsOf: url),
           let jsonString = String(data: jsonData, encoding: .utf8) {

            do {
                try player.loadAnimationData(
                    animationData: jsonString,
                    width: 512,
                    height: 512
                )

                // Enable WebGPU rendering
                if let metalLayer = mtkView.layer as? CAMetalLayer {
                    let metalLayerPtr = Unmanaged.passUnretained(metalLayer).toOpaque()
                    try player.enableWebGPURendering(metalLayer: metalLayerPtr)
                    print("✓ WebGPU rendering enabled")
                }

                // Setup coordinator
                coordinator = WebGPUCoordinator(
                    player: player,
                    mtkView: mtkView,
                    useWebGPU: useWebGPU
                ) { [weak self] renderTime in
                    self?.lastRenderTime = renderTime
                    DispatchQueue.main.async {
                        self?.updateStatusLabels()
                    }
                }

                mtkView.delegate = coordinator

                updateStatusLabels()

            } catch {
                print("Failed to load animation: \(error)")
                statusLabel?.text = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func setupControls() {
        // Play/Pause Button
        playPauseButton = UIButton(type: .system)
        playPauseButton.setTitle("Pause", for: .normal)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false

        // Rendering Mode Segmented Control
        modeSegmentedControl = UISegmentedControl(items: ["WebGPU (GPU)", "Software (CPU)"])
        modeSegmentedControl.selectedSegmentIndex = 0
        modeSegmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        modeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false

        // Status Label
        statusLabel = UILabel()
        statusLabel.text = "Status: Playing"
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = .label
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        // Render Time Label
        renderTimeLabel = UILabel()
        renderTimeLabel.text = "Render time: -- ms"
        renderTimeLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        renderTimeLabel.textColor = .secondaryLabel
        renderTimeLabel.textAlignment = .center
        renderTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        let descriptionLabel = UILabel()
        descriptionLabel.text = """
        WebGPU Mode: Direct GPU rendering
        Software Mode: CPU buffer → GPU copy

        WebGPU provides ~2-3x better performance
        by eliminating the CPU→GPU copy overhead.
        """
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .systemFont(ofSize: 11)
        descriptionLabel.textColor = .tertiaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(playPauseButton)
        view.addSubview(modeSegmentedControl)
        view.addSubview(statusLabel)
        view.addSubview(renderTimeLabel)
        view.addSubview(descriptionLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // MTKView
            mtkView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mtkView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            mtkView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            mtkView.heightAnchor.constraint(equalToConstant: 300),

            // Play/Pause Button
            playPauseButton.topAnchor.constraint(equalTo: mtkView.bottomAnchor, constant: 20),
            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 120),

            // Mode Segmented Control
            modeSegmentedControl.topAnchor.constraint(equalTo: playPauseButton.bottomAnchor, constant: 20),
            modeSegmentedControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            modeSegmentedControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            // Status Label
            statusLabel.topAnchor.constraint(equalTo: modeSegmentedControl.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            // Render Time Label
            renderTimeLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            renderTimeLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            renderTimeLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }

    @objc private func playPauseTapped() {
        guard let player = player else { return }

        if player.isPlaying() {
            player.pause()
            playPauseButton.setTitle("Play", for: .normal)
        } else {
            player.play()
            playPauseButton.setTitle("Pause", for: .normal)
        }

        updateStatusLabels()
    }

    @objc private func modeChanged() {
        useWebGPU = modeSegmentedControl.selectedSegmentIndex == 0

        guard let coordinator = coordinator else { return }

        if useWebGPU {
            // Switch to WebGPU
            if let metalLayer = mtkView.layer as? CAMetalLayer {
                let metalLayerPtr = Unmanaged.passUnretained(metalLayer).toOpaque()
                do {
                    try player.enableWebGPURendering(metalLayer: metalLayerPtr)
                    print("✓ Switched to WebGPU rendering")
                } catch {
                    print("✗ Failed to enable WebGPU: \(error)")
                }
            }
        } else {
            // Switch to software rendering
            player.disableWebGPURendering()

            // Re-allocate software buffer
            do {
                try player.resize(width: 512, height: 512)
                print("✓ Switched to software rendering")
            } catch {
                print("✗ Failed to switch to software rendering: \(error)")
            }
        }

        coordinator.useWebGPU = useWebGPU
        updateStatusLabels()
    }

    private func updateStatusLabels() {
        let mode = useWebGPU ? "WebGPU (Direct GPU)" : "Software (CPU Buffer)"
        let state = player.isPlaying() ? "Playing" : player.isPaused() ? "Paused" : "Stopped"

        statusLabel.text = "Mode: \(mode) | State: \(state)"
        renderTimeLabel.text = String(format: "Render time: %.2f ms", lastRenderTime)
    }

    // MARK: - Coordinator

    class WebGPUCoordinator: NSObject, MTKViewDelegate {
        let player: Player
        let mtkView: MTKView
        var useWebGPU: Bool

        private var metalDevice: MTLDevice!
        private var metalCommandQueue: MTLCommandQueue!
        private var ciContext: CIContext!
        private var onRenderTimeUpdate: (Double) -> Void

        init(player: Player, mtkView: MTKView, useWebGPU: Bool, onRenderTimeUpdate: @escaping (Double) -> Void) {
            self.player = player
            self.mtkView = mtkView
            self.useWebGPU = useWebGPU
            self.onRenderTimeUpdate = onRenderTimeUpdate
            super.init()

            setupMetal()
        }

        private func setupMetal() {
            guard let device = mtkView.device else { return }

            metalDevice = device
            metalCommandQueue = device.makeCommandQueue()
            ciContext = CIContext(mtlDevice: device)
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle size changes if needed
        }

        func draw(in view: MTKView) {
            let frameStart = CACurrentMediaTime()

            guard let drawable = view.currentDrawable,
                  let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
                return
            }

            if useWebGPU {
                // WebGPU mode: tick renders directly to Metal surface
                player.tick()

                // Present the drawable
                commandBuffer.present(drawable)
                commandBuffer.commit()

            } else {
                // Software mode: CGImage → CIImage → Metal pipeline
                if let cgImage = player.tick() {
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
            let renderTime = (frameEnd - frameStart) * 1000.0

            onRenderTimeUpdate(renderTime)
        }
    }
}

#endif
