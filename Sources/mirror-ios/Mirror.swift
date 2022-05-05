//
//  VisitorType.swift
//
//
//  Created by Terry Lee on 2022/4/21.
//

import Foundation
import RxSwift
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
    let scheduler: SchedulerType
    let disposeBag = DisposeBag()
    let maximumPingInterval = 1005
    var engageTimer: Disposable?
    var standardPingsTimer: Disposable?
    var lastPingData: TrackData?
    
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
    
    // MARK: - Update Visitor Type
    public func updateVisitorType(_ visitorType: VisitorType) {
        self.visitorType = visitorType
    }
    
    // MARK: - Send Mirror Event
    func sendMirror(eventType: EventType, parameters: [String: Any]) -> Observable<HTTPURLResponse> {
        let url = eventType.getUrl(environment)
        return RxAlamofire.requestResponse(.get, url, parameters: parameters)
    }
    
    // MARK: - Ping
    
    /// - Parameter data: The TrackData for mirror parameters
    public func ping(data: TrackData) {
        sendPing(data: data)
    }
    
    func sendPing(data: TrackData, isForcePings: Bool = false) {
        
        if !isForcePings {
            guard standardPingsTimer == nil else { return }
            sequenceNumber = 1
            engagedTime = 0
            engageTimer = engageTimerObservable(period: 1).subscribe()
            standardPingsTimer = standardPingsTimerObservable(startSeconds: 15, period: 15, data: data).subscribe()
            observeEnterBackground().subscribe().disposed(by: disposeBag)
            observeEnterForeground().subscribe().disposed(by: disposeBag)
        }
        
        let parameters = getParameters(eventType: .ping, data: data)
        
        sendMirror(eventType: .ping, parameters: parameters)
            .subscribe(onNext: { [weak self] response in
                let pingStr = isForcePings ? "force pings" : "standard ping"
                logger.debug("[Track-Mirror] \(pingStr) success, parameters: \(parameters), response: \(response.statusCode)")
                self?.lastPingData = data
            }).disposed(by: disposeBag)
    }
    
    // Timer for engage time
    func engageTimerObservable(period: Int) -> Observable<Int> {
        Observable<Int>.interval(.seconds(period), scheduler: scheduler)
            .take(until: { [weak self] _ in
                guard let self = self else { return true }
                return self.engagedTime >= self.maximumPingInterval
            }).do(onNext: { [weak self] _ in
                self?.engagedTime += 1
            }, onCompleted: { [weak self] in
                self?.stopStandardPings()
            })
    }
    
    // Timer for standard pings
    func standardPingsTimerObservable(startSeconds: Int, period: Int, data: TrackData) -> Observable<Int> {
        Observable<Int>.timer(.seconds(startSeconds), period: .seconds(period), scheduler: scheduler)
            .do(onNext: { [weak self] _ in
                self?.sequenceNumber += 1
                self?.sendPing(data: data, isForcePings: true)
            })
    }
    
    // observable for enter background
    func observeEnterBackground() -> Observable<Notification> {
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.stopStandardPings()
            })
    }
    
    // observable for enter foreground
    func observeEnterForeground() -> Observable<Notification> {
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .do(onNext: { [weak self] _ in
                guard let self = self, let lastPingData = self.lastPingData else { return }
                self.sendPing(data: lastPingData, isForcePings: true)
                guard self.engagedTime < self.maximumPingInterval else { return }
                self.engageTimer = self.engageTimerObservable(period: 1).subscribe()
                self.standardPingsTimer = self.standardPingsTimerObservable(startSeconds: 15, period: 15, data: lastPingData).subscribe()
            })
    }
    
    // stop ping
    public func stopPing() {
        stopStandardPings(resetData: true)
    }
    
    func stopStandardPings(resetData: Bool = false) {
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
    
    /// - Parameter data: The TrackData for mirror parameters
    public func click(data: TrackData) {
        let parameters = getParameters(eventType: .click, data: data)
        
        sendMirror(eventType: .click, parameters: parameters)
            .subscribe(onNext: { response in
                logger.debug("[Track-Mirror] click success, parameters: \(parameters), response: \(response.statusCode)")
            }).disposed(by: disposeBag)
    }
}

extension Mirror {
    func getParameters(eventType: EventType, data: TrackData) -> [String: Any] {
        
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
