//
//  LibraryImagePickerViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/23.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class LibraryImagePickerViewController: UIViewController, DefaultInstanceFactory {
    class func fromDefaultStoryboard() -> UINavigationController {
        return UIStoryboard(name: "SupportingFlows", bundle: nil).instantiateViewController(withIdentifier: "LibraryImagePickerEntryPoint") as! UINavigationController
    }
    @IBOutlet weak var cancelButtonItem: UIBarButtonItem!
    @IBOutlet weak var doneButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var imageScrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var avatarIndicator: UIImageView!
    var onCancel: (()->())?
    var onPickingImage: ((UIImage)->())?
    var photoGridViewController: PhotoGridCollectionViewController!
    var photoList: PhotoList = PhotoList()
    private var selectedPhoto: PhotoListItem?
    private var fetchImageOperation: FetchImageOperaion?
    private var selectedImage: UIImage?
    @IBOutlet var imageWidthSnap: NSLayoutConstraint!
    @IBOutlet var imageHeightSnap: NSLayoutConstraint!
    private var imageAspectRatio: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let item = photoList.first {
            updateSelectedItemIfNeeded(item)
        }
        updateViewsForStates()
    }
    
    private func updateSelectedItemIfNeeded(_ item: PhotoListItem) {
        guard selectedPhoto !== item else {
            return
        }
        selectedPhoto = item
        fetchImageForSelectedItem()
    }
    
    private func updateViewsForStates() {
        doneButtonItem.isEnabled = selectedImage != nil
    }
    
    private func fetchImageForSelectedItem() {
        guard let photo = selectedPhoto else {return}
        guard fetchImageOperation?.asset != photo.asset else {
            return
        }
        fetchImageOperation?.cancel()
        let width = imageView.bounds.width * UIScreen.main.scale
        let op = FetchImageOperaion(asset: photo.asset, targetSize: CGSize(width: width, height: width))
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didFetchImage()
            }
        }
        fetchImageOperation = op
        op.start()
    }
    
    private func didFetchImage() {
        guard let photo = selectedPhoto else {return}
        guard let op = fetchImageOperation,
            op.asset == photo.asset else {
                fetchImageOperation = nil
                return
        }
        fetchImageOperation = nil
        if let image = op.image {
            setUpImage(image)
        }
    }
    
    private func setUpImage(_ image: UIImage) {
        imageScrollView.zoomScale = 1.0
        imageScrollView.maximumZoomScale = computeMaxZoomScale(for: image)
        imageHeightSnap.isActive = false
        imageWidthSnap.isActive = false
        if image.size.height > image.size.width {
            imageWidthSnap.isActive = true
        } else {
            imageHeightSnap.isActive = true
        }
        imageView.image = image
        if let layout = imageAspectRatio {
            imageView.removeConstraint(layout)
        }
        let layout = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: image.size.width / image.size.height, constant: 0)
        selectedImage = image
        imageView.addConstraint(layout)
        imageAspectRatio = layout
        imageScrollView.setNeedsLayout()
        updateViewsForStates()
    }
    
    private func computeMaxZoomScale(for image: UIImage) -> CGFloat {
        let w = image.size.width / imageView.bounds.width
        let h = image.size.height / imageView.bounds.height
        return max(1, min(w, h, 2.0))
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        guard let image = selectedImage, !imageScrollView.isDragging else { return }
        cropImageAndNotify(image)
    }
    
    private func cropImageAndNotify(_ image: UIImage) {
        guard let ciImg = CIImage(image: image)?.cropped(to: cropRect(for: image)) else {
            return
        }
        let result = UIImage(ciImage: ciImg)
        onPickingImage?(result)
    }
    
    private func cropRect(for image: UIImage) -> CGRect {
        let multiplier = image.size.width / imageScrollView.contentSize.width
        let size = imageScrollView.frame.size
        var origin = imageScrollView.contentOffset
        origin.y = imageScrollView.contentSize.height - origin.y - size.height
        return CGRect(x: origin.x * multiplier, y: origin.y * multiplier, width: size.width * multiplier, height: size.height * multiplier)

    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        onCancel?()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PhotoGridCollectionViewController {
            photoGridViewController = vc
            vc.photoList = photoList
            vc.itemSelectionHandler = {[weak self] item in
                self?.updateSelectedItemIfNeeded(item)
            }
        }
    }

}

extension LibraryImagePickerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
