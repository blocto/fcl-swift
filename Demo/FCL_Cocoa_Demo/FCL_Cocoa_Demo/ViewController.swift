//
//  ViewController.swift
//  FCL_Cocoa_Demo
//
//  Created by Andrew Wang on 2022/7/7.
//

import UIKit
import FCL

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        fcl.config
            .put(.network(.testnet))
    }


}

