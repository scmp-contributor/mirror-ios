import XCTest
import RxSwift
import RxTest
import RxBlocking
@testable import mirror_ios
import RxRelay

final class mirror_iosTests: XCTestCase {
    
    var mirror: Mirror!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    override func setUp() {
        mirror = Mirror(environment: .uat, domain: "scmp.com", window: UIWindow())
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
        XCTAssertEqual(mirror.sequenceNumber, 0)
        XCTAssertEqual(mirror.trackingFlag, TrackingFlag.ˋfalseˋ)
        XCTAssertNotNil(mirror.agentVersion)
    }
    
    // MARK: - Test Update nvironment
    func testUpdateEnvironment() {
        mirror = Mirror(environment: .uat, domain: "scmp.com", window: UIWindow())
        XCTAssertEqual(mirror.environment, .uat)
        mirror.updateEnvironment(.prod)
        XCTAssertEqual(mirror.environment, .prod)
    }
    
    // MARK: - Test Update Domain
    func testUpdateDomain() {
        mirror = Mirror(environment: .uat, domain: "scmp.com", window: UIWindow())
        XCTAssertEqual(mirror.domain, "scmp.com")
        mirror.updateDomain("test.com")
        XCTAssertEqual(mirror.domain, "test.com")
    }
    
    // MARK: - Test Update Visitor Type
    func testUpdateVisitorType() {
        mirror = Mirror(environment: .uat, domain: "scmp.com", visitorType: .guest, window: UIWindow())
        XCTAssertEqual(mirror.visitorType, .guest)
        mirror.updateVisitorType(.unclassified)
        XCTAssertEqual(mirror.visitorType, .unclassified)
        mirror.updateVisitorType(.registered)
        XCTAssertEqual(mirror.visitorType, .registered)
        mirror.updateVisitorType(.subscribed)
        XCTAssertEqual(mirror.visitorType, .subscribed)
    }
    
    // MARK: - Test Delegate
    func testDelegate() throws {
        
        class MirrorManager: MirrorDelegate {
            
            let changeViewRelay: PublishRelay<Void> = PublishRelay()
            let disposeBag = DisposeBag()
            
            func stopPing(handler: @escaping () -> Void) {
                changeViewRelay.subscribe(onNext: {
                    handler()
                }).disposed(by: disposeBag)
            }
        }
        
        let mirrorManager = MirrorManager()
        mirror.delegate = mirrorManager
        
        XCTAssertNil(mirror.standardPingsTimer)
        let data = TrackData(path: "/news/asia")
        mirror.ping(data: data)
        XCTAssertNotNil(mirror.standardPingsTimer)
        mirrorManager.changeViewRelay.accept(())
        XCTAssertNil(mirror.standardPingsTimer)
    }
    
    // MARK: - Test API URL
    func testUatApiURL() {
        mirror = Mirror(environment: .uat, domain: "scmp.com", window: UIWindow())
        let apiUrl = "https://uat-mirror.i-scmp.com"
        XCTAssertEqual(mirror.environment, .uat)
        XCTAssertEqual(mirror.environment.pingUrl, apiUrl + "/ping")
        XCTAssertEqual(mirror.environment.clickUrl, apiUrl + "/ping")
    }
    
    func testProdApiURL() {
        mirror = Mirror(environment: .prod, domain: "scmp.com", window: UIWindow())
        let apiUrl = "https://mirror.i-scmp.com"
        XCTAssertEqual(mirror.environment, .prod)
        XCTAssertEqual(mirror.environment.pingUrl, apiUrl + "/ping")
        XCTAssertEqual(mirror.environment.clickUrl, apiUrl + "/ping")
    }
    
    // MARK: - Test Ping
    func testPing() throws {
        let data = TrackData(path: "/news/asia")
        mirror.ping(data: data)
        XCTAssertEqual(mirror.sequenceNumber, 0)
        XCTAssertEqual(mirror.engagedTime, 0)
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
        
        let data = TrackData(path: "/news/asia")
        
        mirror.ping(data: data)
        XCTAssertNotNil(mirror.standardPingsTimer)
        mirror.stopStandardPings()
        XCTAssertNil(mirror.standardPingsTimer)
    }
    
