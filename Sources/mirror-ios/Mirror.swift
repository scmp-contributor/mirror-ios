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

public protocol MirrorDelegate: AnyObject {
    func changeView(completion: @escaping () -> ())
}

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
    internal var sequenceNumber: Int = 0
    /// - Parameter nc: The flag to indicate if visitor accepts tracking
    internal let trackingFlag: TrackingFlag = .true
    /// - Parameter v: Agent version, for iOS "mi-x.x.x", for android "ma-x.x.x"
    internal let agentVersion: String = Constants.agentVersion
    
    // MARK: - Constants & Variables
    
    public weak var delegate: MirrorDelegate? {
        didSet {
            delegate?.changeView { [weak self] in
                self?.stopStandardPings()
            }
        }
    }
    
    internal let scheduler: SchedulerType
    internal let disposeBag = DisposeBag()
    
    internal var standardPingsTimer: Disposable?
    internal var lastPingData: TrackData?
    internal var latestPingEngageTime: Int = 0
    
    internal var didEnterBackgroundRelay = BehaviorRelay<Bool>(value: false)
    
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
        return RxAlamofire.requestResponse(.get, url, parameters: parameters, headers: ["User-Agent": Constants.userAgent])
    }
    
    // MARK: - Ping
    
    /// - Parameter data: The TrackData for mirror parameters
    public func ping(data: TrackData) {
        stopStandardPings()
        sequenceNumber = 0
        engagedTime = 0
        standardPingsTimer = pingTimerObservable(data: data).subscribe()
    }
    
    internal func sendPing(data: TrackData) {
        sequenceNumber += 1
        let parameters = getParameters(eventType: .ping, data: data)
        latestPingEngageTime = engagedTime
        
        sendMirror(eventType: .ping, parameters: parameters)
            .subscribe(onNext: { [weak self] response in
                logger.debug("[Track-Mirror] ping success, parameters: \(parameters), response: \(response.statusCode)")
                self?.lastPingData = data
            }).disposed(by: disposeBag)
    }
    
    // Timer for engage time
    internal func pingTimerObservable(data: TrackData) -> Observable<Int> {
        let backgroundPingIntervals = [30, 45, 75, 165, 1005]
        return Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: scheduler)
            .take(until: { $0 == Constants.maximumPingInterval }, behavior: .inclusive)
            .do(onNext: { [weak self] time in
                guard let self = self else { return }
                self.engagedTime = time
                if self.didEnterBackgroundRelay.value {
                    if backgroundPingIntervals.contains(time) {
                        self.sendPing(data: data)
                    }
                } else {
                    if (time - self.latestPingEngageTime) % 15 == 0 {
                        self.sendPing(data: data)
                    }
                }
            })
    }
    
    // observable for enter background
    internal func observeEnterBackground() -> Observable<Notification> {
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.didEnterBackgroundRelay.accept(true)
            })
    }
    
    // observable for enter foreground
    internal func observeEnterForeground() -> Observable<Notification> {
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.didEnterBackgroundRelay.accept(false)
                guard let lastPingData = self.lastPingData else { return }
                self.sendPing(data: lastPingData)
            })
    }
    
    // stop ping
    internal func stopStandardPings() {
        standardPingsTimer?.dispose()
        standardPingsTimer = nil
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
            dictionary["s"] = "articles only, \(section)"
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
