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
import RxRelay
import RxOptional
import RxAlamofire
import UIKit

public class Mirror {
    
    let environment: Environment
    
    // MARK: - Mirror SDK Parameters
    /// - Parameter k: The unique organization ID (uuid) from Mirror service. Each organization can hold multiple domains. Please get this value from Mirror team.
    let organizationID: String
    /// - Parameter d: The domain address that we implement the tracking. (Usually from canonical URL)
    let domain: String
    /// - Parameter u: The unique ID for each visitor, generated on client side and store locally. 21 chars length by NanoID.
    let visitorID: String = Preferences.sharedInstance.visitorID
    /// - Parameter vt: The visitor type.
    var visitorType: VisitorType
    /// - Parameter eg: The visitor engaged time on the page in seconds.
    var engagedTime = 0
    /// - Parameter sq: Sequence number of ping events within same session
    var sequenceNumber: Int = 1
    /// - Parameter nc: The flag to indicate if visitor accepts tracking
    let trackingFlag: TrackingFlag = .true
    /// - Parameter v: Agent version
    let agentVersion: String = "0.0.1"
    
    // MARK: - Constants & Variables
    internal let maximumPingInterval = 1005
    
    internal let scheduler: SchedulerType
    
    internal let disposeBag = DisposeBag()
    
    internal var engageTimer: Disposable?
    internal var standardPingsTimer: Disposable?
    
    internal let enterForgroundObservable = NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
    internal let enterBackgroundObservable = NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
    
    internal var lastPingData: TrackData?
    
    // MARK: - init
    public init(environment: Environment = .prod,
                organizationID: String = "1",
                domain: String = "scmp.com",
                visitorType: VisitorType = .guest,
                scheduler: SchedulerType = SerialDispatchQueueScheduler(qos: .default)) {
        self.environment = environment
        self.organizationID = organizationID
        self.domain = domain
        self.visitorType = visitorType
        self.scheduler = scheduler
    }
    
    // MARK: - Ping
    internal func sendMirror(eventType: EventType, parameters: [String: Any]) -> Observable<HTTPURLResponse> {
        let url = eventType.getUrl(environment)
        return RxAlamofire.requestResponse(.get, url, parameters: parameters)
    }
    
    // MARK: - Standard Pings
    public func ping(data: TrackData, isForcePings: Bool = false) {
        
        if !isForcePings {
            guard standardPingsTimer == nil else { return }
            sequenceNumber = 1
            engagedTime = 0
            engageTimer = engageTimerDisposable()
            standardPingsTimer = standardPingsTimerDisposable(startSeconds: 15, period: 15, data: data)
            observeEnterBackground()
            observeEnterForeground()
        }
        
        let parameters = getParameters(eventType: .ping, data: data)
        
        sendMirror(eventType: .ping, parameters: parameters)
            .subscribe(onNext: { [weak self] response in
                let pingStr = isForcePings ? "force pings" : "standard ping"
                logger.debug("[Track-Mirror] \(pingStr) success, parameters: \(parameters), response: \(response.statusCode)")
                self?.lastPingData = data
            }).disposed(by: disposeBag)
    }
    
    internal func engageTimerDisposable() -> Disposable {
        Observable<Int>.interval(.seconds(1), scheduler: scheduler)
            .take(until: { [weak self] _ in
                guard let self = self else { return true }
                return self.engagedTime >= self.maximumPingInterval
            })
            .subscribe(onNext: { [weak self] _ in
                self?.engagedTime += 1
            }, onCompleted: { [weak self] in
                self?.stopStandardPings()
            })
    }
    
    internal func standardPingsTimerDisposable(startSeconds: Int, period: Int, data: TrackData) -> Disposable {
        Observable<Int>.timer(.seconds(startSeconds), period: .seconds(period), scheduler: scheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.sequenceNumber += 1
                self?.ping(data: data, isForcePings: true)
            })
    }
    
    internal func observeEnterBackground() {
        enterBackgroundObservable.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.stopStandardPings()
        }).disposed(by: disposeBag)
    }
    
    internal func observeEnterForeground() {
        enterForgroundObservable.subscribe(onNext: { [weak self] _ in
            guard let self = self, let lastPingData = self.lastPingData else { return }
            self.ping(data: lastPingData, isForcePings: true)
            guard self.engagedTime < self.maximumPingInterval else { return }
            self.engageTimer = self.engageTimerDisposable()
            self.standardPingsTimer = self.standardPingsTimerDisposable(startSeconds: 15, period: 15, data: lastPingData)
        }).disposed(by: disposeBag)
    }
    
    public func stopStandardPings(resetData: Bool = false) {
        guard standardPingsTimer != nil || engageTimer != nil else { return }
        standardPingsTimer?.dispose()
        standardPingsTimer = nil
        engageTimer?.dispose()
        engageTimer = nil
        logger.debug("[Track-Mirror] stop ping success")
        if resetData {
            lastPingData = nil
        }
    }
    
    // MARK: - Click
    public func click(data: TrackData) {
        let parameters = getParameters(eventType: .click, data: data)
        
        sendMirror(eventType: .click, parameters: parameters)
            .subscribe(onNext: { response in
                logger.debug("[Track-Mirror] click success, parameters: \(parameters), response: \(response.statusCode)")
            }).disposed(by: disposeBag)
    }
}

extension Mirror {
    public func getParameters(eventType: EventType, data: TrackData) -> [String: Any] {
        
        var dictionary: [String: Any] = [:]
        
        dictionary["k"] = organizationID
        dictionary["d"] = domain
        dictionary["p"] = data.path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        dictionary["u"] = visitorID
        dictionary["vt"] = visitorType.rawValue
        dictionary["et"] = eventType.rawValue
        dictionary["nc"] = trackingFlag.rawValue
        dictionary["eg"] = engagedTime
        dictionary["sq"] = sequenceNumber
        
        if let section = data.section {
            dictionary["s"] = section
        }
        
        if let authors = data.authors {
            dictionary["a"] = authors
        }
        
        if let pageTitle = data.pageTitle, sequenceNumber == 1 {
            dictionary["pt"] = pageTitle
        }
        
        if let internalReferrer = data.internalReferrer {
            dictionary["ir"] = internalReferrer
        }
        
        if let externalReferrer = data.externalReferrer {
            dictionary["er"] = externalReferrer
        }
        dictionary["v"] = agentVersion
        
        return dictionary
    }
}
