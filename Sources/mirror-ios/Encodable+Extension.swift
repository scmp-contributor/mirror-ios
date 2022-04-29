//
//  Encodable+Extension.swift
//  
//
//  Created by Terry Lee on 2022/4/29.
//

import Foundation

extension Encodable {
    func asDictionary() -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self)) as? [String: Any]) ?? [:]
    }
}
