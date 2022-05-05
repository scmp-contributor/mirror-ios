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
                pageTitle: String? = nil,
                internalReferrer: String? = nil,
                externalReferrer: String? = nil) {
        self.path = path
        self.section = section
        self.authors = authors
        self.pageTitle = pageTitle
        self.internalReferrer = internalReferrer
        self.externalReferrer = externalReferrer
    }
    /// - Parameter p: The clean URL path without query strings. (Usually from canonical URL)
    public var path: String
    /// - Parameter s: The page section of the article
    public var section: String? = nil
    /// - Parameter a: The page authors of the article
    public var authors: String? = nil
    /// - Parameter pt: The page title
    public var pageTitle: String? = nil
    /// - Parameter ir: The page referrer from same domain
    public var internalReferrer: String? = nil
    /// - Parameter er: The page referrer from other domain
    public var externalReferrer: String? = nil
}
