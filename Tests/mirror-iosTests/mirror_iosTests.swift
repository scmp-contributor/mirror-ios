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
        XCTAssertNotNil(mirror.domainAddress)
        XCTAssertNotNil(mirror.visitorID)
        XCTAssertNotNil(mirror.visitorType)
        XCTAssertNotNil(mirror.eventType)
        XCTAssertNotNil(mirror.trackingFlag)
        XCTAssertFalse(mirror.hasNecessaryParameter)
    }
    
    // MARK: - Test Necessary Parameters
    func testNecessaryParameters() {
        XCTAssertFalse(mirror.hasNecessaryParameter)
        mirror.urlAlias = ""
        XCTAssertFalse(mirror.hasNecessaryParameter)
        mirror.urlAlias = "/news/asia".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        XCTAssertTrue(mirror.hasNecessaryParameter)
    }
    
    // MARK: - Test API URL
    func testUatApiURL() {
        mirror = Mirror(environment: .uat)
        let apiUrl = "https://uat-mirror.i-scmp.com"
        XCTAssertEqual(mirror.environment.apiUrl, apiUrl)
        XCTAssertEqual(mirror.environment.pingUrl, apiUrl + "/ping")
        XCTAssertEqual(mirror.environment.clickUrl, apiUrl + "/click")
    }
    
    func testProdApiURL() {
        mirror = Mirror(environment: .prod)
        let apiUrl = "https://mirror.i-scmp.com"
        XCTAssertEqual(mirror.environment.apiUrl, apiUrl)
        XCTAssertEqual(mirror.environment.pingUrl, apiUrl + "/ping")
        XCTAssertEqual(mirror.environment.clickUrl, apiUrl + "/click")
    }
    
    // MARK: - Test Ping
    func testStartStandardLogicSuccess() throws {
        mirror.startStandardPings(urlAlias: "/news/asia", pageTitle: "Test Page Title")
        XCTAssertTrue(mirror.hasNecessaryParameter)
        XCTAssertTrue(mirror.isStandardPingRelay.value)
    }
    
    func testStartStandardLogicFail() throws {
        mirror.startStandardPings(urlAlias: "")
        XCTAssertFalse(mirror.hasNecessaryParameter)
        XCTAssertFalse(mirror.isStandardPingRelay.value)
    }
    
    func testFailPing() throws {
        mirror = Mirror(environment: .uat)
        XCTAssertFalse(mirror.hasNecessaryParameter)
        XCTAssert(try mirror.ping().toBlocking().first()?.statusCode != 200, "statusCode is matching the server data")
    }
    
    func testSuccessPing() throws {
        mirror = Mirror(environment: .uat)
        mirror.urlAlias = "/news/asia".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        XCTAssertTrue(mirror.hasNecessaryParameter)
        XCTAssert(try mirror.ping().toBlocking().first()?.statusCode == 200, "statusCode is not matching the server data")
    }
    
    func testStopPing() throws {
        mirror.stopStandardPings()
        XCTAssertFalse(mirror.isStandardPingRelay.value)
    }
    
    func testPingTimer() {
        let scheduler = TestScheduler(initialClock: 0)
        let mirror = Mirror(environment: .uat, scheduler: scheduler)
        let res = scheduler.start(created: 0, subscribed: 0, disposed: 92) {
            mirror.standardPingsTimer(period: 15)
        }
        XCTAssertEqual(res.events, [
            .next(1, 0),
            .next(16, 1),
            .next(31, 2),
            .next(46, 3),
            .next(61, 4),
            .next(76, 5),
            .next(91, 6),
        ])
    }
    
    func testParams() {
        mirror = Mirror(environment: .uat, organizationID: "1", domainAddress: "scmp.com", visitorType: .guest)
        mirror.startStandardPings(urlAlias: "/news/asia",
                                  articleSection: "articles only, News, Hong Kong, Health & Environment",
                                  articleAuthors: "Keung To, Anson Lo",
                                  pageTitle: "HK, China, Asia news & opinion from SCMP’s global edition | South China Morning Post",
                                  referrerFromSameDomain: "https://www.scmp.com/news/asia/australasia",
                                  referrerFromOtherDomain: "https://www.facebook.com/",
                                  y1: 1080,
                                  y2: 1080,
                                  metadata: "https://www.scmp.com/news/china/diplomacy/article/3155792/friends-mourn-chinas-perfect-child-zheng-shaoxiong-gunned-down",
                                  ff: 30,
                                  agentVersion: "0.0.1")
        
        let parameters = mirror.asDictionary()
        XCTAssertEqual(parameters.keys.count, 19)
        
        XCTAssertEqual(parameters["k"] as? String, "1")
        XCTAssertEqual(parameters["d"] as? String, "scmp.com")
        XCTAssertEqual(parameters["u"] as? String, Preferences.sharedInstance.visitorID)
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
        XCTAssertEqual(parameters["y1"] as? Int, 1080)
        XCTAssertEqual(parameters["y2"] as? Int, 1080)
        XCTAssertEqual(parameters["ci"] as? String, "https://www.scmp.com/news/china/diplomacy/article/3155792/friends-mourn-chinas-perfect-child-zheng-shaoxiong-gunned-down")
        XCTAssertEqual(parameters["ff"] as? Int, 30)
        XCTAssertEqual(parameters["v"] as? String, "0.0.1")
    }
}
