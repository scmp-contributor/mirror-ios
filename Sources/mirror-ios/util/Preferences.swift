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
    
    private let mirrorUuidKey = "mirror_user_uuid"
    
    var uuid: String {
        get {
            if let uuid = UserDefaults.standard.string(forKey: mirrorUuidKey) {
                return uuid
            } else {
                let uuid = NanoID.new()
                self.uuid = uuid
                return uuid
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: mirrorUuidKey)
        }
    }
}
