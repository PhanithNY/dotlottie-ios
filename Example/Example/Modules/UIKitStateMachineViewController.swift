//
//  UIKitStateMachineViewController.swift
//  DotLottieIosTestApp
//
//  UIKit state machine example
//
#if canImport(UIKit)
import UIKit
import SwiftUI
import DotLottie

class UIKitStateMachineViewController: UIViewController {
    
    private var animation: DotLottieAnimation?
    private var enableSwitch: UISwitch!
    private var examplePicker: UIPickerView!
    private var stateLabel: UILabel!
    private var eventsLabel: UILabel!
    private var inputsStackView: UIStackView!
    private var instructionLabel: UILabel!
    private var stateMachineButton: UIButton!
    private var stateStackView: UIStackView!
    private var playerView: DotLottiePlayerUIView?
    
    private var availableStateMachines: [ManifestStateMachine] = []
    private var selectedStateMachineId: String?
    
    private var isStateMachineEnabled = false
    private var selectedExampleIndex = 0
    private var statePollingTimer: Timer?
    
    private let examples = [
        ("adding-guests", "Adding Guests"),
        ("clipped-traffic-lights", "Traffic light states"),
        ("pigeon", "Interactive pigeon"),
        ("smiley-slider", "Slider interaction"),
        ("sync-to-cursor", "Cursor tracking"),
        ("theming", "Theme switching"),
        ("star-marked", "Star marking")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "UIKit State Machine"
        
        setupUI()
        setupAnimation(example: examples[0])
    }
    
    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Example picker
        let pickerLabel = UILabel()
        pickerLabel.text = "Select Example:"
        pickerLabel.font = .systemFont(ofSize: 14, weight: .medium)
        pickerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        examplePicker = UIPickerView()
        examplePicker.delegate = self
        examplePicker.dataSource = self
        examplePicker.translatesAutoresizingMaskIntoConstraints = false
        
        // Enable switch
        let enableLabel = UILabel()
        enableLabel.text = "Enable State Machine"
        enableLabel.font = .systemFont(ofSize: 14)
        enableLabel.translatesAutoresizingMaskIntoConstraints = false
        
