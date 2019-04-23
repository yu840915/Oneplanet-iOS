//
//  LibraryImagePickerViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/23.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class LibraryImagePickerViewController: UIViewController {
    
    @IBOutlet weak var cancelButtonItem: UIBarButtonItem!
    @IBOutlet weak var doneButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var imageScrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var avatarIndicator: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LibraryImagePickerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
