//
//  DotLottiePlayerBridge.swift
//  DotLottie
//
//  Swift bridge for C API (dotlottie_player.h)
//

import Foundation
import DotLottiePlayer

// MARK: - Mode

public enum Mode: UInt32 {
    case forward = 0
    case reverse = 1
    case bounce = 2
    case reverseBounce = 3

    internal var cMode: dotlottieMode {
        switch self {
        case .forward: return Forward
        case .reverse: return Reverse
        case .bounce: return Bounce
        case .reverseBounce: return ReverseBounce
        }
    }

    internal init(cMode: dotlottieMode) {
        switch cMode {
        case Forward: self = .forward
        case Reverse: self = .reverse
        case Bounce: self = .bounce
        case ReverseBounce: self = .reverseBounce
        default: self = .forward
        }
    }
}

// MARK: - Fit

public enum Fit: UInt32 {
    case contain = 0
    case fill = 1
    case cover = 2
    case fitWidth = 3
    case fitHeight = 4
    case none = 5

    internal var cFit: dotlottieDotLottieFit {
        switch self {
        case .contain: return Contain
        case .fill: return Fill
        case .cover: return Cover
        case .fitWidth: return FitWidth
        case .fitHeight: return FitHeight
        case .none: return Void
        }
    }

    internal init(cFit: dotlottieDotLottieFit) {
        switch cFit {
        case Contain: self = .contain
        case Fill: self = .fill
        case Cover: self = .cover
        case FitWidth: self = .fitWidth
        case FitHeight: self = .fitHeight
        case Void: self = .none
        default: self = .contain
        }
    }
}

// MARK: - ColorSpace

public enum ColorSpace: UInt32 {
    case abgr8888 = 0    // Alpha-Blue-Green-Red
    case abgr8888s = 1   // ABGR with sRGB
    case argb8888 = 2    // Alpha-Red-Green-Blue
    case argb8888s = 3   // ARGB with sRGB

    internal var cColorSpace: dotlottieColorSpace {
        switch self {
        case .abgr8888: return ABGR8888
        case .abgr8888s: return ABGR8888S
        case .argb8888: return ARGB8888
        case .argb8888s: return ARGB8888S
        }
    }

    internal init(cColorSpace: dotlottieColorSpace) {
        switch cColorSpace {
        case ABGR8888: self = .abgr8888
        case ABGR8888S: self = .abgr8888s
        case ARGB8888: self = .argb8888
        case ARGB8888S: self = .argb8888s
        default: self = .argb8888
        }
    }
}

// MARK: - Layout

public struct Layout {
    public var fit: Fit
    public var alignX: Float
    public var alignY: Float

    public init(fit: Fit = .contain, alignX: Float = 0.5, alignY: Float = 0.5) {
        self.fit = fit
        self.alignX = alignX
        self.alignY = alignY
    }

    internal var cLayout: dotlottieDotLottieLayout {
        return dotlottieDotLottieLayout(
            fit: fit.cFit,
            align_x: alignX,
            align_y: alignY
        )
    }

    internal init(cLayout: dotlottieDotLottieLayout) {
        self.fit = Fit(cFit: cLayout.fit)
        self.alignX = cLayout.align_x
        self.alignY = cLayout.align_y
    }
}

// MARK: - Config

public struct Config {
    public var mode: Mode
    public var loopAnimation: Bool
    public var loopCount: UInt32
    public var speed: Float
    public var useFrameInterpolation: Bool
    public var autoplay: Bool
    public var segment: [Float]
    public var backgroundColor: UInt32
    public var layout: Layout
    public var marker: String
    public var themeId: String
    public var stateMachineId: String
    public var animationId: String

    public init(
        autoplay: Bool = false,
        loopAnimation: Bool = false,
        loopCount: UInt32 = 0,
        mode: Mode = .forward,
        speed: Float = 1.0,
        useFrameInterpolation: Bool = false,
        segment: [Float] = [],
        backgroundColor: UInt32 = 0,
        layout: Layout = Layout(),
        marker: String = "",
        themeId: String = "",
        stateMachineId: String = "",
        animationId: String = ""
    ) {
        self.autoplay = autoplay
        self.loopAnimation = loopAnimation
        self.loopCount = loopCount
        self.mode = mode
        self.speed = speed
        self.useFrameInterpolation = useFrameInterpolation
        self.segment = segment
        self.backgroundColor = backgroundColor
        self.layout = layout
        self.marker = marker
        self.themeId = themeId
        self.stateMachineId = stateMachineId
        self.animationId = animationId
    }

