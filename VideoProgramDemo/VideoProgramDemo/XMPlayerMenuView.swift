//
//  XMPlayerMenuView.swift
//  VideoProgramDemo
//
//  Created by xuxueyong on 2017/9/29.
//  Copyright © 2017年 xinma. All rights reserved.
//

import UIKit

protocol XMPlayerMenuViewDelegate: class {
    // slider 拖拽
    func sliderTouchUpOutSide(_ slider: UISlider)
    // 播放／暂停
    func playOrPauseEvent(_ button: UIButton)
    // 全屏 ／ 退出全屏
    func fullScreenButtonDidClick(_ button: UIButton)
    
}

class XMPlayerMenuView: UIView {
    // 是否拖拽sliderBar
    var isDragSlider = false
    
    var delegate: XMPlayerMenuViewDelegate?
    
    // 播放／暂停
    lazy var iPlayOrPauseButton: UIButton = {
        let btn = UIButton()
        btn.setImage(#imageLiteral(resourceName: "video_stop_def"), for: .normal)
        btn.setImage(#imageLiteral(resourceName: "video_start_def"), for: .selected)
        btn.addTarget(self, action: #selector(playOrPauseButtonClick(button:)), for: .touchUpInside)
        return btn
    }()
    
    // 时间显示
    lazy var iTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "03:04 / 04:40"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    // 拖拽条
    lazy var iSlideBar: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.minimumTrackTintColor = .cyan
        slider.maximumTrackTintColor = .clear
        slider.setThumbImage(#imageLiteral(resourceName: "video_progress_img"), for: .normal)
        slider.addTarget(self, action: #selector(sliderTouchDown(slider:)), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderTouchUpOutside(slider:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderTouchUpOutside(slider:)), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(sliderTouchUpOutside(slider:)), for: .touchCancel)
        return slider
    }()
    
    // 进度条
    lazy var iProgressBar: UIProgressView = {
        let bar = UIProgressView()
        bar.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        bar.progressTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
        return bar
    }()
    
    // 全屏/退出 按钮
    lazy var iFullScreenButton: UIButton = {
        let btn = UIButton()
        btn.setImage(#imageLiteral(resourceName: "video_zoom_def"), for: .normal)
        btn.setImage(#imageLiteral(resourceName: "video_reduce_def"), for: .selected)
        btn.addTarget(self, action: #selector(fullScreenButtonClick(_:)), for: .touchUpInside)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iPlayOrPauseButton)
        iPlayOrPauseButton.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.width.equalTo(30)
            make.height.equalTo(30)
            make.centerY.equalTo(self)
        }
        
        addSubview(iTimeLabel)
        iTimeLabel.snp.makeConstraints { (make) in
            make.width.equalTo(90)
            make.height.equalTo(20)
            make.centerY.equalTo(self)
            make.left.equalTo(iPlayOrPauseButton.snp.right).offset(10)
        }
        
        addSubview(iFullScreenButton)
        iFullScreenButton.snp.makeConstraints { (make) in
            make.width.equalTo(30)
            make.height.equalTo(30)
            make.right.equalTo(-10)
            make.centerY.equalTo(self)
        }
        
        addSubview(iSlideBar)
        iSlideBar.snp.makeConstraints { (make) in
            make.centerY.equalTo(self)
            make.height.equalTo(19)
            make.left.equalTo(iTimeLabel.snp.right).offset(10)
            make.right.equalTo(iFullScreenButton.snp.left).offset(-10)
        }
        
        insertSubview(iProgressBar, belowSubview: iSlideBar)
        iProgressBar.snp.makeConstraints { (make) in
            make.centerY.equalTo(iSlideBar)
            make.left.right.equalTo(iSlideBar)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: -  按钮点击事件
extension XMPlayerMenuView {

    func sliderTouchDown(slider: UISlider) {
        isDragSlider = true
    }
    
    func sliderTouchUpOutside(slider: UISlider) {
        guard let de = delegate else { return }
        de.sliderTouchUpOutSide(slider)
    }
    
    func playOrPauseButtonClick(button: UIButton) {
        guard let de = delegate else { return }
        de.playOrPauseEvent(button)
    }
    
    func fullScreenButtonClick(_ button: UIButton) {
        guard let de = delegate else { return }
        de.fullScreenButtonDidClick(button)
    }
}
