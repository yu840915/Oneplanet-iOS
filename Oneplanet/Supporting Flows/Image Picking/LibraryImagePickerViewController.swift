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

    override func viewDidLoad() {
        super.viewDidLoad()
        if let item = photoList.first {
            updateSelectedItemIfNeeded(item)
        }
    }
    
    private func updateSelectedItemIfNeeded(_ item: PhotoListItem) {
        guard selectedPhoto !== item else {
            return
        }
        selectedPhoto = item
        fetchImageForSelectedItem()
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
        imageView.image = op.image
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
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
