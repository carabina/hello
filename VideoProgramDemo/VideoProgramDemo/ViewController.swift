//
//  ViewController.swift
//  VideoProgramDemo
//
//  Created by xuxueyong on 2017/9/29.
//  Copyright © 2017年 xinma. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        playVideo()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    func playVideo() {
        let playerView = XMPlayerView()
//        playerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width / 16 * 9)
////        UIScreen.main.bounds.width / 16 * 9
        playerView.addPlayerSource(with: "http://vodcdn.yst.vodjk.com/201710091426/7f37bfb7139aa6f5543aa80f74883a61/company/1/2017/2/5/102031f7zucbrhss7uo3l3di/sd/ace07cbdbf0c40cb94b50dfab232178c.m3u8")
        view.addSubview(playerView)
        playerView.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(0)
            make.height.equalTo(UIScreen.main.bounds.width / 16 * 9)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