    internal func toCConfig() -> dotlottieDotLottieConfig {
        var config = dotlottieDotLottieConfig()
        dotlottie_init_config(&config)

        config.mode = mode.cMode
        config.loop_animation = loopAnimation
        config.loop_count = loopCount
        config.speed = speed
        config.use_frame_interpolation = useFrameInterpolation
        config.autoplay = autoplay
        config.segment_start = segment.count > 0 ? segment[0] : 0
        config.segment_end = segment.count > 1 ? segment[1] : 0
        config.background_color = backgroundColor
        config.layout = layout.cLayout

        // Convert strings to C strings with fixed size
        withCString(marker) { markerPtr in
            _ = strncpy(&config.marker.value.0, markerPtr, Int(dotlottieDOTLOTTIE_MAX_STR_LENGTH) - 1)
        }
        withCString(themeId) { themePtr in
            _ = strncpy(&config.theme_id.value.0, themePtr, Int(dotlottieDOTLOTTIE_MAX_STR_LENGTH) - 1)
        }
        withCString(stateMachineId) { smPtr in
            _ = strncpy(&config.state_machine_id.value.0, smPtr, Int(dotlottieDOTLOTTIE_MAX_STR_LENGTH) - 1)
        }
        withCString(animationId) { animPtr in
            _ = strncpy(&config.animation_id.value.0, animPtr, Int(dotlottieDOTLOTTIE_MAX_STR_LENGTH) - 1)
        }

        return config
    }

    internal init(cConfig: dotlottieDotLottieConfig) {
        self.mode = Mode(cMode: cConfig.mode)
        self.loopAnimation = cConfig.loop_animation
        self.loopCount = cConfig.loop_count
        self.speed = cConfig.speed
        self.useFrameInterpolation = cConfig.use_frame_interpolation
        self.autoplay = cConfig.autoplay
        self.segment = [cConfig.segment_start, cConfig.segment_end]
        self.backgroundColor = cConfig.background_color
        self.layout = Layout(cLayout: cConfig.layout)

        // Convert C strings to Swift strings
        self.marker = String(cString: withUnsafePointer(to: cConfig.marker.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } })
        self.themeId = String(cString: withUnsafePointer(to: cConfig.theme_id.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } })
        self.stateMachineId = String(cString: withUnsafePointer(to: cConfig.state_machine_id.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } })
        self.animationId = String(cString: withUnsafePointer(to: cConfig.animation_id.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } })
    }
}

// Helper function to convert Swift String to C string
private func withCString<T>(_ string: String, _ body: (UnsafePointer<CChar>) -> T) -> T {
    return string.withCString(body)
}

// MARK: - Manifest

public struct Manifest {
    public var generator: String?
    public var version: String?
    public var animations: [ManifestAnimation]?
    public var themes: [ManifestTheme]?
    public var stateMachines: [ManifestStateMachine]?

    public init(
        generator: String? = nil,
        version: String? = nil,
        animations: [ManifestAnimation]? = nil,
        themes: [ManifestTheme]? = nil,
        stateMachines: [ManifestStateMachine]? = nil
    ) {
        self.generator = generator
        self.version = version
        self.animations = animations
        self.themes = themes
        self.stateMachines = stateMachines
    }
}

public struct ManifestAnimation {
    public var id: String?
    public var name: String?
    public var initialTheme: String?
    public var background: String?

    public init(id: String? = nil, name: String? = nil, initialTheme: String? = nil, background: String? = nil) {
        self.id = id
        self.name = name
        self.initialTheme = initialTheme
        self.background = background
    }
}

public struct ManifestTheme {
    public var id: String
    public var name: String?

    public init(id: String, name: String? = nil) {
        self.id = id
        self.name = name
    }
}

public struct ManifestStateMachine {
    public var id: String
    public var name: String?

    public init(id: String, name: String? = nil) {
        self.id = id
        self.name = name
    }
}

// MARK: - Marker

public struct Marker {
    public var name: String
    public var time: Float
    public var duration: Float

    public init(name: String, time: Float, duration: Float) {
        self.name = name
        self.time = time
        self.duration = duration
    }

    internal init(cMarker: dotlottieDotLottieMarker) {
        self.name = String(cString: withUnsafePointer(to: cMarker.name.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } })
        self.time = cMarker.time
        self.duration = cMarker.duration
    }
}

// MARK: - Events

public enum Event {
    case pointerDown(x: Float, y: Float)
    case pointerUp(x: Float, y: Float)
    case pointerMove(x: Float, y: Float)
    case pointerEnter(x: Float, y: Float)
    case pointerExit(x: Float, y: Float)
    case click(x: Float, y: Float)
    case onComplete
    case onLoopComplete

