//
//  WebViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/28.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {
    var webView: WKWebView!
    private var shouldAddConstraintsForWebView = false
    var exitTitle = Localized.titles.cancel
    var request: URLRequest? {
        didSet {
            if isViewLoaded && oldValue != request {
                startRequest()
            }
        }
    }
    @IBOutlet weak var exitButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        exitButtonItem.title = exitTitle
        setUpWebView()
        startRequest()
    }
    
    private func setUpWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: self.view.frame, configuration: webConfiguration)
        view.addSubview(webView)
        shouldAddConstraintsForWebView = true
        updateViewConstraints()
    }
    
    private func startRequest() {
        guard let req = request else {
            return
        }
        webView.load(req)
    }
    
    override func updateViewConstraints() {
        if shouldAddConstraintsForWebView {
            shouldAddConstraintsForWebView = false
            webView.translatesAutoresizingMaskIntoConstraints = false
            let views: [String : Any] = ["webView": webView]
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[webView]|", options: [], metrics: nil, views: views))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[webView]|", options: [], metrics: nil, views: views))
        }
        super.updateViewConstraints()
    }

    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
