//
//  Example7_StateMachine.swift
//  DotLottieIosTestApp
//
//  State machine example with interactivity
//

import SwiftUI
import DotLottie

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct Example7_StateMachine: View {
    @StateObject private var viewModel = StateMachineExampleViewModel()
    @State private var useLegacyView = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Example 7: State Machine & Interactivity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            
            // Example picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Select Example:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $viewModel.selectedExample) {
                    ForEach(stateMachineExamples.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(stateMachineExamples[index].animation)
                            Text(stateMachineExamples[index].description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .tag(index)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedExample) { newIndex in
                    viewModel.changeExample(index: newIndex)
                }
            }
            
            if !viewModel.stateMachines.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("State Machine")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let selection = Binding<String>(
                        get: { viewModel.selectedStateMachineId ?? viewModel.stateMachines.first?.id ?? "" },
                        set: { viewModel.selectStateMachine(id: $0) }
                    )
                    
                    Picker("", selection: selection) {
                        ForEach(viewModel.stateMachines, id: \.id) { machine in
                            Text(machine.name ?? machine.id)
                                .tag(machine.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Toggle("Use DotLottieAnimation.view (legacy)", isOn: $useLegacyView)
                .font(.caption)
            
            // State machine toggle
            if viewModel.hasStateMachines {
                Toggle("Enable State Machine", isOn: $viewModel.isStateMachineEnabled)
                    .onChange(of: viewModel.isStateMachineEnabled) { enabled in
                        viewModel.toggleStateMachine(enabled: enabled)
                    }
            }
            
            if viewModel.isStateMachineEnabled {
                // Current state display
                HStack {
                    Text("Current State:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.currentState)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Available events
                if !viewModel.availableEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Available Events:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.availableEvents, id: \.self) { event in
                                    Text(event)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
            
            // Animation view with tap handling
            ZStack {
                if let animation = viewModel.animation {
                    if viewModel.isAnimationLoaded {
                        if useLegacyView {
                            // Direct DotLottieAnimation.view with built-in gesture handling
                            animation.view()
                                .frame(height: 250)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .onAppear {
                                    if !viewModel.isStateMachineEnabled, animation.loop() {
                                        _ = animation.play()
                                    }
                                }
                        } else {
                            LottiePlayerView(animation: animation)
                                .loopMode(animation.loop() ? .loop : .playOnce)
                                .playbackMode(viewModel.isStateMachineEnabled ? .paused : .playing)
                                .frame(height: 250)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                    } else {
                        VStack {
                            ProgressView()
                            Text("Loading \(stateMachineExamples[viewModel.selectedExample].animation)...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                } else {
                    ProgressView()
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            // State machine inputs
            if viewModel.isStateMachineEnabled && !viewModel.inputs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("State Machine Inputs:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(viewModel.inputs.keys.sorted()), id: \.self) { key in
                        if let type = viewModel.inputs[key] {
                            InputControl(
                                key: key,
                                type: type,
                                viewModel: viewModel
                            )
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            
            // Instructions
            if viewModel.isStateMachineEnabled {
                #if canImport(UIKit)
                Text("💡 Tap or drag on the animation to interact with the state machine")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                #else
                Text("💡 Click or drag on the animation to interact with the state machine")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                #endif
            } else {
                Text("Toggle 'Enable State Machine' to interact with the animation")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            Spacer(minLength: 20)
        }
        .padding(.horizontal)
        }
        .navigationTitle("State Machine")
    }
}


// MARK: - Input Control

struct InputControl: View {
    let key: String
    let type: String
    @ObservedObject var viewModel: StateMachineExampleViewModel
    
    var body: some View {
        switch type.lowercased() {
        case "number", "numeric":
            NumericInputControl(key: key, viewModel: viewModel)
        case "boolean", "bool":
            BooleanInputControl(key: key, viewModel: viewModel)
        case "string":
            StringInputControl(key: key, viewModel: viewModel)
        case "event":
            EventInputControl(key: key, viewModel: viewModel)
        default:
            Text("\(key): \(type)")
                .font(.caption)
        }
    }
}

struct NumericInputControl: View {
    let key: String
    @ObservedObject var viewModel: StateMachineExampleViewModel
    @State private var value: Double = 0
    @State private var isUserEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(key): \(String(format: "%.0f", value))")
                .font(.caption)
            
            Stepper(value: $value, in: 0...100, step: 1) {
                EmptyView()
            }
            .labelsHidden()
            .onChange(of: value) { newValue in
                isUserEditing = true
                viewModel.setNumericInput(key: key, value: Float(newValue))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isUserEditing = false
                }
            }
        }
        .onAppear {
            value = Double(viewModel.getNumericInput(key: key))
        }
        .onChange(of: viewModel.inputValues[key] as? Float) { newValue in
            // Only update from animation if user is not currently editing
            if !isUserEditing, let newValue = newValue {
                value = Double(newValue)
            }
        }
    }
}

struct BooleanInputControl: View {
    let key: String
    @ObservedObject var viewModel: StateMachineExampleViewModel
    @State private var value: Bool = false
    @State private var isUserEditing = false
    
    var body: some View {
        Toggle(key, isOn: $value)
            .font(.caption)
            .onChange(of: value) { newValue in
                isUserEditing = true
                viewModel.setBooleanInput(key: key, value: newValue)
                // Reset editing flag after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isUserEditing = false
                }
            }
            .onAppear {
                value = viewModel.getBooleanInput(key: key)
            }
            .onChange(of: viewModel.inputValues[key] as? Bool) { newValue in
                // Only update from animation if user is not currently editing
                if !isUserEditing, let newValue = newValue {
                    value = newValue
                }
            }
    }
}

struct StringInputControl: View {
    let key: String
    @ObservedObject var viewModel: StateMachineExampleViewModel
    @State private var value: String = ""
    @State private var isUserEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.caption)
            
            TextField("Enter value", text: $value)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .onChange(of: value) { newValue in
                    isUserEditing = true
                    viewModel.setStringInput(key: key, value: newValue)
                    // Reset editing flag after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isUserEditing = false
                    }
                }
                .onAppear {
                    value = viewModel.getStringInput(key: key)
                }
                .onChange(of: viewModel.inputValues[key] as? String) { newValue in
                    // Only update from animation if user is not currently editing
                    if !isUserEditing, let newValue = newValue {
                        value = newValue
                    }
                }
        }
    }
}

struct EventInputControl: View {
    let key: String
    @ObservedObject var viewModel: StateMachineExampleViewModel
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            print("🔘 Event button pressed: \(key)")
            viewModel.fireEvent(key: key)
            
            // Visual feedback
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            Text(key)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
    }
}

// MARK: - ViewModel

// Available state machine examples (.lottie files with embedded state machines)
let stateMachineExamples = [
    StateMachineExample(animation: "adding-guests", description: "Adding Guests"),
    StateMachineExample(animation: "star-marked", description: "Star marking"),
    StateMachineExample(animation: "clipped-traffic-lights", description: "Traffic light states"),
    StateMachineExample(animation: "pigeon", description: "Interactive pigeon"),
    StateMachineExample(animation: "smiley-slider", description: "Slider interaction"),
    StateMachineExample(animation: "sync-to-cursor", description: "Follow cursor movement"),
    StateMachineExample(animation: "theming", description: "Theme switching"),
]

struct StateMachineExample {
    let animation: String
    let description: String
}

class StateMachineExampleViewModel: ObservableObject {
    @Published var isStateMachineEnabled = false
    @Published var currentState = "N/A"
    @Published var availableEvents: [String] = []
    @Published var inputs: [String: String] = [:]
    @Published var inputValues: [String: Any] = [:] // Stores current input values
    @Published var stateMachines: [ManifestStateMachine] = []
    @Published var selectedStateMachineId: String?
    @Published var animation: DotLottieAnimation?
    @Published var selectedExample = 0
    @Published var hasStateMachines = false
    @Published var isAnimationLoaded = false
    
    init() {
        setupAnimation(example: stateMachineExamples[0])
    }
    
    func changeExample(index: Int) {
        guard index < stateMachineExamples.count else { return }
        selectedExample = index
        
        // Reset state
        isAnimationLoaded = false
        hasStateMachines = false
        stateMachines = []
        selectedStateMachineId = nil
        
        // Stop current state machine
        if isStateMachineEnabled {
            stopStateMachine()
        }
        
        // Setup new animation
        setupAnimation(example: stateMachineExamples[index])
    }
    
    private func setupAnimation(example: StateMachineExample) {
        let config = AnimationConfig(
            autoplay: true,
            loop: true
        )
        
        // Create new animation
        let newAnimation = DotLottieAnimation(
            fileName: example.animation,
            bundle: .main,
            config: config
        )
        
        // Update on main thread
        DispatchQueue.main.async {
            self.animation = newAnimation
        }
        
        // Monitor loading status
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self = self, let animation = self.animation else {
                timer.invalidate()
                return
            }
            
            if animation.isLoaded() {
                timer.invalidate()
                print("✅ Animation loaded: \(example.animation)")
                
                self.isAnimationLoaded = true
                
                // Animation is now loaded, check for state machines
                self.checkForStateMachines()
            } else if animation.error() {
                timer.invalidate()
                print("❌ Error loading animation")
                self.hasStateMachines = false
                self.isAnimationLoaded = false
            }
        }
    }
    
    private func checkForStateMachines() {
        guard let animation = animation,
              animation.isLoaded() else {
            print("⚠️ Animation not loaded yet")
            hasStateMachines = false
            return
        }
        
        guard let manifest = animation.manifest() else {
            print("⚠️ No manifest found")
            hasStateMachines = false
            stateMachines = []
            selectedStateMachineId = nil
            return
        }
        
        stateMachines = manifest.stateMachines ?? []
        hasStateMachines = !stateMachines.isEmpty
        
        if let selectedStateMachineId,
           !stateMachines.contains(where: { $0.id == selectedStateMachineId }) {
            self.selectedStateMachineId = nil
        }
        
        if selectedStateMachineId == nil {
            selectedStateMachineId = stateMachines.first?.id
        }
        
        if hasStateMachines {
            print("✅ Found \(stateMachines.count) state machine(s) in manifest")
            stateMachines.forEach { sm in
                print("  - \(sm.name ?? sm.id) (ID: \(sm.id))")
            }
        } else {
            print("⚠️ No state machines found in this animation's manifest")
        }
    }
    
    func selectStateMachine(id: String) {
        guard stateMachines.contains(where: { $0.id == id }) else { return }
        let changed = selectedStateMachineId != id
        selectedStateMachineId = id
        
        if changed && isStateMachineEnabled {
            startStateMachine()
        }
    }
    
    func toggleStateMachine(enabled: Bool) {
        if enabled {
            startStateMachine()
        } else {
            stopStateMachine()
        }
    }
    
    private func startStateMachine() {
        guard let animation = animation else {
            print("⚠️ Cannot start state machine - no animation")
            return
        }
        
        // Wait for animation to be fully loaded
        guard animation.isLoaded() else {
            print("⚠️ Animation not loaded yet, waiting...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.startStateMachine()
            }
            return
        }
        
        guard let manifest = animation.manifest(),
              let manifestStateMachines = manifest.stateMachines,
              !manifestStateMachines.isEmpty else {
            print("⚠️ Cannot start state machine - none available in manifest")
            hasStateMachines = false
            isStateMachineEnabled = false
            return
        }
        
        stateMachines = manifestStateMachines
        
        let targetId = selectedStateMachineId ?? manifestStateMachines.first?.id
        guard let targetId else {
            print("⚠️ No state machine selected")
            isStateMachineEnabled = false
            return
        }
        
        selectedStateMachineId = targetId
        
        // Stop normal playback
        _ = animation.pause()
        _ = animation.stateMachineStop()
        
        // Start the state machine
        let started = animation.stateMachineStart(id: targetId)
        print("State machine '\(targetId)' started: \(started)")
        
        if started {
            // Update available events
            availableEvents = animation.stateMachineFrameworkSetup()
            print("Available events: \(availableEvents)")
            
            // Update inputs
            inputValues = [:]
            inputs = animation.stateMachineGetInputs()
            print("Inputs: \(inputs)")
            
            // Update current state
            updateCurrentState()
            
            // Start polling state
            startStatePolling()
            
            isStateMachineEnabled = true
        } else {
            print("⚠️ Failed to start state machine")
            isStateMachineEnabled = false
            // Re-enable looping if state machine failed
            _ = animation.play()
        }
    }
    
    private func stopStateMachine() {
        guard let animation = animation else { return }
        
        // Stop state machine
        _ = animation.stateMachineStop()
        currentState = "N/A"
        availableEvents = []
        inputs = [:]
        stopStatePolling()
        isStateMachineEnabled = false
        
        // Resume normal looping playback
        _ = animation.play()
        
        print("State machine stopped - animation now looping")
    }
    
    func setNumericInput(key: String, value: Float) {
        _ = animation?.stateMachineSetNumericInput(key: key, value: value)
    }
    
    func setBooleanInput(key: String, value: Bool) {
        _ = animation?.stateMachineSetBooleanInput(key: key, value: value)
    }
    
    func setStringInput(key: String, value: String) {
        _ = animation?.stateMachineSetStringInput(key: key, value: value)
    }
    
    func fireEvent(key: String) {
        animation?.stateMachineFire(event: key)
    }
    
    func getNumericInput(key: String) -> Float {
        animation?.stateMachineGetNumericInput(key: key) ?? 0
    }
    
    func getBooleanInput(key: String) -> Bool {
        animation?.stateMachineGetBooleanInput(key: key) ?? false
    }
    
    func getStringInput(key: String) -> String {
        animation?.stateMachineGetStringInput(key: key) ?? ""
    }
    
    private var statePollingTimer: Timer?
    
    private func startStatePolling() {
        statePollingTimer?.invalidate()
        statePollingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.updateCurrentState()
            // Don't automatically poll input values - only update when user changes them
            // self?.updateInputValues()
        }
    }
    
    private func stopStatePolling() {
        statePollingTimer?.invalidate()
        statePollingTimer = nil
    }
    
    private func updateCurrentState() {
        guard let animation = animation else { return }
        currentState = animation.stateMachineCurrentState()
    }
    
    private func updateInputValues() {
        guard let animation = animation else { return }
        
        // Update all input values from the animation (only if changed)
        for (key, type) in inputs {
            switch type.lowercased() {
            case "number", "numeric":
                let value = animation.stateMachineGetNumericInput(key: key)
                // Only update if value actually changed
                if let currentValue = inputValues[key] as? Float, currentValue != value {
                    inputValues[key] = value
                } else if inputValues[key] == nil {
                    inputValues[key] = value
                }
            case "boolean", "bool":
                let value = animation.stateMachineGetBooleanInput(key: key)
                // Only update if value actually changed
                if let currentValue = inputValues[key] as? Bool, currentValue != value {
                    inputValues[key] = value
                } else if inputValues[key] == nil {
                    inputValues[key] = value
                }
            case "string":
                let value = animation.stateMachineGetStringInput(key: key)
                // Only update if value actually changed
                if let currentValue = inputValues[key] as? String, currentValue != value {
                    inputValues[key] = value
                } else if inputValues[key] == nil {
                    inputValues[key] = value
                }
            default:
                break
            }
        }
    }
    
    deinit {
        stopStatePolling()
    }
}