    internal func toCEvent() -> dotlottieDotLottieEvent {
        var event = dotlottieDotLottieEvent()

        switch self {
        case .pointerDown(let x, let y):
            event.tag = PointerDown
            event.pointer_down = dotlottiePointerDown_Body(x: x, y: y)
        case .pointerUp(let x, let y):
            event.tag = PointerUp
            event.pointer_up = dotlottiePointerUp_Body(x: x, y: y)
        case .pointerMove(let x, let y):
            event.tag = PointerMove
            event.pointer_move = dotlottiePointerMove_Body(x: x, y: y)
        case .pointerEnter(let x, let y):
            event.tag = PointerEnter
            event.pointer_enter = dotlottiePointerEnter_Body(x: x, y: y)
        case .pointerExit(let x, let y):
            event.tag = PointerExit
            event.pointer_exit = dotlottiePointerExit_Body(x: x, y: y)
        case .click(let x, let y):
            event.tag = Click
            event.click = dotlottieClick_Body(x: x, y: y)
        case .onComplete:
            event.tag = OnComplete
        case .onLoopComplete:
            event.tag = OnLoopComplete
        }

        return event
    }
}

// MARK: - OpenUrlPolicy

public struct OpenUrlPolicy {
    public var requireUserInteraction: Bool
    public var whitelist: [String]

    public init(requireUserInteraction: Bool = true, whitelist: [String] = []) {
        self.requireUserInteraction = requireUserInteraction
        self.whitelist = whitelist
    }

    internal func toCPolicy() -> dotlottieDotLottieOpenUrlPolicy {
        var policy = dotlottieDotLottieOpenUrlPolicy()
        policy.require_user_interaction = requireUserInteraction

        let whitelistStr = whitelist.joined(separator: ",")
        withCString(whitelistStr) { ptr in
            _ = strncpy(&policy.whitelist.value.0, ptr, Int(dotlottieDOTLOTTIE_MAX_STR_LENGTH) - 1)
        }

        return policy
    }
}

// MARK: - Observer Protocols

public protocol Observer: AnyObject {
    func onLoad()
    func onLoadError()
    func onPlay()
    func onPause()
    func onStop()
    func onFrame(frameNo: Float)
    func onRender(frameNo: Float)
    func onLoop(loopCount: UInt32)
    func onComplete()
}

public protocol StateMachineObserver: AnyObject {
    func onTransition(previousState: String, newState: String)
    func onStateEntered(enteringState: String)
    func onStateExit(leavingState: String)
}

public protocol StateMachineInternalObserver: AnyObject {
    func onMessage(message: String)
}

// MARK: - DotLottiePlayer

public class DotLottiePlayer {
    private var playerPtr: OpaquePointer?
    private var stateMachinePtr: OpaquePointer?

    private var observers: [Observer] = []
    private var stateMachineObservers: [StateMachineObserver] = []
    private var stateMachineInternalObservers: [StateMachineInternalObserver] = []

    private var eventPollTimer: Timer?

    public init(config: Config) {
        var cConfig = config.toCConfig()
        playerPtr = dotlottie_new_player(&cConfig)
        startEventPolling()
    }

    public static func withThreads(config: Config, threads: UInt32) -> DotLottiePlayer {
        // Note: The C API doesn't expose thread configuration
        // Using regular init for now
        return DotLottiePlayer(config: config)
    }

    deinit {
        stopEventPolling()

        if let smPtr = stateMachinePtr {
            dotlottie_state_machine_release(smPtr)
            stateMachinePtr = nil
        }

        if let ptr = playerPtr {
            dotlottie_destroy(ptr)
            playerPtr = nil
        }
    }

    // MARK: - Loading

    public func loadAnimationData(animationData: String, width: UInt32, height: UInt32) -> Bool {
        guard let ptr = playerPtr else { return false }
        return animationData.withCString { dataPtr in
            dotlottie_load_animation_data(ptr, dataPtr, width, height) == dotlottieDOTLOTTIE_SUCCESS
        }
    }

    public func loadAnimationPath(animationPath: String, width: UInt32, height: UInt32) -> Bool {
        guard let ptr = playerPtr else { return false }
        return animationPath.withCString { pathPtr in
            dotlottie_load_animation_path(ptr, pathPtr, width, height) == dotlottieDOTLOTTIE_SUCCESS
        }
    }

