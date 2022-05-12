//
//  VisitorType.swift
//
//
//  Created by Terry Lee on 2022/4/21.
//

import Foundation
import RxSwift
import RxCocoa
import RxAlamofire
import UIKit

public class Mirror {
    
    internal var environment: Environment
    
    // MARK: - Mirror SDK Parameters
    /// - Parameter k: The unique organization ID (uuid) from Mirror service. Each organization can hold multiple domains. Please get this value from Mirror team.
    internal let organizationID: String
    /// - Parameter d: The domain address that we implement the tracking. (Usually from canonical URL)
    internal var domain: String
    /// - Parameter u: The unique ID for each visitor, generated on client side and store locally. 21 chars length by NanoID.
    internal let uuid: String = Preferences.sharedInstance.uuid
    /// - Parameter vt: The visitor type.
    internal var visitorType: VisitorType
    /// - Parameter eg: The visitor engaged time on the page in seconds.
    internal var engagedTime = 0
    /// - Parameter sq: Sequence number of ping events within same session
    internal var sequenceNumber: Int = 1
    /// - Parameter nc: The flag to indicate if visitor accepts tracking
    internal let trackingFlag: TrackingFlag = .true
    /// - Parameter v: Agent version
    internal let agentVersion: String = "mi-0.0.1"
    
    // MARK: - Constants & Variables
    internal let scheduler: SchedulerType
    internal let disposeBag = DisposeBag()
    internal let maximumPingInterval = 1005
    internal var engageTimer: Disposable?
    internal var standardPingsTimer: Disposable?
    internal var lastPingData: TrackData?
    
    // MARK: - init
    public init(environment: Environment = .prod,
                organizationID: String = "1",
                domain: String,
                visitorType: VisitorType = .guest,
                scheduler: SchedulerType = SerialDispatchQueueScheduler(qos: .default)) {
        self.environment = environment
        self.organizationID = organizationID
        self.domain = domain
        self.visitorType = visitorType
        self.scheduler = scheduler
        
        observeEnterBackground().subscribe().disposed(by: disposeBag)
        observeEnterForeground().subscribe().disposed(by: disposeBag)
    }
    
    // MARK: - Update Environment
    public func updateEnvironment(_ environment: Environment) {
        self.environment = environment
    }
    
    // MARK: - Update Domain
    public func updateDomain(_ domain: String) {
        self.domain = domain
    }
    
    // MARK: - Update Visitor Type
    public func updateVisitorType(_ visitorType: VisitorType) {
        self.visitorType = visitorType
    }
    
    // MARK: - Send Mirror Event
    internal func sendMirror(eventType: EventType, parameters: [String: Any]) -> Observable<HTTPURLResponse> {
        let url = eventType.getUrl(environment)
        return RxAlamofire.requestResponse(.get, url, parameters: parameters)
    }
    
    // MARK: - Ping
    
    /// - Parameter data: The TrackData for mirror parameters
    public func ping(data: TrackData) {
        sendPing(data: data)
    }
    
    internal func sendPing(data: TrackData, isNewPings: Bool = true,  isForcePings: Bool = false) {
        
        if isNewPings {
            stopStandardPings(resetData: true)
            sequenceNumber = 1
            engagedTime = 0
            setPingTimer(data: data)
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
    internal func engageTimerObservable(period: Int) -> Observable<Int> {
        Observable<Int>.interval(.seconds(period), scheduler: scheduler)
            .take(until: { [weak self] _ in
                guard let self = self else { return true }
                return self.engagedTime >= self.maximumPingInterval
            }, behavior: .exclusive)
            .do(onNext: { [weak self] _ in
                self?.engagedTime += 1
            }, onCompleted: { [weak self] in
                self?.stopStandardPings()
            })
    }
    
    // Timer for standard pings
    internal func standardPingsTimerObservable(startSeconds: Int, period: Int, data: TrackData) -> Observable<Int> {
        Observable<Int>.timer(.seconds(startSeconds), period: .seconds(period), scheduler: scheduler)
            .do(onNext: { [weak self] _ in
                self?.sequenceNumber += 1
                self?.sendPing(data: data, isNewPings: false, isForcePings: false)
            })
    }
    
    internal func setPingTimer(data: TrackData) {
        engageTimer = engageTimerObservable(period: 1).subscribe()
        standardPingsTimer = standardPingsTimerObservable(startSeconds: 15, period: 15, data: data).subscribe()
    }
    
    // observable for enter background
    internal func observeEnterBackground() -> Observable<Notification> {
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.stopStandardPings()
            })
    }
    
    // observable for enter foreground
    internal func observeEnterForeground() -> Observable<Notification> {
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .do(onNext: { [weak self] _ in
                guard let self = self, let lastPingData = self.lastPingData else { return }
                self.sendPing(data: lastPingData, isNewPings: false, isForcePings: true)
                guard self.engagedTime < self.maximumPingInterval else { return }
                self.setPingTimer(data: lastPingData)
            })
    }
    
    // stop ping
    internal func stopStandardPings(resetData: Bool = false) {
        engageTimer?.dispose()
        engageTimer = nil
        standardPingsTimer?.dispose()
        standardPingsTimer = nil
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
    internal func getParameters(eventType: EventType, data: TrackData) -> [String: Any] {
        
        var dictionary: [String: Any] = [:]
        
        dictionary["k"] = organizationID
        dictionary["d"] = domain
        dictionary["p"] = data.path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        dictionary["u"] = uuid
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
        
        dictionary["pi"] = data.pageID
        
        dictionary["v"] = agentVersion
        
        return dictionary
    }
}
