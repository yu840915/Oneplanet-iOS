//
//  UIComponentFactories.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class BarButtonItemFactory {
    private init(){}
    static let shared = BarButtonItemFactory()
    
    func makeTitlelessBack() -> UIBarButtonItem {
        return UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
    }
}

class TextAttachmentFactory {
    private init(){}
    static let shared = TextAttachmentFactory()
    
    func arrowDown() -> NSTextAttachment {
        let arrow = NSTextAttachment()
        let img = #imageLiteral(resourceName: "ic_filterdown_nor")
        arrow.image = img
        arrow.bounds = CGRect(origin: CGPoint(x: 0, y: 2), size: CGSize(width: img.size.width, height: img.size.height))
        return arrow
    }
}