    public func loadAnimation(animationId: String, width: UInt32, height: UInt32) -> Bool {
        guard let ptr = playerPtr else { return false }
        return animationId.withCString { idPtr in
            dotlottie_load_animation(ptr, idPtr, width, height) == dotlottieDOTLOTTIE_SUCCESS
        }
    }

    public func loadDotlottieData(fileData: Data, width: UInt32, height: UInt32) -> Bool {
        guard let ptr = playerPtr else { return false }
        return fileData.withUnsafeBytes { bufferPtr in
            guard let baseAddress = bufferPtr.baseAddress else { return false }
            return dotlottie_load_dotlottie_data(ptr, baseAddress.assumingMemoryBound(to: CChar.self), UInt(fileData.count), width, height) == dotlottieDOTLOTTIE_SUCCESS
        }
    }

    // MARK: - Playback

    public func play() -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_play(ptr) == dotlottieDOTLOTTIE_SUCCESS
    }

    public func pause() -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_pause(ptr) == dotlottieDOTLOTTIE_SUCCESS
    }

    public func stop() -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_stop(ptr) == dotlottieDOTLOTTIE_SUCCESS
    }

    public func tick() -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_tick(ptr) == dotlottieDOTLOTTIE_SUCCESS
    }

    public func render() -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_render(ptr) == dotlottieDOTLOTTIE_SUCCESS
    }

    public func setFrame(no: Float) -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_set_frame(ptr, no) == dotlottieDOTLOTTIE_SUCCESS
    }

    public func seek(frame: Float) -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_seek(ptr, frame) == dotlottieDOTLOTTIE_SUCCESS
    }

    // MARK: - State

    public func isLoaded() -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_is_loaded(ptr) == 1
    }

    public func isPlaying() -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_is_playing(ptr) == 1
    }

    public func isPaused() -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_is_paused(ptr) == 1
    }

    public func isStopped() -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_is_stopped(ptr) == 1
    }

    public func isComplete() -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_is_complete(ptr) == 1
    }

    // MARK: - Properties

    public func totalFrames() -> Float {
        guard let ptr = playerPtr else { return 0 }
        var result: Float = 0
        dotlottie_total_frames(ptr, &result)
        return result
    }

    public func currentFrame() -> Float {
        guard let ptr = playerPtr else { return 0 }
        var result: Float = 0
        dotlottie_current_frame(ptr, &result)
        return result
    }

    public func duration() -> Float {
        guard let ptr = playerPtr else { return 0 }
        var result: Float = 0
        dotlottie_duration(ptr, &result)
        return result
    }

    public func loopCount() -> UInt32 {
        guard let ptr = playerPtr else { return 0 }
        var result: UInt32 = 0
        dotlottie_loop_count(ptr, &result)
        return result
    }

    // MARK: - Renderer Targets

    /// Set software (CPU) rendering target
    /// - Parameters:
    ///   - buffer: Pre-allocated RGBA buffer (width × height)
    ///   - stride: Bytes per row (typically width × 4)
    ///   - width: Buffer width in pixels
    ///   - height: Buffer height in pixels
    ///   - colorSpace: Pixel format (default: argb8888)
    /// - Returns: true if successful
    public func setSoftwareTarget(
        buffer: UnsafeMutablePointer<UInt32>,
        stride: UInt32,
        width: UInt32,
        height: UInt32,
        colorSpace: ColorSpace = .argb8888
    ) -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_set_sw_target(
            ptr, buffer, width, height, colorSpace.cColorSpace
        ) == dotlottieDOTLOTTIE_SUCCESS
    }

    /// Set OpenGL rendering target
    public func setGLTarget(
        context: UnsafeMutableRawPointer,
        id: Int32,
        width: UInt32,
        height: UInt32,
        colorSpace: ColorSpace = .argb8888
    ) -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_set_gl_target(
            ptr, context, id, width, height
        ) == dotlottieDOTLOTTIE_SUCCESS
    }

    /// Set WebGPU rendering target
    public func setWebGPUTarget(
        device: UnsafeMutableRawPointer?,
        instance: UnsafeMutableRawPointer?,
        target: UnsafeMutableRawPointer,
        width: UInt32,
        height: UInt32,
        colorSpace: ColorSpace = .abgr8888s,
        type: Int32 = 0  // 0 = surface, 1 = texture
    ) -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_set_wg_target(
            ptr, device, instance, target, width, height
        ) == dotlottieDOTLOTTIE_SUCCESS
    }

    // MARK: - WebGPU Context Management

    /// Create WebGPU context from Metal layer
    /// - Parameter metalLayer: Pointer to CAMetalLayer
    /// - Returns: Opaque pointer to WgpuContext, or nil on failure
    public static func createWebGPUContext(metalLayer: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
        return dotlottie_create_wgpu_context_from_metal_layer(metalLayer)
    }

    /// Get WebGPU pointers from context
    /// - Parameter context: Context from createWebGPUContext
    /// - Returns: Tuple of (device, instance, surface) or nil on failure
    public static func getWebGPUPointers(context: UnsafeMutableRawPointer) -> (device: UInt64, instance: UInt64, surface: UInt64)? {
        var device: UInt64 = 0
        var instance: UInt64 = 0
        var surface: UInt64 = 0
        dotlottie_wgpu_context_get_pointers(context, &device, &instance, &surface)

        if device == 0 || instance == 0 || surface == 0 {
            return nil
        }

        return (device: device, instance: instance, surface: surface)
    }

    /// Free WebGPU context
    /// - Parameter context: Context to free
    public static func freeWebGPUContext(context: UnsafeMutableRawPointer) {
        dotlottie_free_wgpu_context(context)
    }

    /// Present WebGPU surface to display rendered frame
    /// MUST be called after tick() when using WebGPU rendering
    /// Without this, rendering happens off-screen but never displays
    /// - Parameter context: WebGPU context from createWebGPUContext
    public static func presentWebGPUSurface(context: UnsafeMutableRawPointer) {
        dotlottie_wgpu_context_present(context)
    }

    // MARK: - Configuration

    public func config() -> Config {
        guard let ptr = playerPtr else { return Config() }
        var cConfig = dotlottieDotLottieConfig()
        dotlottie_config(ptr, &cConfig)
        return Config(cConfig: cConfig)
    }

    public func setConfig(config: Config) {
        guard let ptr = playerPtr else { return }
        var cConfig = config.toCConfig()

        // Apply config by setting individual properties
        // Note: There's no single set_config in C API, so we set properties individually
        let currentConfig = self.config()

        // For now, we'll need to recreate the player with new config
        // This is a limitation of the C API
        // Individual setters can be added as needed
    }

    // MARK: - Resize

    public func resize(width: UInt32, height: UInt32) -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_resize(ptr, width, height) == dotlottieDOTLOTTIE_SUCCESS
    }

    public func clear() {
        guard let ptr = playerPtr else { return }
        dotlottie_clear(ptr)
    }

    // MARK: - Manifest

    public func manifest() -> Manifest? {
        guard let ptr = playerPtr else { return nil }

        var cManifest = dotlottieDotLottieManifest()
        guard dotlottie_manifest(ptr, &cManifest) == dotlottieDOTLOTTIE_SUCCESS else {
            return nil
        }

        let generator = cManifest.generator.defined ? String(cString: withUnsafePointer(to: cManifest.generator.value.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } }) : nil
        let version = cManifest.version.defined ? String(cString: withUnsafePointer(to: cManifest.version.value.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } }) : nil

        // Get animations
        var animSize: UInt = 0
        dotlottie_manifest_animations(ptr, nil, &animSize)
        var animations: [ManifestAnimation] = []
        if animSize > 0 {
            var cAnimations = [dotlottieDotLottieManifestAnimation](repeating: dotlottieDotLottieManifestAnimation(), count: Int(animSize))
            dotlottie_manifest_animations(ptr, &cAnimations, &animSize)
            animations = cAnimations.map { cAnim in
                ManifestAnimation(
                    id: cAnim.id.defined ? String(cString: withUnsafePointer(to: cAnim.id.value.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } }) : nil,
                    name: cAnim.name.defined ? String(cString: withUnsafePointer(to: cAnim.name.value.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } }) : nil,
                    initialTheme: cAnim.initial_theme.defined ? String(cString: withUnsafePointer(to: cAnim.initial_theme.value.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } }) : nil,
                    background: cAnim.background.defined ? String(cString: withUnsafePointer(to: cAnim.background.value.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } }) : nil
                )
            }
        }

        // Get themes
        var themeSize: UInt = 0
        dotlottie_manifest_themes(ptr, nil, &themeSize)
        var themes: [ManifestTheme] = []
        if themeSize > 0 {
            var cThemes = [dotlottieDotLottieManifestTheme](repeating: dotlottieDotLottieManifestTheme(), count: Int(themeSize))
            dotlottie_manifest_themes(ptr, &cThemes, &themeSize)
            themes = cThemes.map { cTheme in
                ManifestTheme(
                    id: String(cString: withUnsafePointer(to: cTheme.id.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } }),
                    name: cTheme.name.defined ? String(cString: withUnsafePointer(to: cTheme.name.value.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } }) : nil
                )
            }
        }

        // Get state machines
        var smSize: UInt = 0
        dotlottie_manifest_state_machines(ptr, nil, &smSize)
        var stateMachines: [ManifestStateMachine] = []
        if smSize > 0 {
            var cSMs = [dotlottieDotLottieManifestStateMachine](repeating: dotlottieDotLottieManifestStateMachine(), count: Int(smSize))
            dotlottie_manifest_state_machines(ptr, &cSMs, &smSize)
            stateMachines = cSMs.map { cSM in
                ManifestStateMachine(
                    id: String(cString: withUnsafePointer(to: cSM.id.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } }),
                    name: cSM.name.defined ? String(cString: withUnsafePointer(to: cSM.name.value.value) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } }) : nil
                )
            }
        }

        return Manifest(
            generator: generator,
            version: version,
            animations: animations.isEmpty ? nil : animations,
            themes: themes.isEmpty ? nil : themes,
            stateMachines: stateMachines.isEmpty ? nil : stateMachines
        )
    }

    // MARK: - Markers

    public func markers() -> [Marker] {
        guard let ptr = playerPtr else { return [] }

        var size: UInt = 0
        dotlottie_markers(ptr, nil, &size)

        guard size > 0 else { return [] }

        var cMarkers = [dotlottieDotLottieMarker](repeating: dotlottieDotLottieMarker(), count: Int(size))
        dotlottie_markers(ptr, &cMarkers, &size)

        return cMarkers.map { Marker(cMarker: $0) }
    }

    // MARK: - Theme

    public func setTheme(themeId: String) -> Bool {
        guard let ptr = playerPtr else { return false }
        return themeId.withCString { idPtr in
            dotlottie_set_theme(ptr, idPtr) == dotlottieDOTLOTTIE_SUCCESS
        }
    }

    public func resetTheme() -> Bool {
        guard let ptr = playerPtr else { return false }
        return dotlottie_reset_theme(ptr) == dotlottieDOTLOTTIE_SUCCESS
    }

    public func setThemeData(themeData: String) -> Bool {
        guard let ptr = playerPtr else { return false }
        return themeData.withCString { dataPtr in
            dotlottie_set_theme_data(ptr, dataPtr) == dotlottieDOTLOTTIE_SUCCESS
        }
    }

    public func activeThemeId() -> String {
        guard let ptr = playerPtr else { return "" }
        var buffer = [CChar](repeating: 0, count: Int(dotlottieDOTLOTTIE_MAX_STR_LENGTH))
        dotlottie_active_theme_id(ptr, &buffer)
        return String(cString: buffer)
    }

    public func activeAnimationId() -> String {
        guard let ptr = playerPtr else { return "" }
        var buffer = [CChar](repeating: 0, count: Int(dotlottieDOTLOTTIE_MAX_STR_LENGTH))
        dotlottie_active_animation_id(ptr, &buffer)
        return String(cString: buffer)
    }

    // MARK: - Slots

    public func setSlotsStr(slots: String) -> Bool {
        guard let ptr = playerPtr else { return false }
        return slots.withCString { slotsPtr in
            dotlottie_set_slots_str(ptr, slotsPtr) == dotlottieDOTLOTTIE_SUCCESS
        }
    }

    // MARK: - Layer Bounds

    public func getLayerBounds(layerName: String) -> [Float] {
        guard let ptr = playerPtr else { return [] }
        var bounds = dotlottieLayerBoundingBox()
        layerName.withCString { namePtr in
            dotlottie_get_layer_bounds(ptr, namePtr, &bounds)
        }
        return [bounds.x1, bounds.y1, bounds.x2, bounds.y2, bounds.x3, bounds.y3, bounds.x4, bounds.y4]
    }

    // MARK: - State Machine

    public func stateMachineLoad(stateMachineId: String) -> Bool {
        guard let ptr = playerPtr else { return false }

        // Release old state machine if exists
        if let smPtr = stateMachinePtr {
            dotlottie_state_machine_release(smPtr)
            stateMachinePtr = nil
        }

        stateMachinePtr = stateMachineId.withCString { idPtr in
            dotlottie_state_machine_load(ptr, idPtr)
        }

        return stateMachinePtr != nil
    }

    public func stateMachineLoadData(stateMachine: String) -> Bool {
        guard let ptr = playerPtr else { return false }

        // Release old state machine if exists
        if let smPtr = stateMachinePtr {
            dotlottie_state_machine_release(smPtr)
            stateMachinePtr = nil
        }

        stateMachinePtr = stateMachine.withCString { dataPtr in
            dotlottie_state_machine_load_data(ptr, dataPtr)
        }

        return stateMachinePtr != nil
    }

    public func stateMachineStart(openUrlPolicy: OpenUrlPolicy) -> Bool {
        guard let smPtr = stateMachinePtr else { return false }
        var policy = openUrlPolicy.toCPolicy()
        return dotlottie_state_machine_start(smPtr, &policy) == dotlottieDOTLOTTIE_SUCCESS
    }

    public func stateMachineStop() -> Bool {
        guard let smPtr = stateMachinePtr else { return false }
        return dotlottie_state_machine_stop(smPtr) == dotlottieDOTLOTTIE_SUCCESS
    }

    public func stateMachinePostEvent(event: Event) {
        guard let smPtr = stateMachinePtr else { return }
        var cEvent = event.toCEvent()
        dotlottie_state_machine_post_event(smPtr, &cEvent)
    }

    public func stateMachineFireEvent(event: String) {
        guard let smPtr = stateMachinePtr else { return }
        event.withCString { eventPtr in
            dotlottie_state_machine_fire_event(smPtr, eventPtr)
        }
    }

    public func stateMachineSetNumericInput(key: String, value: Float) -> Bool {
        guard let smPtr = stateMachinePtr else { return false }
        return key.withCString { keyPtr in
            dotlottie_state_machine_set_numeric_input(smPtr, keyPtr, value) == dotlottieDOTLOTTIE_SUCCESS
        }
    }

    public func stateMachineSetStringInput(key: String, value: String) -> Bool {
        guard let smPtr = stateMachinePtr else { return false }
        return key.withCString { keyPtr in
            value.withCString { valuePtr in
                dotlottie_state_machine_set_string_input(smPtr, keyPtr, valuePtr) == dotlottieDOTLOTTIE_SUCCESS
            }
        }
    }

    public func stateMachineSetBooleanInput(key: String, value: Bool) -> Bool {
        guard let smPtr = stateMachinePtr else { return false }
        return key.withCString { keyPtr in
            dotlottie_state_machine_set_boolean_input(smPtr, keyPtr, value) == dotlottieDOTLOTTIE_SUCCESS
        }
    }

    public func stateMachineGetNumericInput(key: String) -> Float {
        guard let smPtr = stateMachinePtr else { return 0 }
        var result: Float = 0
        key.withCString { keyPtr in
            dotlottie_state_machine_get_numeric_input(smPtr, keyPtr, &result)
        }
        return result
    }

    public func stateMachineGetStringInput(key: String) -> String {
        guard let smPtr = stateMachinePtr else { return "" }
        var buffer = [CChar](repeating: 0, count: Int(dotlottieDOTLOTTIE_MAX_STR_LENGTH))
        key.withCString { keyPtr in
            dotlottie_state_machine_get_string_input(smPtr, keyPtr, &buffer)
        }
        return String(cString: buffer)
    }

    public func stateMachineGetBooleanInput(key: String) -> Bool {
        guard let smPtr = stateMachinePtr else { return false }
        var result: Bool = false
        key.withCString { keyPtr in
            dotlottie_state_machine_get_boolean_input(smPtr, keyPtr, &result)
        }
        return result
    }

    public func stateMachineCurrentState() -> String {
        guard let smPtr = stateMachinePtr else { return "" }
        var buffer = [CChar](repeating: 0, count: Int(dotlottieDOTLOTTIE_MAX_STR_LENGTH))
        dotlottie_state_machine_current_state(smPtr, &buffer)
        return String(cString: buffer)
    }

    public func stateMachineFrameworkSetup() -> [String] {
        guard let smPtr = stateMachinePtr else { return [] }
        var result: UInt16 = 0
        dotlottie_state_machine_framework_setup(smPtr, &result)

        var events: [String] = []
        if result & UInt16(dotlottieINTERACTION_TYPE_POINTER_DOWN) != 0 { events.append("pointerdown") }
        if result & UInt16(dotlottieINTERACTION_TYPE_POINTER_UP) != 0 { events.append("pointerup") }
        if result & UInt16(dotlottieINTERACTION_TYPE_POINTER_MOVE) != 0 { events.append("pointermove") }
        if result & UInt16(dotlottieINTERACTION_TYPE_POINTER_ENTER) != 0 { events.append("pointerenter") }
        if result & UInt16(dotlottieINTERACTION_TYPE_POINTER_EXIT) != 0 { events.append("pointerexit") }
        if result & UInt16(dotlottieINTERACTION_TYPE_CLICK) != 0 { events.append("click") }
        if result & UInt16(dotlottieINTERACTION_TYPE_ON_COMPLETE) != 0 { events.append("oncomplete") }
        if result & UInt16(dotlottieINTERACTION_TYPE_ON_LOOP_COMPLETE) != 0 { events.append("onloopcomplete") }

        return events
    }

    public func stateMachineGetInputs() -> [String] {
        // This returns an array of alternating key-value pairs [key1, type1, key2, type2, ...]
        // We'll return all as strings for now
        return []
    }

    public func getStateMachine(stateMachineId: String) -> String {
        guard let ptr = playerPtr else { return "" }
        var buffer = [CChar](repeating: 0, count: Int(dotlottieDOTLOTTIE_MAX_STR_LENGTH))
        stateMachineId.withCString { idPtr in
            dotlottie_get_state_machine(ptr, idPtr, &buffer)
        }
        return String(cString: buffer)
    }

    // MARK: - Observers

    public func subscribe(observer: Observer) {
        observers.append(observer)
    }

    public func unsubscribe(observer: Observer) {
        observers.removeAll { $0 === observer }
    }

    public func stateMachineSubscribe(observer: StateMachineObserver) -> Bool {
        stateMachineObservers.append(observer)
        return true
    }

    public func stateMachineUnsubscribe(observer: StateMachineObserver) -> Bool {
        stateMachineObservers.removeAll { $0 === observer }
        return true
    }

    public func stateMachineInternalSubscribe(observer: StateMachineInternalObserver) -> Bool {
        stateMachineInternalObservers.append(observer)
        return true
    }

    public func stateMachineInternalUnsubscribe(observer: StateMachineInternalObserver) -> Bool {
        stateMachineInternalObservers.removeAll { $0 === observer }
        return true
    }

    // MARK: - Event Polling

    private func startEventPolling() {
        eventPollTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.pollEvents()
        }
    }

    private func stopEventPolling() {
        eventPollTimer?.invalidate()
        eventPollTimer = nil
    }

    private func pollEvents() {
        guard let ptr = playerPtr else { return }

        // Poll player events
        var event = dotlottieDotLottiePlayerEvent()
        while dotlottie_poll_event(ptr, &event) == 1 {
            handlePlayerEvent(event)
        }

        // Poll state machine events
        if let smPtr = stateMachinePtr {
            var smEvent = dotlottieStateMachineEvent()
            while dotlottie_state_machine_poll_event(smPtr, &smEvent) == 1 {
                handleStateMachineEvent(smEvent)
            }

            var internalEvent = dotlottieStateMachineInternalEvent()
            while dotlottie_state_machine_poll_internal_event(smPtr, &internalEvent) == 1 {
                handleStateMachineInternalEvent(internalEvent)
            }
        }
    }

    private func handlePlayerEvent(_ event: dotlottieDotLottiePlayerEvent) {
        for observer in observers {
            switch event.event_type {
            case Load:
                observer.onLoad()
            case LoadError:
                observer.onLoadError()
            case Play:
                observer.onPlay()
            case Pause:
                observer.onPause()
            case Stop:
                observer.onStop()
            case Frame:
                observer.onFrame(frameNo: event.data.frame_no)
            case Render:
                observer.onRender(frameNo: event.data.frame_no)
            case Loop:
                observer.onLoop(loopCount: event.data.loop_count)
            case Complete:
                observer.onComplete()
            default:
                break
            }
        }
    }

    private func handleStateMachineEvent(_ event: dotlottieStateMachineEvent) {
        for observer in stateMachineObservers {
            switch event.event_type {
            case StateMachineTransition:
                let str1 = String(cString: withUnsafePointer(to: event.data.strings.str1) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } })
                let str2 = String(cString: withUnsafePointer(to: event.data.strings.str2) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } })
                observer.onTransition(previousState: str1, newState: str2)
            case StateMachineStateEntered:
                let state = String(cString: withUnsafePointer(to: event.data.strings.str1) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } })
                observer.onStateEntered(enteringState: state)
            case StateMachineStateExit:
                let state = String(cString: withUnsafePointer(to: event.data.strings.str1) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } })
                observer.onStateExit(leavingState: state)
            default:
                break
            }
        }
    }

    private func handleStateMachineInternalEvent(_ event: dotlottieStateMachineInternalEvent) {
        let message = String(cString: withUnsafePointer(to: event.message) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { $0 } })
        for observer in stateMachineInternalObservers {
            observer.onMessage(message: message)
        }
    }
}

// MARK: - Helper Functions

public func createDefaultLayout() -> Layout {
    return Layout(fit: .contain, alignX: 0.5, alignY: 0.5)
}
