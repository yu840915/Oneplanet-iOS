//
//  TabbarHidingSignalProducer.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/10.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class TabbarHidingSignalProducer {
    let scrollView: UIScrollView
    let halfHidingInterval: CGFloat
    private(set) var hidingFactor: CGFloat = 0
    var hidingFactorDidChange: (()->())?
    var animateFactorChange: (()->())?
    private var eventHandles: [Any]?
    private var startingOffset: InitialCondition?
    private weak var inertiaTimer: Timer?
    private var isDragging: Bool {
        didSet {
            if oldValue != isDragging {
                if isDragging {
                    handleStartDragging()
                } else {
                    handleEndDragging()
                }
            }
        }
    }
    private var draggingWatcher: UpdateClock!
    
    init(scrollView: UIScrollView, halfHidingInterval: CGFloat) {
        self.scrollView = scrollView
        self.halfHidingInterval = halfHidingInterval
        isDragging = scrollView.isTracking
        draggingWatcher = UpdateClock(preferredFrameRate: 30, onTick: {[weak self] in
            self?.updateDragging()
        })
        setUpEventHandles()
    }
    
    private func setUpEventHandles() {
        var handles: [Any] = []
        handles.append(scrollView.observe(\.contentOffset) {[weak self] (scrollView, change) in
            self?.handleDidScroll(change: change)
        })
        eventHandles = handles
    }
    
    private func updateDragging() {
        isDragging = scrollView.isTracking
    }
    
    private func handleDidScroll(change: NSKeyValueObservedChange<CGPoint>) {
        isDragging = scrollView.isTracking
        let isAtTop = scrollView.contentOffset.y < 60
        let isAtBottom = (scrollView.contentSize.height + scrollView.adjustedContentInset.bottom - scrollView.contentOffset.y - scrollView.frame.height) < 5
        if isAtTop {
            updateFactorIfDifferent(0, animated: true)
            return
        } else if isAtBottom {
            updateFactorIfDifferent(1, animated: true)
            return
        }
        guard scrollView.isTracking || inertiaTimer != nil else { return }
        if let condition = startingOffset {
            var relD = (scrollView.contentOffset.y - condition.offset.y) / halfHidingInterval
            if condition.factor > 0 {
                relD = condition.factor + relD
            }
            updateFactorIfDifferent(max(0, min(1, relD)), animated: false)
        } else {
            startingOffset = InitialCondition(offset: scrollView.contentOffset, factor: hidingFactor)
        }
    }
    
    private func updateFactorIfDifferent(_ factor: CGFloat, animated: Bool) {
        guard hidingFactor != factor else { return }
        hidingFactor = factor
        if animated {
            let handler = animateFactorChange ?? hidingFactorDidChange
            handler?()
        } else {
            hidingFactorDidChange?()
        }
    }
    
    private func handleStartDragging() {
        inertiaTimer?.invalidate()
        inertiaTimer = nil
    }
    
    private func handleEndDragging() {
        guard hidingFactor != 0 && hidingFactor != 1 else {
            startingOffset = nil
            return
        }
        inertiaTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) {[weak self] (_) in
            self?.snapHiddingFactor()
        }
    }
    
    private func snapHiddingFactor() {
        guard let condition = startingOffset else { return }
        inertiaTimer = nil
        startingOffset = nil
        var factor: CGFloat = 0
        if condition.factor > 0 {
            factor = ((condition.offset.y - scrollView.contentOffset.y) > halfHidingInterval / 2) ? 0 : 1
        } else {
            factor = ((scrollView.contentOffset.y - condition.offset.y) > halfHidingInterval / 2) ? 1 : 0
        }
        updateFactorIfDifferent(factor, animated: true)
    }
}

extension TabbarHidingSignalProducer {
    struct InitialCondition {
        let offset: CGPoint
        let factor: CGFloat
    }
}
