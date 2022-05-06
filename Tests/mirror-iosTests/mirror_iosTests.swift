import XCTest
import RxSwift
import RxTest
import RxBlocking
@testable import mirror_ios

final class mirror_iosTests: XCTestCase {
    
    var mirror: Mirror!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    override func setUp() {
        mirror = Mirror(environment: .uat)
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }
    
    // MARK: - Test Initial Value
    func testInitialValue() {
        XCTAssertNotNil(mirror.organizationID)
        XCTAssertNotNil(mirror.domain)
        XCTAssertNotNil(mirror.uuid)
        XCTAssertNotNil(mirror.visitorType)
        XCTAssertEqual(mirror.engagedTime, 0)
        XCTAssertEqual(mirror.sequenceNumber, 1)
        XCTAssertEqual(mirror.trackingFlag, TrackingFlag.true)
        XCTAssertNotNil(mirror.agentVersion)
    }
    
    // MARK: - Test Update nvironment
    func testUpdateEnvironment() {
        mirror = Mirror(environment: .uat)
        XCTAssertEqual(mirror.environment, .uat)
        mirror.updateEnvironment(.prod)
        XCTAssertEqual(mirror.environment, .prod)
    }
    
    // MARK: - Test Update Visitor Type
    func testUpdateVisitorType() {
        mirror = Mirror(environment: .uat, visitorType: .guest)
        XCTAssertEqual(mirror.visitorType, .guest)
        mirror.updateVisitorType(.unclassified)
        XCTAssertEqual(mirror.visitorType, .unclassified)
        mirror.updateVisitorType(.registered)
        XCTAssertEqual(mirror.visitorType, .registered)
        mirror.updateVisitorType(.subscribed)
        XCTAssertEqual(mirror.visitorType, .subscribed)
        
    }
    
    // MARK: - Test API URL
    func testUatApiURL() {
        mirror = Mirror(environment: .uat)
        let apiUrl = "https://uat-mirror.i-scmp.com"
        XCTAssertEqual(mirror.environment.apiUrl, apiUrl)
        XCTAssertEqual(mirror.environment.pingUrl, apiUrl + "/ping")
        XCTAssertEqual(mirror.environment.clickUrl, apiUrl + "/ping")
    }
    
    func testProdApiURL() {
        mirror = Mirror(environment: .prod)
        let apiUrl = "https://mirror.i-scmp.com"
        XCTAssertEqual(mirror.environment.apiUrl, apiUrl)
        XCTAssertEqual(mirror.environment.pingUrl, apiUrl + "/ping")
        XCTAssertEqual(mirror.environment.clickUrl, apiUrl + "/ping")
    }
    
    // MARK: - Test Ping
    func testFirstStandardPings() throws {
        let data = TrackData(path: "/news/asia")
        mirror.sendPing(data: data)
        XCTAssertEqual(mirror.sequenceNumber, 1)
        XCTAssertEqual(mirror.engagedTime, 0)
        
        mirror.sendPing(data: data)
        XCTAssertNotNil(mirror.standardPingsTimer)
    }
    
    func testSendPing() throws {
        let data = TrackData(path: "/news/asia")
        let parameters = mirror.getParameters(eventType: .ping, data: data)
        XCTAssertEqual(try mirror.sendMirror(eventType: .ping, parameters: parameters).toBlocking().first()?.statusCode, 200)
    }
    
    func testStopPing() throws {
        mirror.stopStandardPings()
        XCTAssertNil(mirror.standardPingsTimer)
        XCTAssertNil(mirror.engageTimer)
        
        let data = TrackData(path: "/news/asia")
        
        mirror.sendPing(data: data)
        XCTAssertNotNil(mirror.standardPingsTimer)
        mirror.stopStandardPings()
        XCTAssertNil(mirror.standardPingsTimer)
        XCTAssertNil(mirror.engageTimer)
        
        mirror.sendPing(data: data)
        XCTAssertNotNil(mirror.standardPingsTimer)
        mirror.stopPing()
        XCTAssertNil(mirror.standardPingsTimer)
        XCTAssertNil(mirror.engageTimer)
        XCTAssertNil(mirror.lastPingData)
    }
    
