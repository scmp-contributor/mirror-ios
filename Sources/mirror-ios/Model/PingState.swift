//
//  PingState.swift
//  
//
//  Created by Terry Lee on 2022/5/24.
//

import Foundation

public enum PingState {
    case active
    case inactive
    case background
    
    public var intervals: [Int] {
        switch self {
        case .active:
            return [15]
        case .inactive:
            return [15, 30, 45, 75, 135, 255]
        case .background:
            return [30, 45, 75, 165, 1005]
        }
    }
}
