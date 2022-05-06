//
//  EventType.swift
//  
//
//  Created by Terry Lee on 2022/4/22.
//

import Foundation

public enum EventType: String {
    /// ping: to indicate the current user is active
    case ping
    /// click: to indicate a link was clicked
    case click
    
    internal func getUrl(_ environment: Environment) -> String {
        switch self {
        case .ping:
            return environment.pingUrl
        case .click:
            return environment.clickUrl
        }
    }
}
