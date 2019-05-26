//
//  CharacterPickerViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class CharacterPickerViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController!.navigationBar.barStyle = .black
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}
