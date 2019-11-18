//
//  UpdateClock.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/25.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class UpdateClock {
    private var displayLink: CADisplayLink!
    private var actionTarget: DisplayLinkActionTarget
    
    convenience init(preferredInterval interval: TimeInterval = 1, runloopMode mode: RunLoop.Mode = .common, onTick: @escaping ()->Void) {
        self.init(preferredFrameRate: Int(1.0 / interval), runloopMode: mode, onTick: onTick)
    }
    
    init(preferredFrameRate: Int, runloopMode mode: RunLoop.Mode = .common, onTick: @escaping ()->Void) {
        actionTarget = DisplayLinkActionTarget(tickAction: onTick)
        displayLink = CADisplayLink(target: actionTarget, selector: #selector(DisplayLinkActionTarget.triggerUIUpdate(sender:)))
        displayLink.preferredFramesPerSecond = preferredFrameRate
        displayLink.add(to: .main, forMode: mode)
    }
    
    deinit {
        displayLink.invalidate()
    }
    
}

fileprivate extension UpdateClock {
    
    class DisplayLinkActionTarget {
        
        let tickAction: ()->Void
        
        init(tickAction: @escaping ()->Void) {
            self.tickAction = tickAction
        }
        
        @objc func triggerUIUpdate(sender: Any) {
            tickAction()
        }
        
    }
    
}
