//
//  LogUtils.swift
//  
//
//  Created by Terry Lee on 2022/4/25.
//

import Foundation
import SwiftyBeaver

internal let mirrorLog: SwiftyBeaver.Type = {
    
    let sbLogger = SwiftyBeaver.self
    
    #if DEBUG
    if sbLogger.destinations.isEmpty {
        let console = ConsoleDestination()
        console.useNSLog = true
        console.minLevel = .debug
        sbLogger.addDestination(console) // add to SwiftyBeaver
    }
    #endif
    
    return sbLogger
}()
