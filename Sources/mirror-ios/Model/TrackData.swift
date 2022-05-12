//
//  TrackData.swift
//  
//
//  Created by Terry Lee on 2022/5/4.
//

import Foundation

public struct TrackData {
    
    public init(path: String,
                section: String? = nil,
                authors: String? = nil,
                pageTitle: String? = nil) {
        self.path = path
        self.section = section
        self.authors = authors
        self.pageTitle = pageTitle
    }
    /// - Parameter p: The clean URL path without query strings. (Usually from canonical URL)
    public var path: String
    /// - Parameter s: The page section of the article
    public var section: String? = nil
    /// - Parameter a: The page authors of the article
    public var authors: String? = nil
    /// - Parameter pt: The page title
    public var pageTitle: String? = nil
}
