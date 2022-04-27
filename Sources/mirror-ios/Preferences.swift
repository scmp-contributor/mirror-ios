//
//  Preferences.swift
//  
//
//  Created by Terry Lee on 2022/4/22.
//

import Foundation

class Preferences {
    
    init() { }
    
    static let sharedInstance: Preferences = Preferences()
    
    private let defaults = UserDefaults.standard
    
    private let visitorIDKey = "mirror_visitorID"
    
    var visitorID: String {
        get {
            if let visitorID = UserDefaults.standard.string(forKey: visitorIDKey) {
                return visitorID
            } else {
                let visitorID = NanoID.new()
                self.visitorID = visitorID
                return visitorID
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: visitorIDKey)
        }
    }
}
