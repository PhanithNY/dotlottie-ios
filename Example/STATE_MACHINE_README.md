# State Machine Examples

This document describes the state machine functionality added to `DotLottiePlayerUIView` and the test app examples.

## State Machine Support in DotLottiePlayerUIView

### Loading State Machines

```swift
// Load state machine from JSON data
playerView.stateMachineLoadData(jsonString)

// Load state machine by ID
playerView.stateMachineLoad(id: "my-state-machine")
```

### Controlling State Machines

```swift
// Start the state machine
playerView.stateMachineStart()

// Stop the state machine
playerView.stateMachineStop()
```

### Interaction Methods

#### Pointer Events
```swift
// Post click event at a point
playerView.stateMachinePostClickEvent(at: CGPoint(x: 100, y: 100))

// Post pointer down
playerView.stateMachinePostPointerDownEvent(at: point)

// Post pointer move
playerView.stateMachinePostPointerMoveEvent(at: point)

// Post pointer up
playerView.stateMachinePostPointerUpEvent(at: point)

// Post pointer enter/exit
playerView.stateMachinePostPointerEnterEvent(at: point)
playerView.stateMachinePostPointerExitEvent(at: point)
```

#### Custom Events
```swift
// Post a specific event
playerView.stateMachinePostEvent(.click(x: 100, y: 100))
playerView.stateMachinePostEvent(.onComplete)
```

### State Machine Inputs

#### Setting Inputs
```swift
// Set numeric input (e.g., slider value)
playerView.stateMachineSetNumericInput(key: "slider", value: 50.0)

// Set boolean input (e.g., toggle state)
playerView.stateMachineSetBooleanInput(key: "enabled", value: true)

// Set string input
playerView.stateMachineSetStringInput(key: "mode", value: "active")
```

#### Getting Inputs
```swift
// Get current input value
let sliderValue = playerView.stateMachineGetNumericInput(key: "slider")
let isEnabled = playerView.stateMachineGetBooleanInput(key: "enabled")
let mode = playerView.stateMachineGetStringInput(key: "mode")

// Get all inputs and their types
let inputs: [String: String] = playerView.stateMachineGetInputs()
// Example: ["slider": "Number", "enabled": "Boolean", "mode": "String"]
```

### State Machine Information

```swift
// Get current state
let currentState = playerView.stateMachineCurrentState()

// Get available events/listeners
let events = playerView.stateMachineFrameworkSetup()
```

### Observing State Machine Events

```swift
class MyStateMachineObserver: StateMachineObserver {
    func onStateEntered(enteringState: String) {
        print("Entered state: \(enteringState)")
    }
    
    func onStateExit(leavingState: String) {
        print("Exiting state: \(leavingState)")
    }
    
    func onTransition(previousState: String, newState: String) {
        print("Transition: \(previousState) -> \(newState)")
    }
    
    // ... other methods
}

let observer = MyStateMachineObserver()
playerView.stateMachineSubscribe(observer)
```

## Example 7: State Machine & Interactivity

### Features

The state machine example demonstrates:

1. **Multiple State Machine Demos**
   - Click Button: Click to trigger state transitions
   - Toggle: Toggle between on/off states
   - Smiley Slider: Slider interaction changes expression
   - Sync to Cursor: Animation follows cursor movement

2. **Enable/Disable Toggle**
   - Turn state machine on/off dynamically
   - Animation works normally when disabled

3. **Live State Display**
   - Shows current state machine state
   - Updates in real-time (10Hz polling)
   - Shows available events

4. **Dynamic Input Controls**
   - Automatically generates UI for state machine inputs
   - Supports:
     - **Numeric inputs**: Sliders (0-100)
     - **Boolean inputs**: Toggles
     - **String inputs**: Text fields

5. **Touch Interaction**
   - Tap gesture → Click event
   - Pan gesture → Pointer down/move/up events
   - Real-time interaction with animation

### UIKit Example

```swift
let playerView = DotLottiePlayerUIView(name: "click-button", config: config)

// Load state machine
if let data = loadStateMachineJSON() {
    playerView.stateMachineLoadData(data)
    playerView.stateMachineStart()
}

// Handle tap
@objc func handleTap(_ gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: playerView)
    playerView.stateMachinePostClickEvent(at: location)
}
```

### SwiftUI Example

```swift
@StateObject var viewModel = StateMachineViewModel()

var body: some View {
    DotLottiePlayerViewWrapper(playerView: viewModel.playerView)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { gesture in
                    viewModel.handleClick(at: gesture.location)
                }
        )
}
```

## State Machine File Format

State machine files are JSON files (e.g., `sm-click-button.json`) that define:
- States and transitions
- Event listeners (click, pointerMove, etc.)
- Input variables
- Animation behaviors

Place state machine JSON files in your bundle and load them:

```swift
if let url = Bundle.main.url(forResource: "sm-click-button", withExtension: "json"),
   let data = try? String(contentsOf: url) {
    playerView.stateMachineLoadData(data)
    playerView.stateMachineStart()
}
```

## Memory Management

State machines are automatically cleaned up when:
- Calling `stateMachineStop()`
- Changing animations
- View is deallocated

Always stop state machines before changing animations:

```swift
_ = playerView.stateMachineStop()
playerView.dotLottieAnimation = newAnimation
```

## Best Practices

1. **Load state machines after animation loads**
   ```swift
   playerView = DotLottiePlayerUIView(name: "animation") { view, error in
       if error == nil {
           self.loadAndStartStateMachine()
       }
   }
   ```

2. **Poll for state updates**
   ```swift
   Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
       let state = playerView.stateMachineCurrentState()
       updateUI(state: state)
   }
   ```

3. **Handle inputs dynamically**
   ```swift
   let inputs = playerView.stateMachineGetInputs()
   for (key, type) in inputs {
       createControl(for: key, type: type)
   }
   ```

4. **Clean up when done**
   ```swift
   deinit {
       _ = playerView.stateMachineStop()
       statePollingTimer?.invalidate()
   }
   ```

