//
//  ViewController.swift
//  mirror-ios-example
//
//  Created by Terry Lee on 2022/4/21.
//

import UIKit
import mirror_ios
import RxSwift

class ViewController: UIViewController {
    
    let mirror = Mirror(environment: .uat)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func startPingButton(_ sender: UIButton) {
        mirror.ping(data: TrackData(path: "testing.com", pageTitle: "Test Page Title"))
    }
    
    @IBAction func stopPingButton(_ sender: UIButton) {
        mirror.stopStandardPings(resetData: true)
    }
}

