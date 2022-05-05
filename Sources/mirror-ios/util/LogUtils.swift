//
//  LogUtils.swift
//  
//
//  Created by Terry Lee on 2022/4/25.
//

import Foundation
import SwiftyBeaver

internal let logger: SwiftyBeaver.Type = {
  
  let sbLogger = SwiftyBeaver.self
  
  #if DEBUG
    let console = ConsoleDestination()
    console.useNSLog = true
    console.minLevel = .debug // just log .Info, .Warning & .Error
    sbLogger.addDestination(console) // add to SwiftyBeaver
  #endif
  
  return sbLogger
}()
