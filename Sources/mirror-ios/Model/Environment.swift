//
//  Environment.swift
//  
//
//  Created by Terry Lee on 2022/4/22.
//

import Foundation

public enum Environment {
    case uat
    case prod
    
    internal var apiUrl: String {
        let environment = self == .uat ? "uat-" : ""
        return "https://\(environment)mirror.i-scmp.com"
    }
    
    internal var pingUrl: String {
        apiUrl + "/ping"
    }
    
    internal var clickUrl: String {
        apiUrl + "/ping"
    }
}
