//
//  ViewController.swift
//  mirror-ios-example
//
//  Created by Terry Lee on 2022/4/21.
//

import UIKit
import mirror_ios

class ViewController: UIViewController {
    
    @IBOutlet weak var pathTextField: UITextField!
    @IBOutlet weak var sectionTextField: UITextField!
    @IBOutlet weak var authorsTextField: UITextField!
    @IBOutlet weak var pageTitleTextField: UITextField!
    
    let mirror = Mirror(environment: .uat, domain: "scmp.com")
    
    var trackData: TrackData? {
        guard let path = pathTextField.text, !path.isEmpty else { return nil }
        let section = (sectionTextField.text?.isEmpty ?? true) ? nil : sectionTextField.text
        let authors = (authorsTextField.text?.isEmpty ?? true) ? nil : authorsTextField.text
        let pageTitle = (pageTitleTextField.text?.isEmpty ?? true) ? nil : pageTitleTextField.text
        let data = TrackData(path: path,
                             section: section,
                             authors: authors,
                             pageTitle: pageTitle)
        return data
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        resetDefault()
    }
    
    func resetDefault() {
        pathTextField.text = "/news/asia"
        sectionTextField.text = "News, Hong Kong, Health & Environment"
        authorsTextField.text = "Keung To, Anson Lo"
        pageTitleTextField.text = "HK, China, Asia news & opinion from SCMP’s global edition | South China Morning Post"
    }
    
    @IBAction func pingButton(_ sender: UIButton) {
        guard let trackData = trackData else {
            print("Path is necessary")
            return
        }
        mirror.ping(data: trackData)
    }
    
    @IBAction func clickButton(_ sender: UIButton) {
        guard let trackData = trackData else {
            print("Path is necessary")
            return
        }
        mirror.click(data: trackData)
    }
    
    @IBAction func resetButton(_ sender: UIButton) {
        resetDefault()
    }
}