    func testPingParams() {
        mirror = Mirror(environment: .uat, organizationID: "1", domain: "scmp.com", visitorType: .guest)
        let data = TrackData(path: "/news/asia",
                             section: "articles only, News, Hong Kong, Health & Environment",
                             authors: "Keung To, Anson Lo",
                             pageTitle: "HK, China, Asia news & opinion from SCMP’s global edition | South China Morning Post",
                             internalReferrer: "https://www.scmp.com/news/asia/australasia",
                             externalReferrer: "https://www.facebook.com/")
        let parameters = mirror.getParameters(eventType: .ping, data: data)
        XCTAssertEqual(parameters.keys.count, 15)
        XCTAssertEqual(parameters["k"] as? String, "1")
        XCTAssertEqual(parameters["d"] as? String, "scmp.com")
        XCTAssertEqual(parameters["u"] as? String, Preferences.sharedInstance.uuid)
        XCTAssertEqual(parameters["vt"] as? String, "gst")
        XCTAssertEqual(parameters["et"] as? String, "ping")
        XCTAssertEqual(parameters["nc"] as? String, "true")
        XCTAssertEqual(parameters["p"] as? String, "/news/asia".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
        XCTAssertEqual(parameters["eg"] as? Int, 0)
        XCTAssertEqual(parameters["sq"] as? Int, 1)
        XCTAssertEqual(parameters["s"] as? String, "articles only, News, Hong Kong, Health & Environment")
        XCTAssertEqual(parameters["a"] as? String, "Keung To, Anson Lo")
        XCTAssertEqual(parameters["pt"] as? String, "HK, China, Asia news & opinion from SCMP’s global edition | South China Morning Post")
        XCTAssertEqual(parameters["ir"] as? String, "https://www.scmp.com/news/asia/australasia")
        XCTAssertEqual(parameters["er"] as? String, "https://www.facebook.com/")
        XCTAssertEqual(parameters["v"] as? String, mirror.agentVersion)
    }
    
    func testClickParams() {
        mirror = Mirror(environment: .uat, organizationID: "1", domain: "scmp.com", visitorType: .guest)
        let data = TrackData(path: "/news/asia",
                             section: "articles only, News, Hong Kong, Health & Environment",
                             authors: "Keung To, Anson Lo",
                             pageTitle: "HK, China, Asia news & opinion from SCMP’s global edition | South China Morning Post",
                             internalReferrer: "https://www.scmp.com/news/asia/australasia",
                             externalReferrer: "https://www.facebook.com/")
        let parameters = mirror.getParameters(eventType: .click, data: data)
        XCTAssertEqual(parameters.keys.count, 15)
        XCTAssertEqual(parameters["k"] as? String, "1")
        XCTAssertEqual(parameters["d"] as? String, "scmp.com")
        XCTAssertEqual(parameters["u"] as? String, Preferences.sharedInstance.uuid)
        XCTAssertEqual(parameters["vt"] as? String, "gst")
        XCTAssertEqual(parameters["et"] as? String, "click")
        XCTAssertEqual(parameters["nc"] as? String, "true")
        XCTAssertEqual(parameters["p"] as? String, "/news/asia".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
        XCTAssertEqual(parameters["eg"] as? Int, 0)
        XCTAssertEqual(parameters["sq"] as? Int, 1)
        XCTAssertEqual(parameters["s"] as? String, "articles only, News, Hong Kong, Health & Environment")
        XCTAssertEqual(parameters["a"] as? String, "Keung To, Anson Lo")
        XCTAssertEqual(parameters["pt"] as? String, "HK, China, Asia news & opinion from SCMP’s global edition | South China Morning Post")
        XCTAssertEqual(parameters["ir"] as? String, "https://www.scmp.com/news/asia/australasia")
        XCTAssertEqual(parameters["er"] as? String, "https://www.facebook.com/")
        XCTAssertEqual(parameters["v"] as? String, mirror.agentVersion)
    }
    
    func testEngageTimer() {
        let mirror = Mirror(environment: .uat, scheduler: scheduler)
        XCTAssertEqual(mirror.engagedTime, 0)
        let res = scheduler.start(created: 0, subscribed: 0, disposed: 5) {
            mirror.engageTimerObservable(period: 1)
        }
        XCTAssertEqual(res.events, [
            .next(1, 0),
            .next(2, 1),
            .next(3, 2),
            .next(4, 3)
        ])
        XCTAssertEqual(mirror.engagedTime, 4)
    }
    
    func testStandardPingsTimer() {
        let mirror = Mirror(environment: .uat, scheduler: scheduler)
        let data = TrackData(path: "/news/asia")
        XCTAssertEqual(mirror.sequenceNumber, 1)
        let res = scheduler.start(created: 0, subscribed: 0, disposed: 91) {
            mirror.standardPingsTimerObservable(startSeconds: 15, period: 15, data: data)
        }
        XCTAssertEqual(res.events, [
            .next(15, 0),
            .next(30, 1),
            .next(45, 2),
            .next(60, 3),
            .next(75, 4),
            .next(90, 5)
        ])
        XCTAssertEqual(mirror.sequenceNumber, 7)
    }
    
    func testDidEnterBackgroundNotification() {
        let mirror = Mirror(environment: .uat, scheduler: scheduler)
        
        let data = TrackData(path: "/news/asia")

        mirror.ping(data: data)

        XCTAssertNotNil(mirror.standardPingsTimer)
        XCTAssertNotNil(mirror.engageTimer)
        
        let res = scheduler.start {
            mirror.observeEnterBackground()
        }
        
        res.onNext(Notification(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil))
        
        XCTAssertNil(mirror.standardPingsTimer)
        XCTAssertNil(mirror.engageTimer)
    }
    
    // MARK: - Test Click
    func testSendClick() throws {
        let data = TrackData(path: "/news/asia")
        let parameters = mirror.getParameters(eventType: .click, data: data)
        XCTAssertEqual(try mirror.sendMirror(eventType: .click, parameters: parameters).toBlocking().first()?.statusCode, 200)
    }
}
