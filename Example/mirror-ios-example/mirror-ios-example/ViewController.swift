//
//  ViewController.swift
//  mirror-ios-example
//
//  Created by Terry Lee on 2022/4/21.
//

import UIKit
import RxCocoa
import mirror_ios

let currentViewControllerRelay: BehaviorRelay<UIViewController?> = BehaviorRelay<UIViewController?>(value: nil)

class ViewController: UIViewController {
    
    @IBOutlet weak var pathTextField: UITextField!
    @IBOutlet weak var sectionTextField: UITextField!
    @IBOutlet weak var authorsTextField: UITextField!
    @IBOutlet weak var pageTitleTextField: UITextField!
    @IBOutlet weak var clickInfoTextField: UITextField!
    
    var mirrorManager: MirrorManager? {
        SceneDelegate.shared?.mirrorManager
    }
    
    var trackData: TrackData? {
        guard let path = pathTextField.text, !path.isEmpty else { return nil }
        let section = (sectionTextField.text?.isEmpty ?? true) ? nil : sectionTextField.text
        let authors = (authorsTextField.text?.isEmpty ?? true) ? nil : authorsTextField.text
        let pageTitle = (pageTitleTextField.text?.isEmpty ?? true) ? nil : pageTitleTextField.text
        let ckickInfo = (clickInfoTextField.text?.isEmpty ?? true) ? nil : clickInfoTextField.text
        let data = TrackData(path: path,
                             section: section,
                             authors: authors,
                             pageTitle: pageTitle,
                             clickInfo: ckickInfo)
        return data
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        resetToPingData()
        currentViewControllerRelay.accept(self)
    }
    
    func resetToPingData() {
        pathTextField.text = "/news/asia"
        sectionTextField.text = "News, Hong Kong, Health & Environment"
        authorsTextField.text = "Keung To, Anson Lo"
        pageTitleTextField.text = "HK, China, Asia news & opinion from SCMP’s global edition | South China Morning Post"
        clickInfoTextField.text = nil
    }
    
    func resetToClickData() {
        pathTextField.text = "/hk"
        sectionTextField.text = nil
        authorsTextField.text = nil
        pageTitleTextField.text = nil
        clickInfoTextField.text = "https://scmp.com/news/hong-kong/health-environment/article/3179276/coronavirus-hong-kong-prepared-rebound-infections"
    }
    
    @IBAction func pingButton(_ sender: UIButton) {
        guard let trackData = trackData else {
            print("Path is necessary")
            return
        }
        mirrorManager?.ping(data: trackData)
    }
    
    @IBAction func clickButton(_ sender: UIButton) {
        guard let trackData = trackData else {
            print("Path is necessary")
            return
        }
        mirrorManager?.click(data: trackData)
    }
    
    @IBAction func resetToPingDataButton(_ sender: UIButton) {
        resetToPingData()
    }
    
    @IBAction func resetToClickDataButton(_ sender: UIButton) {
        resetToClickData()
    }
    
    
    @IBAction func simulateChangeViewButton(_ sender: UIButton) {
        let vc = ViewController()
        currentViewControllerRelay.accept(vc)
    }
}

