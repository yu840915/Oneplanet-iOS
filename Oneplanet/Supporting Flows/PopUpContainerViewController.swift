//
//  PopUpContainerViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/4.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PopUpContainerViewController: UIViewController {

    private(set) var contentViewController: UIViewController!
    var contentViewControllerSetUpBlock: ((UIViewController)->())?
    var shouldAddConstraintToContentView = false
    @IBOutlet weak var contentContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentContainer.layer.cornerRadius = 8
        shouldAddConstraintToContentView = true
        updateViewConstraints()
    }
    
    override func updateViewConstraints() {
        if shouldAddConstraintToContentView {
            let content = contentViewController.view!
            content.translatesAutoresizingMaskIntoConstraints = false
            let container = content.superview!
            let views = ["content": content]
            container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[content]|", options: [], metrics: nil, views: views))
            container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", options: [], metrics: nil, views: views))
        }
        super.updateViewConstraints()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        assert(contentViewController == nil)
        contentViewControllerSetUpBlock?(segue.destination)
        contentViewController = segue.destination
        contentViewControllerSetUpBlock = nil
    }

}
