//
//  Constants.swift
//  
//
//  Created by Terry Lee on 2022/5/12.
//

import UIKit

struct Constants {
    static let mirrorBaseUrlProd = "https://mirror.i-scmp.com"
    static let mirrorBaseUrlUat = "https://uat-mirror.i-scmp.com"
    
    static var userAgent: String {
        UIDevice.current.userInterfaceIdiom == .phone ? "native-mobile-ios" : "native-tablet-ios"
    }
    
    static let maximumPingInterval = 1005
    
    // Agent version, for iOS "mi-x.x.x", for android "ma-x.x.x"
    static let agentVersion: String = "mi-0.0.23"
}
