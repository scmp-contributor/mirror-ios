//
//  MirrorManager.swift
//  mirror-ios-example
//
//  Created by Terry Lee on 2022/5/13.
//

import Foundation
import RxSwift
import mirror_ios

class MirrorManager {
    
    let mirror: Mirror = Mirror(environment: .uat, domain: "scmp.com")
    
    let disposeBag = DisposeBag()
    
    init() {
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
