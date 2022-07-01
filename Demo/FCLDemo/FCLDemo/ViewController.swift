//
//  ViewController.swift
//  FCLDemo
//
//  Created by Andrew Wang on 2022/6/29.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    let webView: WKWebView = .init()
    
    var urlObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        urlObservation = webView.observe(\.url, options: [.old, .new]) { webView, change in
            print("🏷 url: \(String(describing: webView.url))")
        }
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let url = URL(string: "https://wallet-testnet.blocto.app/sdk?app_id=64776cec-5953-4a58-8025-772f55a3917b&request_id=7168F3E5-E582-4CFA-948F-92F5198BEB57&blockchain=solana&method=request_account")!
        let request = URLRequest(url: url)
        webView.load(request)
        // Do any additional setup after loading the view.
    }

}
