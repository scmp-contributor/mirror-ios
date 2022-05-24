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
                clickInfo: String? = nil) {
        self.path = path
        self.section = section
        self.authors = authors
        self.pageTitle = pageTitle
        self.clickInfo = clickInfo
    }
    /// - Parameter p: The clean URL path without query strings. (Usually from canonical URL)
    private (set) var path: String
    /// - Parameter s: The page section of the article
    private (set) var section: String? = nil
    /// - Parameter a: The page authors of the article
    private (set) var authors: String? = nil
    /// - Parameter pt: The page title
    private (set) var pageTitle: String? = nil
    /// - Parameter pi: The page session ID for correlating browsing behaviors under a single page. Generated on client side and store locally. 21 chars length by NanoID.
    public let pageID: String = NanoID.new()
    /// - Parameter ci: The metadata of click event
    public let clickInfo: String? = nil
}
