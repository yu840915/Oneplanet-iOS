//
//  IAPTestViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/18.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class IAPTestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func purchase(_ sender: Any) {
        let i = Invoice(iapProduct: IAPTransactionProcessor.shared.blueGemRelatedProducts.rubyProduct!, associatedProductID: nil)!
        IAPTransactionProcessor.shared.placeOrder(with: i)
    }
    
    
    @IBAction func showReceipt(_ sender: Any) {
        if let data = IAPTransactionProcessor.shared.readReceipt() {
            debugPrint(data.base64EncodedString())
        }
    }
}
