//
//  ViewController.swift
//  mirror-ios-example
//
//  Created by Terry Lee on 2022/4/21.
//

import UIKit
import mirror_ios

class ViewController: UIViewController {
    
    let mirror = Mirror(environment: .uat)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func startPingButton(_ sender: UIButton) {
        let data = TrackData(path: "testing.com", pageTitle: "Test Page Title")
        mirror.ping(data: data)
    }
    
    @IBAction func stopPingButton(_ sender: UIButton) {
        mirror.stopPing()
    }
}

