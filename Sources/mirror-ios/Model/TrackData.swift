//
//  TrackData.swift
//  
//
//  Created by Terry Lee on 2022/5/4.
//

import Foundation

public struct TrackData: Equatable {
    
    public init(path: String,
                section: String? = nil,
                authors: String? = nil,
                pageTitle: String? = nil,
                pageID: String? = nil,
                clickInfo: String? = nil) {
        self.path = path
        self.section = section
        self.authors = authors
        self.pageTitle = pageTitle
        self.pageID = pageID ?? NanoID.new()
        self.clickInfo = clickInfo
    }
    /// - Parameter p: The clean URL path without query strings. (Usually from canonical URL)
    public private (set) var path: String
    /// - Parameter s: The page section of the article
    public private (set) var section: String? = nil
    /// - Parameter a: The page authors of the article
    public private (set) var authors: String? = nil
    /// - Parameter pt: The page title
    public private (set) var pageTitle: String? = nil
    /// - Parameter pi: The page session ID for correlating browsing behaviors under a single page. Generated on client side and store locally. 21 chars length by NanoID.
    public private (set) var pageID: String
    /// - Parameter ci: The metadata of click event
    public private (set) var clickInfo: String? = nil
    
    public func isEqualExcluePageIDTo(_ other: TrackData?) -> Bool {
        path == other?.path &&
        section == other?.section &&
        authors == other?.authors &&
        pageTitle == other?.pageTitle &&
        clickInfo == other?.clickInfo
    }
}
