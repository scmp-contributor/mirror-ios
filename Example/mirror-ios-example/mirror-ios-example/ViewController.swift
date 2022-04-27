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
    
    let mirror = Mirror(environment: .uat, visitorType: .guest)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func startPingButton(_ sender: UIButton) {
        mirror.startPing(urlAlias: "/news/asia", pageTitle: "Test Page Title")
    }
    
    @IBAction func stopPingButton(_ sender: UIButton) {
        mirror.stopPing()
    }
}

