//
//  MirrorManager.swift
//  mirror-ios-example
//
//  Created by Terry Lee on 2022/5/13.
//

import UIKit
import RxSwift
import mirror_ios

class MirrorManager {
    
    let mirror: Mirror
    
    let disposeBag = DisposeBag()
    
    init(window: UIWindow) {
        mirror = Mirror(environment: .uat, domain: "scmp.com", window: window)
        mirror.delegate = self
    }
    
    func ping(data: TrackData) {
        mirror.ping(data: data)
    }
    
    func click(data: TrackData) {
        mirror.click(data: data)
    }
}

extension MirrorManager: MirrorDelegate {
    func changeView(completion: @escaping () -> ()) {
        currentViewControllerRelay
            .distinctUntilChanged()
            .asObservable()
            .map { _ in }
            .subscribe(onNext: {
                completion()
            }).disposed(by: disposeBag)
    }
}
