//
//  MirrorGestureRecongnizer.swift
//  
//
//  Created by Terry Lee on 2022/5/23.
//

import UIKit
import RxSwift
import RxRelay

public class MirrorGestureRecongnizer: UIGestureRecognizer {
    
    private let disposeBag = DisposeBag()
    
    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.state = .ended
            }).disposed(by: disposeBag)
    }
    
    // MARK: - UIGestureRecognizer
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        state = .began
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        state = .ended
    }
}
