//
//  AnimationModel.swift
//
//
//  Created by Sam on 30/10/2023.
//

import Foundation
import CoreImage

public enum PlayerState {
    case playing
    case paused
    case initial
    case loaded
    case stopped
    case frozen
    case error
    case draw
    case complete
    case stateMachineIsActive
}

public struct AnimationModel {
    public var width: Int = 512
    
    public var height: Int = 512

    public var error: Bool = false
    
    public var errorMessage: String = ""
    
    public var backgroundColor: CIImage = CIImage.clear
}