        enableSwitch = UISwitch()
        enableSwitch.addTarget(self, action: #selector(stateMachineToggled), for: .valueChanged)
        enableSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        stateStackView = UIStackView(arrangedSubviews: [enableLabel, enableSwitch])
        stateStackView.axis = .horizontal
        stateStackView.spacing = 12
        stateStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // State label
        stateLabel = UILabel()
        stateLabel.text = "State: N/A"
        stateLabel.font = .systemFont(ofSize: 12)
        stateLabel.textColor = .secondaryLabel
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Events label
        eventsLabel = UILabel()
        eventsLabel.text = "Events: None"
        eventsLabel.font = .systemFont(ofSize: 10)
        eventsLabel.textColor = .secondaryLabel
        eventsLabel.numberOfLines = 0
        eventsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Inputs container
        inputsStackView = UIStackView()
        inputsStackView.axis = .vertical
        inputsStackView.spacing = 12
        inputsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Instruction label
        instructionLabel = UILabel()
        instructionLabel.text = "💡 Tap on the animation to interact"
        instructionLabel.font = .systemFont(ofSize: 12)
        instructionLabel.textColor = .systemBlue
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        instructionLabel.isHidden = true
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stateMachineButton = UIButton(type: .system)
        stateMachineButton.setTitle("Select State Machine", for: .normal)
        stateMachineButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        stateMachineButton.contentHorizontalAlignment = .left
        stateMachineButton.isHidden = true
        stateMachineButton.addTarget(self, action: #selector(selectStateMachineTapped), for: .touchUpInside)
        stateMachineButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Placeholder for player view
        let playerViewPlaceholder = UIView()
        playerViewPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        playerViewPlaceholder.backgroundColor = .systemGray6
        playerViewPlaceholder.layer.cornerRadius = 12
        playerViewPlaceholder.tag = 9999
        
        contentView.addSubview(pickerLabel)
        contentView.addSubview(examplePicker)
        contentView.addSubview(playerViewPlaceholder)
        contentView.addSubview(stateStackView)
        contentView.addSubview(stateLabel)
        contentView.addSubview(eventsLabel)
        contentView.addSubview(inputsStackView)
        contentView.addSubview(instructionLabel)
        contentView.addSubview(stateMachineButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            pickerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            pickerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            examplePicker.topAnchor.constraint(equalTo: pickerLabel.bottomAnchor, constant: 8),
            examplePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            examplePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            examplePicker.heightAnchor.constraint(equalToConstant: 100),
            
            playerViewPlaceholder.topAnchor.constraint(equalTo: examplePicker.bottomAnchor, constant: 16),
            playerViewPlaceholder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            playerViewPlaceholder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            playerViewPlaceholder.heightAnchor.constraint(equalToConstant: 250),
            
            stateStackView.topAnchor.constraint(equalTo: playerViewPlaceholder.bottomAnchor, constant: 16),
            stateStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            stateMachineButton.topAnchor.constraint(equalTo: stateStackView.bottomAnchor, constant: 8),
            stateMachineButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stateMachineButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            stateLabel.topAnchor.constraint(equalTo: stateMachineButton.bottomAnchor, constant: 12),
            stateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            eventsLabel.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 8),
            eventsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            inputsStackView.topAnchor.constraint(equalTo: eventsLabel.bottomAnchor, constant: 16),
            inputsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            inputsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            instructionLabel.topAnchor.constraint(equalTo: inputsStackView.bottomAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            instructionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupAnimation(example: (String, String)) {
        // Remove old player view if any
        playerView?.removeFromSuperview()
        playerView = nil
        
        availableStateMachines = []
        selectedStateMachineId = nil
        stateMachineButton?.isHidden = true
        stateMachineButton?.setTitle("Select State Machine", for: .normal)
        
        let config = AnimationConfig(
            autoplay: true,
            loop: true
        )
        
        // Create animation
        animation = DotLottieAnimation(
            fileName: example.0,
            bundle: .main,
            config: config
        )
        
        guard let animation = animation else {
            print("❌ Failed to create animation")
            return
        }
        
        // Monitor loading status
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if animation.isLoaded() {
                timer.invalidate()
                print("✅ Animation loaded (.lottie file): \(example.0)")
                
                DispatchQueue.main.async {
                    // Start with looping playback
                    animation.setLoop(loop: true)
                    _ = animation.play()
                }
            } else if animation.error() {
                timer.invalidate()
                print("❌ Error loading animation")
            }
        }
        
        // Use DotLottiePlayerUIView for playback and interaction
        let player = DotLottiePlayerUIView(dotLottieAnimation: animation, config: config)
        player.translatesAutoresizingMaskIntoConstraints = false
        player.backgroundColor = .clear
        player.layer.cornerRadius = 12
        player.clipsToBounds = true
        playerView = player
        
        // Insert animation view in placeholder position
        if let scrollView = view.subviews.first as? UIScrollView,
           let contentView = scrollView.subviews.first,
           let placeholder = contentView.viewWithTag(9999) {
            contentView.insertSubview(player, aboveSubview: placeholder)
            
            NSLayoutConstraint.activate([
                player.topAnchor.constraint(equalTo: placeholder.topAnchor),
                player.leadingAnchor.constraint(equalTo: placeholder.leadingAnchor),
                player.trailingAnchor.constraint(equalTo: placeholder.trailingAnchor),
                player.heightAnchor.constraint(equalTo: placeholder.heightAnchor)
            ])
        }
        
        stateLabel.isHidden = animation.manifest()?.stateMachines?.isEmpty ?? true == true
    }
    
    
    @objc private func stateMachineToggled() {
        isStateMachineEnabled = enableSwitch.isOn
        
        if isStateMachineEnabled {
            enableStateMachine()
        } else {
            disableStateMachine()
        }
    }
    
    private func updateStateMachineButtonTitle() {
        let title: String
        if let selectedId = selectedStateMachineId,
           let machine = availableStateMachines.first(where: { $0.id == selectedId }) {
            title = "State Machine: \(machine.name ?? machine.id)"
        } else {
            title = "Select State Machine"
        }
        stateMachineButton.setTitle(title, for: .normal)
        stateMachineButton.isHidden = availableStateMachines.isEmpty
    }
    
    @objc private func selectStateMachineTapped() {
        guard !availableStateMachines.isEmpty else { return }
        
        let alert = UIAlertController(title: "Select State Machine", message: nil, preferredStyle: .actionSheet)
        
        availableStateMachines.forEach { machine in
            alert.addAction(UIAlertAction(title: machine.name ?? machine.id, style: .default, handler: { [weak self] _ in
                self?.selectStateMachine(id: machine.id)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        #if canImport(UIKit)
        alert.popoverPresentationController?.sourceView = stateMachineButton
        alert.popoverPresentationController?.sourceRect = stateMachineButton.bounds
        #endif
        
        present(alert, animated: true)
    }
    
    private func selectStateMachine(id: String) {
        guard availableStateMachines.contains(where: { $0.id == id }) else { return }
        guard selectedStateMachineId != id else { return }
        
        selectedStateMachineId = id
        updateStateMachineButtonTitle()
        
        if isStateMachineEnabled {
            startSelectedStateMachine()
        }
    }
    
    private func enableStateMachine() {
        guard let animation = animation,
              animation.isLoaded() else {
            print("⚠️ Animation not ready")
            return
        }
        
        guard let manifest = animation.manifest(),
              let stateMachines = manifest.stateMachines,
              !stateMachines.isEmpty else {
            print("⚠️ No state machines in manifest")
            return
        }
        
        availableStateMachines = stateMachines
        
        if let selectedStateMachineId,
           !availableStateMachines.contains(where: { $0.id == selectedStateMachineId }) {
            self.selectedStateMachineId = nil
        }
        
        if selectedStateMachineId == nil {
            selectedStateMachineId = availableStateMachines.first?.id
        }
        
        updateStateMachineButtonTitle()
        startSelectedStateMachine()
    }
    
    private func disableStateMachine() {
        guard let animation = animation else { return }
        
        // Stop state machine
        _ = animation.stateMachineStop()
        stateLabel.text = "State: N/A"
        eventsLabel.text = "Events: None"
        inputsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        instructionLabel.isHidden = true
        statePollingTimer?.invalidate()
        
        // Resume normal looping playback
        animation.setLoop(loop: true)
        _ = animation.play()
    }
    
    private func startSelectedStateMachine() {
        guard let animation = animation else { return }
        guard let targetId = selectedStateMachineId ?? availableStateMachines.first?.id else {
            print("⚠️ No state machine selected")
            return
        }
        
        selectedStateMachineId = targetId
        updateStateMachineButtonTitle()
        
        // Stop normal playback and disable loop
        _ = animation.pause()
        animation.setLoop(loop: false)
        _ = animation.stateMachineStop()
        
        let started = animation.stateMachineStart(id: targetId)
        print("State machine '\(targetId)' started: \(started)")
        
        if started {
            let events = animation.stateMachineFrameworkSetup()
            eventsLabel.text = "Events: \(events.joined(separator: ", "))"
            
            let inputs = animation.stateMachineGetInputs()
            updateInputControls(inputs: inputs)
            
            instructionLabel.isHidden = false
            startStatePolling()
        } else {
            eventsLabel.text = "Events: None"
            inputsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            instructionLabel.isHidden = true
            isStateMachineEnabled = false
            enableSwitch.isOn = false
        }
    }
    
    private func updateInputControls(inputs: [String: String]) {
        // Clear existing controls
        inputsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard !inputs.isEmpty else { return }
        
        let headerLabel = UILabel()
        headerLabel.text = "State Machine Inputs:"
        headerLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        inputsStackView.addArrangedSubview(headerLabel)
        
        for (key, type) in inputs.sorted(by: { $0.key < $1.key }) {
            let control = createInputControl(key: key, type: type)
            inputsStackView.addArrangedSubview(control)
        }
    }
    
    private func createInputControl(key: String, type: String) -> UIView {
        switch type.lowercased() {
        case "number", "numeric":
            return createNumericControl(key: key)
        case "boolean", "bool":
            return createBooleanControl(key: key)
        case "string":
            return createStringControl(key: key)
        case "event":
            return createEventControl(key: key)
        default:
            let label = UILabel()
            label.text = "\(key): \(type)"
            label.font = .systemFont(ofSize: 12)
            return label
        }
    }
    
    private func createNumericControl(key: String) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center
        
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.tag = 1001
        
        let stepper = UIStepper()
        stepper.minimumValue = 0
        stepper.maximumValue = 100
        stepper.stepValue = 1
        stepper.value = Double(animation?.stateMachineGetNumericInput(key: key) ?? 0)
        stepper.accessibilityIdentifier = key
        stepper.addTarget(self, action: #selector(numericInputChanged(_:)), for: .valueChanged)
        
        label.text = "\(key): \(String(format: "%.0f", stepper.value))"
        
        container.addArrangedSubview(label)
        container.addArrangedSubview(stepper)
        
        return container
    }
    
    private func createBooleanControl(key: String) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        
        let label = UILabel()
        label.text = key
        label.font = .systemFont(ofSize: 12)
        
        let toggle = UISwitch()
        toggle.isOn = animation?.stateMachineGetBooleanInput(key: key) ?? false
        toggle.addTarget(self, action: #selector(booleanInputChanged(_:)), for: .valueChanged)
        toggle.accessibilityIdentifier = key
        
        container.addArrangedSubview(label)
        container.addArrangedSubview(toggle)
        
        return container
    }
    
    private func createStringControl(key: String) -> UIView {
        let container = UIView()
        
        let label = UILabel()
        label.text = key
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let textField = UITextField()
        textField.text = animation?.stateMachineGetStringInput(key: key) ?? ""
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 12)
        textField.accessibilityIdentifier = key
        textField.addTarget(self, action: #selector(stringInputChanged(_:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(stringInputChanged(_:)), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(stringInputChanged(_:)), for: .editingDidEndOnExit)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        container.addSubview(textField)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func createEventControl(key: String) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(key, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        button.accessibilityIdentifier = key
        button.addTarget(self, action: #selector(eventButtonPressed(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set height constraint
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        
        return button
    }
    
    // Gesture handling is now done automatically by animation.view()
    // No need for manual gesture handlers
    
    @objc private func numericInputChanged(_ stepper: UIStepper) {
        guard let key = stepper.accessibilityIdentifier else { return }
        let value = Float(stepper.value)
        _ = animation?.stateMachineSetNumericInput(key: key, value: value)
        
        if let stack = stepper.superview as? UIStackView,
           let label = stack.arrangedSubviews.first(where: { $0.tag == 1001 }) as? UILabel {
            label.text = "\(key): \(String(format: "%.0f", stepper.value))"
        }
    }
    
    @objc private func booleanInputChanged(_ toggle: UISwitch) {
        guard let key = toggle.accessibilityIdentifier else { return }
        _ = animation?.stateMachineSetBooleanInput(key: key, value: toggle.isOn)
    }
    
    @objc private func stringInputChanged(_ textField: UITextField) {
        guard let key = textField.accessibilityIdentifier, let text = textField.text else {
            print("⚠️ String input changed but missing key or text")
            return
        }
        print("📝 String input changed: \(key) = '\(text)'")
        let success = animation?.stateMachineSetStringInput(key: key, value: text) ?? false
        print("  → Set result: \(success)")
    }
    
    @objc private func eventButtonPressed(_ button: UIButton) {
        guard let key = button.accessibilityIdentifier else {
            print("⚠️ Event button pressed but missing key")
            return
        }
        print("🔘 Event button pressed: \(key)")
        
        animation?.stateMachineFire(event: key)
        
        // Visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
    }
    
    private func startStatePolling() {
        statePollingTimer?.invalidate()
        statePollingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.updateState()
            // Don't automatically poll input values - only update when user changes them
            // self?.updateInputControls()
        }
    }
    
    private func updateState() {
        guard let animation = animation else { return }
        let state = animation.stateMachineCurrentState()
        stateLabel.text = "State: \(state)"
    }
    
    private func updateInputControls() {
        guard let animation = animation else { return }
        
        for view in inputsStackView.arrangedSubviews {
            // Update numeric steppers
            if let stepper = view.subviews.first(where: { $0 is UIStepper }) as? UIStepper,
               let key = stepper.accessibilityIdentifier {
                let currentValue = Double(animation.stateMachineGetNumericInput(key: key))
                if abs(stepper.value - currentValue) > 0.01 {
                    stepper.value = currentValue
                    if let label = view.viewWithTag(1001) as? UILabel {
                        label.text = "\(key): \(String(format: "%.0f", currentValue))"
                    }
                }
            }
 
            // Update boolean toggles
            if let stackView = view as? UIStackView,
               let toggle = stackView.arrangedSubviews.first(where: { $0 is UISwitch }) as? UISwitch,
               let key = toggle.accessibilityIdentifier {
                let currentValue = animation.stateMachineGetBooleanInput(key: key)
                // Only update if different
                if toggle.isOn != currentValue {
                    toggle.isOn = currentValue
                }
            }

            // Update string text fields
            if let textField = view.subviews.first(where: { $0 is UITextField }) as? UITextField,
               let key = textField.accessibilityIdentifier {
                // Only update if not currently editing
                if !textField.isFirstResponder {
                    let currentValue = animation.stateMachineGetStringInput(key: key)
                    if textField.text != currentValue {
                        textField.text = currentValue
                    }
                }
            }
            
            // Event inputs are buttons - no need to update them from animation
        }
    }
    
    deinit {
        statePollingTimer?.invalidate()
    }
}

// MARK: - UIPickerView Delegate & DataSource

extension UIKitStateMachineViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        examples.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        "\(examples[row].0) - \(examples[row].1)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard row != selectedExampleIndex else { return }
        selectedExampleIndex = row
        
        // Disable state machine
        if isStateMachineEnabled {
            enableSwitch.isOn = false
            disableStateMachine()
        }
        
        // Setup new animation
        setupAnimation(example: examples[row])
    }
}

#endif

