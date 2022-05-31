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
import SwiftyBeaver

public protocol MirrorDelegate: AnyObject {
    func stopPing(handler: @escaping () -> Void)
}

public class Mirror: NSObject {
    
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
    internal var engagedTime: Double = 0
    /// - Parameter sq: Sequence number of ping events within same session
    internal var sequenceNumber: Int = 0
    /// - Parameter ir: The page referrer from same domain
    internal var internalReferrer: String? = nil
    /// - Parameter nc: The flag to indicate if visitor accepts tracking
    internal let trackingFlag: TrackingFlag = .ˋfalseˋ
    /// - Parameter ff: The additional duration added to the event to extend the page browing session
    internal var ff: Int {
        if sequenceNumber == 1 {
            return 45
        } else {
            if pingTimeInterval * 2 >= 270 {
                return 270
            } else {
                return pingTimeInterval * 2
            }
        }
    }
    /// - Parameter v: Agent version, for iOS "mi-x.x.x", for android "ma-x.x.x"
    internal let agentVersion: String = Constants.agentVersion
    
    internal var pingTimeInterval = 0
    // MARK: - Constants & Variables
    
    public weak var delegate: MirrorDelegate? {
        didSet {
            delegate?.stopPing { [weak self] in
                self?.stopStandardPings()
            }
        }
    }
    
    internal var gestureRecongnizer: MirrorGestureRecongnizer {
        let gesture = MirrorGestureRecongnizer(target: self, action: #selector(handleGesture(_:)))
        gesture.requiresExclusiveTouchType = false
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }
    
    internal let scheduler: SchedulerType
    internal let disposeBag = DisposeBag()
    
    internal var standardPingsTimer: Disposable?
    internal var lastPingData: TrackData?
    
    internal var pingState: PingState = .active
    
    // Gesture
    internal let inactiveRelay = BehaviorRelay<Bool>(value: false)
    internal var lastTouchEndedTime: TimeInterval = Date().timeIntervalSince1970
    internal var touchTimer: Disposable?
    
    // MARK: - init
    public init(environment: Environment = .prod,
                organizationID: String = "1",
                domain: String,
                visitorType: VisitorType = .guest,
                window: UIWindow,
                scheduler: SchedulerType = SerialDispatchQueueScheduler(qos: .default)) {
        self.environment = environment
        self.organizationID = organizationID
        self.domain = domain
        self.visitorType = visitorType
        self.scheduler = scheduler
        
        super.init()
        
        window.addGestureRecognizer(gestureRecongnizer)
        
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
    public func ping(data: TrackData?) {
        if data?.isEqualExcluePageIDTo(lastPingData) ?? false {
            return
        }
        stopStandardPings()
        lastPingData = data
        sequenceNumber = 0
        resetEngageTime()
        if let data = data {
            setPingTimer(data: data, pingState: .active, dueTime: 0, intervalsIndex: 0)
        }
    }
    
    internal func sendPing(data: TrackData, pingState: PingState, pingInterval: Int) {
        sequenceNumber += 1
        engagedTime = pingState == .background ? 0 : engagedTime
        let parameters = getParameters(eventType: .ping, data: data)
        
        sendMirror(eventType: .ping, parameters: parameters)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                mirrorLog.debug("""
                                [Track-Mirror]
                                mirror -> ping success, response: \(response.statusCode),
                                mirror -> state: \(pingState),
                                mirror -> ping interval: \(pingInterval),
                                mirror -> next ping interval: \(self.pingTimeInterval)
                                ====== Mirror Request Body Start ======
                                \(self.formatMirrorDictionary(parameters))
                                ====== Mirror Request Body End ======
                                """)
                self.lastPingData = data
                self.resetEngageTime()
            }).disposed(by: disposeBag)
    }
    
    internal func setPingTimer(data: TrackData, pingState: PingState, dueTime: Int, intervalsIndex: Int) {
        self.pingState = pingState
        resetEngageTime()
        
        standardPingsTimer?.dispose()
        standardPingsTimer = nil
        
        let period = pingState.intervals[intervalsIndex]
        
        func setNewPingTimer(pingState: PingState, intervalsIndex: Int) {
            if intervalsIndex < pingState.intervals.count - 1 {
                let index = intervalsIndex + 1
                let period = pingState.intervals[index]
                self.setPingTimer(data: data, pingState: pingState, dueTime: period, intervalsIndex: index)
            }
        }
        
        self.pingTimeInterval = period
        standardPingsTimer = Observable<Int>.timer(.seconds(dueTime), period: .seconds(period), scheduler: scheduler)
            .subscribe(onNext: { [weak self] time in
                guard let self = self else { return }
                
                self.sendPing(data: data, pingState: pingState, pingInterval: period)
                
                switch pingState {
                case .active:
                    if self.inactiveRelay.value {
                        self.setPingTimer(data: data, pingState: .inactive, dueTime: PingState.inactive.intervals[0], intervalsIndex: 0)
                    } else {
                        self.inactiveRelay.accept(true)
                    }
                case .inactive:
                    if self.inactiveRelay.value {
                        setNewPingTimer(pingState: .inactive, intervalsIndex: intervalsIndex)
                    } else {
                        self.setPingTimer(data: data, pingState: .active, dueTime: PingState.active.intervals[0], intervalsIndex: 0)
                    }
                case .background:
                    setNewPingTimer(pingState: .background, intervalsIndex: intervalsIndex)
                }
            })
    }
    
