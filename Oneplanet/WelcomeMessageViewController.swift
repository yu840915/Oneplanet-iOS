//
//  WelcomeMessageViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class WelcomeMessageViewController: UIViewController, AuthorizationFlowEntryPoint {
    var authorizationCompletion: ((UserSession) -> ())!
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var skipButton: UIButton!
    private var contentViewController: WelcomeMessageContentCollectionViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        skipButton.setTitle(Localized.titles.skip, for: .normal)
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
        navigationController!.navigationBar.barStyle = .blackTranslucent
        updatePageControl()
        showSkipIfNeeded()
        UserProgressChecklist.watchWelcomeMessage.markAsFinished()
    }
    
    private func updatePageControl() {
        let shouldShow = contentViewController.imageReferences.count > 1
        pageControl.isHidden = !shouldShow
        if shouldShow {
            pageControl.numberOfPages = contentViewController.imageReferences.count
            pageControl.currentPage = contentViewController.currentIndex
        }
    }
    
    private func showSkipIfNeeded() {
        let shouldShow = (contentViewController.imageReferences.count - 1) == contentViewController.currentIndex
        if skipButton.isHidden {
            skipButton.isHidden = !shouldShow
        }
    }
    
    private func handleIndexChange() {
        updatePageControl()
        showSkipIfNeeded()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? WelcomeMessageContentCollectionViewController {
            vc.currentIndexDidChange = {[weak self] in
                self?.handleIndexChange()
            }
            vc.imageReferences = [NativeImageReference(image: UIImage(named: "im_first1")!), NativeImageReference(image: UIImage(named: "im_first2")!), NativeImageReference(image: UIImage(named: "im_first3")!)]
            contentViewController = vc
        }
        if let vc = segue.destination as? AuthorizationFlowEntryPoint {
            vc.authorizationCompletion = {[weak self] session in
                self?.authorizationCompletion(session)
            }
        }
    }

}
