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
        XCTAssertNotNil(mirror.visitorID)
        XCTAssertNotNil(mirror.visitorType)
        XCTAssertEqual(mirror.engagedTime, 0)
        XCTAssertEqual(mirror.sequenceNumber, 1)
        XCTAssertEqual(mirror.trackingFlag, TrackingFlag.true)
        XCTAssertNotNil(mirror.agentVersion)
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
    func testFirstStandardPings() throws {
        let data = TrackData(path: "/news/asia")
        mirror.ping(data: data)
        XCTAssertEqual(mirror.sequenceNumber, 1)
        XCTAssertEqual(mirror.engagedTime, 0)
        
        mirror.ping(data: data)
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
        
        mirror.ping(data: data)
        XCTAssertNotNil(mirror.standardPingsTimer)
        mirror.stopStandardPings()
        XCTAssertNil(mirror.standardPingsTimer)
        XCTAssertNil(mirror.engageTimer)
        
        mirror.ping(data: data)
        XCTAssertNotNil(mirror.standardPingsTimer)
        mirror.stopStandardPings(resetData: true)
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
        XCTAssertEqual(parameters["u"] as? String, Preferences.sharedInstance.visitorID)
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
}
