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
    
    internal var baseUrl: String {
        self == .uat ? Constants.mirrorBaseUrlUat : Constants.mirrorBaseUrlProd
    }
    
    internal var pingUrl: String {
        baseUrl + "/ping"
    }
    
    internal var clickUrl: String {
        baseUrl + "/ping"
    }
}
