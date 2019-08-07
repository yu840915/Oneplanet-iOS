//
//  PostPhotoPickingFlowViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/7.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class PostPhotoPickingFlowViewController: ButtonBarPagerTabStripViewController, UserSessionDepending {

    var userSession: UserSession!
    var onPickingImage: ((UIImage)->())?
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        changeCurrentIndexProgressive = {[weak self] (oldCell, newCell, progressPercentage, changeCurrentIndex, animated) in
            self?.updateButtonBarCell(oldCell: oldCell, newCell: newCell, progressPercentage: progressPercentage, changeCurrentIndex: changeCurrentIndex, animated: animated)
            if changeCurrentIndex {
                self?.updateNavigationItems()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        PagerStyleConfigurer().configure(self)
        settings.style.selectedBarHeight = 0
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        var val = [UIViewController]()
        if AskForCameraAuthorizationOperation.authorizationStatus == .authorized {
            let op = PrepareCaptureSessionOperation(initialCameraPosition: .back)
            op.start()
            if let controller = op.captureSessionController {
                let photo = CameraImagePickerViewController.fromDefaultStoryboard()
                photo.captureSessionController = controller
                photo.onPickingImage = {[weak self] image in
                    self?.onPickingImage(image)
                }
                photo.onCancel = {[weak self] in
                    self?.exit()
                }
                val.append(photo)
            }
        }
        if AskForPhotoLibraryAuthorizationOperation.authorizationStatus == .authorized {
            let lib = LibraryImagePickerViewController.fromDefaultStoryboard()
            lib.hasPadding = true
            lib.onPickingImage = {[weak self] image in
                self?.onPickingImage(image)
            }
            lib.onCancel = {[weak self] in
                self?.exit()
            }
            val.append(lib)
        }
        return val
    }
    
    func updateButtonBarCell(oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) {
        guard changeCurrentIndex else { return }
        oldCell?.label.textColor = PagerStyleConfigurer.Style.normal.titleColor
        newCell?.label.textColor = PagerStyleConfigurer.Style.highlighted.titleColor
        oldCell?.label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        newCell?.label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    }
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: (view.frame.width / 2), height: 40)
    }
    
    func updateNavigationItems() {
        let vc = viewControllers[currentIndex]
        navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems
        navigationItem.leftBarButtonItem = vc.navigationItem.leftBarButtonItem
        navigationItem.titleView = nil
        if let view = vc.navigationItem.titleView {
            navigationItem.titleView = view
        } else {
            navigationItem.title = vc.navigationItem.title
        }
    }
    
    private func exit() {
        dismiss(animated: true, completion: nil)
    }
    
    private func onPickingImage(_ image: UIImage) {
        onPickingImage?(image)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}
