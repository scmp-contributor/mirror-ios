//
//  AnyGestureRecongnizer.swift
//  
//
//  Created by Terry Lee on 2022/5/23.
//

import UIKit
import RxSwift
import RxRelay

public class MirrorGestureRecongnizer: UIGestureRecognizer {
    
    // MARK: - Public
    public let inactiveRelay = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Private
    private let disposeBag = DisposeBag()
    
    private var lastTouchEndedTime: TimeInterval = Date().timeIntervalSince1970
    
    private (set) var engageTime: Int = 0
    
    private var touchTimer: Disposable?
    private var inactiveTimer: Disposable?
    
    // MARK: - Init
    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        
        setInactiveTimer(enable: true)
    }
    
    // MARK: - UIGestureRecognizer
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        state = .began
        
        setInactiveTimer(enable: false)
        
        let ts = Date().timeIntervalSince1970
        if ts > lastTouchEndedTime,
           ts - lastTouchEndedTime <= 4 {
            engageTime += Int(ts - lastTouchEndedTime)
        }
        
        setTouchTimer(enable: true)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        state = .ended
        
        setTouchTimer(enable: false)
        setInactiveTimer(enable: true)
        
        let ts = Date().timeIntervalSince1970
        lastTouchEndedTime = ts
    }
    
    // MARK: - Reset engage time
    public func resetEngageTime() {
        engageTime = 0
    }
    
    // MARK: - Touch Timer
    private func setTouchTimer(enable: Bool) {
        if enable {
            touchTimer = Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.engageTime += 1
                })
        } else {
            touchTimer?.dispose()
            touchTimer = nil
        }
    }
    
    // MARK: - Inactive Timer
    private func setInactiveTimer(enable: Bool) {
        if enable {
            inactiveTimer = Observable<Int>.interval(.seconds(15), scheduler: MainScheduler.instance)
                .take(1)
                .subscribe(onNext: { [weak self] _ in
                    self?.inactiveRelay.accept(true)
                })
        } else {
            inactiveRelay.accept(false)
            inactiveTimer?.dispose()
            inactiveTimer = nil
        }
    }
}