    func testPingParams() {
        mirror = Mirror(environment: .uat, organizationID: "1", domain: "scmp.com", visitorType: .guest, window: UIWindow())
        let data = TrackData(path: "/news/asia",
                             section: "News, Hong Kong, Health & Environment",
                             authors: "Keung To, Anson Lo",
                             pageTitle: "HK, China, Asia news & opinion from SCMP’s global edition | South China Morning Post")
        mirror.sequenceNumber = 1
        let parameters = mirror.getParameters(eventType: .ping, data: data)
        XCTAssertEqual(parameters.keys.count, 15)
        XCTAssertEqual(parameters["k"] as? String, "1")
        XCTAssertEqual(parameters["d"] as? String, "scmp.com")
        XCTAssertEqual(parameters["u"] as? String, Preferences.sharedInstance.uuid)
        XCTAssertEqual(parameters["vt"] as? String, "gst")
        XCTAssertEqual(parameters["et"] as? String, "ping")
        XCTAssertEqual(parameters["nc"] as? String, "false")
        XCTAssertEqual(parameters["p"] as? String, "/news/asia".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
        XCTAssertEqual(parameters["eg"] as? Int, 0)
        XCTAssertEqual(parameters["sq"] as? Int, 1)
        XCTAssertEqual(parameters["s"] as? String, "articles only, News, Hong Kong, Health & Environment")
        XCTAssertEqual(parameters["a"] as? String, "Keung To, Anson Lo")
        XCTAssertEqual(parameters["pt"] as? String, "HK, China, Asia news & opinion from SCMP’s global edition | South China Morning Post")
        XCTAssertEqual(parameters["pi"] as? String, data.pageID)
        XCTAssertEqual(parameters["ff"] as? Int, 45)
        XCTAssertEqual(parameters["v"] as? String, mirror.agentVersion)
        
        mirror = Mirror(environment: .uat, organizationID: "1", domain: "scmp.com", visitorType: .guest, window: UIWindow())
        let anotherData = TrackData(path: "/news/asia")
        let anotherParameters = mirror.getParameters(eventType: .click, data: anotherData)
        XCTAssertEqual(anotherParameters["s"] as? String, "No Section")
        XCTAssertEqual(anotherParameters["a"] as? String, "No Author")
    }
    
    func testClickParams() {
        mirror = Mirror(environment: .uat, organizationID: "1", domain: "scmp.com", visitorType: .guest, window: UIWindow())
        let data = TrackData(path: "/news/asia",
                             section: "News, Hong Kong, Health & Environment",
                             authors: "Keung To, Anson Lo",
                             clickInfo: "https://www.scmp.com/news/china/diplomacy/article/3155792/friends-mourn-chinas-perfect-child-zheng-shaoxiong-gunned-down")
        mirror.sequenceNumber = 1
        let parameters = mirror.getParameters(eventType: .click, data: data)
        XCTAssertEqual(parameters.keys.count, 14)
        XCTAssertEqual(parameters["k"] as? String, "1")
        XCTAssertEqual(parameters["d"] as? String, "scmp.com")
        XCTAssertEqual(parameters["u"] as? String, Preferences.sharedInstance.uuid)
        XCTAssertEqual(parameters["vt"] as? String, "gst")
        XCTAssertEqual(parameters["p"] as? String, "/news/asia".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
        XCTAssertEqual(parameters["eg"] as? Int, 0)
        XCTAssertEqual(parameters["sq"] as? Int, 1)
        XCTAssertEqual(parameters["s"] as? String, "articles only, News, Hong Kong, Health & Environment")
        XCTAssertEqual(parameters["a"] as? String, "Keung To, Anson Lo")
        XCTAssertEqual(parameters["pi"] as? String, data.pageID)
        XCTAssertEqual(parameters["et"] as? String, "click")
        XCTAssertEqual(parameters["nc"] as? String, "false")
        XCTAssertEqual(parameters["ff"] as? Int, nil)
        XCTAssertEqual(parameters["ci"] as? String, "https://www.scmp.com/news/china/diplomacy/article/3155792/friends-mourn-chinas-perfect-child-zheng-shaoxiong-gunned-down".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
        XCTAssertEqual(parameters["v"] as? String, mirror.agentVersion)
    }
    
    // MARK: - Test Click
    func testSendClick() throws {
        let data = TrackData(path: "/news/asia")
        let parameters = mirror.getParameters(eventType: .click, data: data)
        XCTAssertEqual(try mirror.sendMirror(eventType: .click, parameters: parameters).toBlocking().first()?.statusCode, 200)
    }
}