    // observable for enter background
    internal func observeEnterBackground() -> Observable<Notification> {
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let lastPingData = self.lastPingData {
                    if let index = PingState.background.intervals.firstIndex(where: { $0 >= self.pingTimeInterval }) {
                        self.setPingTimer(data: lastPingData, pingState: .background, dueTime: 0, intervalsIndex: index)
                    }
                }
            })
    }
    
    // observable for enter foreground
    internal func observeEnterForeground() -> Observable<Notification> {
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                guard let lastPingData = self.lastPingData else { return }
                self.setPingTimer(data: lastPingData, pingState: .active, dueTime: 0, intervalsIndex: 0)
            })
    }
    
    // stop ping
    internal func stopStandardPings() {
        internalReferrer = lastPingData?.path
        lastPingData = nil
        standardPingsTimer?.dispose()
        standardPingsTimer = nil
    }
    
    // MARK: - Click
    
    /// - Parameter data: The TrackData for mirror parameters
    public func click(data: TrackData) {
        sequenceNumber += 1
        let parameters = getParameters(eventType: .click, data: data)
        
        sendMirror(eventType: .click, parameters: parameters)
            .subscribe(onNext: { response in
                mirrorLog.debug("""
                                [Track-Mirror]
                                mirror -> click success, response: \(response.statusCode)
                                ====== Mirror Request Body Start ======
                                \(self.formatMirrorDictionary(parameters))
                                ====== Mirror Request Body End ======
                                """)
            }).disposed(by: disposeBag)
    }
}

extension Mirror {
    internal func getParameters(eventType: EventType, data: TrackData) -> [String: Any] {
        
        let isPingEvent = eventType == .ping
        
        var dictionary: [String: Any] = [:]
        
        dictionary["k"] = organizationID
        dictionary["d"] = domain
        dictionary["p"] = data.path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        dictionary["u"] = uuid
        dictionary["vt"] = visitorType.rawValue
        let eg = lround(engagedTime) > 15 ? 15 : lround(engagedTime)
        dictionary["eg"] = eg
        dictionary["sq"] = sequenceNumber
        
        if let section = data.section {
            dictionary["s"] = "articles only, \(section)"
        } else {
            dictionary["s"] = "No Section"
        }
        
        let authors = data.authors ?? "No Author"
        dictionary["a"] = authors
        
        if let pageTitle = data.pageTitle, sequenceNumber == 1 {
            dictionary["pt"] = pageTitle
        }
        
        dictionary["pi"] = data.pageID
        
        if isPingEvent {
            if let internalReferrer = internalReferrer {
                dictionary["ir"] = internalReferrer.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            }
            
            dictionary["ff"] = ff
        }
        
        dictionary["et"] = eventType.rawValue
        dictionary["nc"] = trackingFlag.rawValue
        
        if let clickInfo = data.clickInfo {
            dictionary["ci"] = clickInfo.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        }
        
        dictionary["v"] = agentVersion
        
        return dictionary
    }
    
    internal func formatMirrorDictionary(_ dic: [String: Any]) -> String {
        var result = ""
        for (index, d) in dic.enumerated() {
            result.append("mirror parameter \(d.key): \(d.value)")
            if index < dic.count - 1 {
                result.append("\n")
            }
        }
        return result
    }
}

// MARK: - Gesture
extension Mirror: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func handleGesture(_ sender: UIGestureRecognizer) {
        switch sender.state {
        case .began:
            if pingState == .inactive {
                if let lastPingData = lastPingData {
                    setPingTimer(data: lastPingData, pingState: .active, dueTime: 0, intervalsIndex: 0)
                }
            }
            
            self.inactiveRelay.accept(false)
            
            let ts = Date().timeIntervalSince1970
            if ts > lastTouchEndedTime,
               ts - lastTouchEndedTime <= 4 {
                engagedTime += (ts - lastTouchEndedTime)
            }
            
            setTouchTimer(enable: true)
        case .ended:
            setTouchTimer(enable: false)
            
            let ts = Date().timeIntervalSince1970
            lastTouchEndedTime = ts
        default:
            break
        }
    }
    
    //  Reset engage time
    public func resetEngageTime() {
        lastTouchEndedTime = Date().timeIntervalSince1970
        engagedTime = 0
    }
    
    // Touch Timer
    private func setTouchTimer(enable: Bool) {
        if enable {
            touchTimer = Observable<Int>.timer(.milliseconds(0), period: .milliseconds(1), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.engagedTime += 0.001
                })
        } else {
            touchTimer?.dispose()
            touchTimer = nil
        }
    }
}
