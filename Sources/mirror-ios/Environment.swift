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
    
    var apiUrl: String {
        let environment = self == .uat ? "uat-" : ""
        return "https://\(environment)mirror.i-scmp.com"
    }
    
    public var pingUrl: String {
        var apiUrl = apiUrl
        apiUrl.append(contentsOf: "/ping")
        return apiUrl
    }
    
    public var clickUrl: String {
        var apiUrl = apiUrl
        apiUrl.append(contentsOf: "/click")
        return apiUrl
    }
}
