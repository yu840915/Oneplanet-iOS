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
    var shouldAddConstraintToDismissView = false
    @IBOutlet weak var contentContainer: UIView!
    private var dismissTap: UITapGestureRecognizer!
    private var dismissView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentContainer.layer.cornerRadius = 8
        shouldAddConstraintToContentView = true
        setUpDismissTap()
        updateViewConstraints()
    }
    
    private func setUpDismissTap() {
        let dismiss = UIView()
        dismiss.backgroundColor = .clear
        view.addSubview(dismiss)
        view.sendSubviewToBack(dismiss)
        dismissView = dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(exit(_:)))
        tap.isEnabled = false
        dismiss.addGestureRecognizer(tap)
        dismissTap = tap
        shouldAddConstraintToDismissView = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dismissTap.isEnabled = true
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
        if shouldAddConstraintToDismissView {
            let content = dismissView!
            content.translatesAutoresizingMaskIntoConstraints = false
            let views = ["content": content]
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[content]|", options: [], metrics: nil, views: views))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", options: [], metrics: nil, views: views))
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
