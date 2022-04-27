//
//  VisitorType.swift
//
//
//  Created by Terry Lee on 2022/4/21.
//

import Foundation
import Alamofire
import RxSwift
import RxCocoa
import RxOptional
import RxAlamofire

public class Mirror: Encodable {
    
    let environment: Environment
    
    // MARK: - Mirror SDK Parameters
    /// - Parameter k: The unique organization ID (uuid) from Mirror service. Each organization can hold multiple domains. Please get this value from Mirror team.
    let organizationID: String
    /// - Parameter d: The domain address that we implement the tracking. (Usually from canonical URL)
    let domainAddress: String
    /// - Parameter p: The clean URL path without query strings. (Usually from canonical URL)
    var urlAlias: String? = nil
    /// - Parameter u: The unique ID for each visitor, generated on client side and store locally. 21 chars length by NanoID.
    let visitorID: String = Preferences.sharedInstance.visitorID
    /// - Parameter vt: The visitor type.
    let visitorType: VisitorType
    /// - Parameter eg: The visitor engaged time on the page in seconds.
    var visitorEngagedTime: Int? = nil
    /// - Parameter sq: Sequence number of ping events within same session
    var sequenceNumber: Int? = nil
    /// - Parameter s: The page section of the article
    var articleSection: String? = nil
    /// - Parameter a: The page authors of the article
    var articleAuthors: String? = nil
    /// - Parameter pt: The page title
    var pageTitle: String? = nil
    /// - Parameter ir: The page referrer from same domain
    var referrerFromSameDomain: String? = nil
    /// - Parameter er: The page referrer from other domain
    var referrerFromOtherDomain: String? = nil
    /// - Parameter y1: The page document height or scroll element height in pixels.
    var y1: Int? = nil
    /// - Parameter y2: The page document logical height or window available height in pixels.
    var y2: Int? = nil
    /// - Parameter et: The interation event type.
    var eventType: EventType = .ping
    /// - Parameter nc: The flag to indicate if visitor accepts tracking
    let trackingFlag: TrackingFlag = .true
    /// - Parameter ci: The metadata of click event
    var metadata: String? = nil
    /// - Parameter ff: The additional duration added to the event to extend the page browing session
    var ff: Int? = nil
    /// - Parameter v: Agent version
    var agentVersion: String? = nil
    
    // MARK: - Constants & Variables
    private var hasNecessaryParameter: Bool {
        organizationID.isNotEmpty &&
        domainAddress.isNotEmpty &&
        (urlAlias != nil) && (urlAlias?.isNotEmpty ?? false) &&
        visitorID.isNotEmpty &&
        visitorType.rawValue.isNotEmpty &&
        eventType.rawValue.isNotEmpty &&
        trackingFlag.rawValue.isNotEmpty
    }
    
    private let disposeBag = DisposeBag()
    
    private var timerObserver: Disposable?
    
    // MARK: - init
    public init(environment: Environment, organizationID: String = "1", domainAddress: String = "scmp.com", visitorType: VisitorType) {
        self.environment = environment
        self.organizationID = organizationID
        self.domainAddress = domainAddress
        self.visitorType = visitorType
    }
    
    // MARK: - Standard Pings
    public func startPing(urlAlias: String,
                          visitorEngagedTime: Int? = nil,
                          articleSection: String? = nil,
                          articleAuthors: String? = nil,
                          pageTitle: String? = nil,
                          referrerFromSameDomain: String? = nil,
                          referrerFromOtherDomain: String? = nil,
                          y1: Int? = nil,
                          y2: Int? = nil,
                          metadata: String? = nil,
                          ff: Int? = nil,
                          agentVersion: String? = nil) {
        
        self.urlAlias = urlAlias
        self.visitorEngagedTime = visitorEngagedTime
        self.articleSection = articleSection
        self.articleAuthors = articleAuthors
        self.pageTitle = pageTitle
        self.referrerFromSameDomain = referrerFromSameDomain
        self.referrerFromOtherDomain = referrerFromOtherDomain
        self.y1 = y1
        self.y2 = y2
        self.metadata = metadata
        self.ff = ff
        self.agentVersion = agentVersion
        
        guard hasNecessaryParameter else {
            logger.debug("[Track-Mirror] ping falied, some necessary parameters missing")
            return
        }
        let period = 15
        timerObserver = Observable<Int>.timer(.seconds(0), period: .seconds(period), scheduler: MainScheduler.instance)
            .flatMap { [weak self] times -> Observable<HTTPURLResponse> in
                guard let self = self else { return .empty() }
                let times = times + 1
                self.sequenceNumber = times
                logger.debug("[Track-Mirror] send ping parameters: \(self.parameters)")
                return RxAlamofire.requestResponse(.get, self.environment.pingUrl, parameters: self.parameters)
            }
            .subscribe(onNext: { response in
                logger.debug("[Track-Mirror] ping success, response: \(response.statusCode)")
            }, onError: {
                logger.debug("[Track-Mirror] ping failed, error: \($0)")
            })
    }
    
    public func stopPing() {
        timerObserver?.dispose()
        logger.debug("[Track-Mirror] stop ping")
    }
}

// MARK: - encode
extension Mirror {
    
    var parameters: [String: Any] {
      (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self)) as? [String: Any]) ?? [:]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(organizationID, forKey: .k)
        try container.encode(domainAddress, forKey: .d)
        if let urlAlias = urlAlias {
            try container.encode(urlAlias.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), forKey: .p)
        }
        try container.encode(visitorID, forKey: .u)
        try container.encode(visitorType.rawValue, forKey: .vt)
        try container.encode(eventType.rawValue, forKey: .et)
        try container.encode(trackingFlag.rawValue, forKey: .nc)
        
        if let visitorEngagedTime = visitorEngagedTime {
            try container.encode(visitorEngagedTime, forKey: .eg)
        }
        
        if let sequenceNumber = sequenceNumber {
            try container.encode(sequenceNumber, forKey: .sq)
        }
        
        if let articleSection = articleSection {
            try container.encode(articleSection, forKey: .s)
        }
        
        if let articleAuthors = articleAuthors {
            try container.encode(articleAuthors, forKey: .a)
        }
        
        if let pageTitle = pageTitle, sequenceNumber == 1 {
            try container.encode(pageTitle, forKey: .pt)
        }
        
        if let referrerFromSameDomain = referrerFromSameDomain {
            try container.encode(referrerFromSameDomain, forKey: .ir)
        }
        
        if let referrerFromOtherDomain = referrerFromOtherDomain {
            try container.encode(referrerFromOtherDomain, forKey: .er)
        }
        
        if let y1 = y1 {
            try container.encode(y1, forKey: .y1)
        }
        
        if let y2 = y2 {
            try container.encode(y2, forKey: .y2)
        }
        
        if let metadata = metadata {
            try container.encode(metadata, forKey: .ci)
        }
        
        if let ff = ff {
            try container.encode(ff, forKey: .ff)
        }
        
        if let agentVersion = agentVersion {
            try container.encode(agentVersion, forKey: .v)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case k
        case d
        case p
        case u
        case vt
        case eg
        case sq
        case s
        case a
        case pt
        case pi
        case ir
        case er
        case y1
        case y2
        case et
        case nc
        case ci
        case ff
        case xe
        case v
    }
}
