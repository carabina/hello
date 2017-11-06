//
//  XMPlayerView.swift
//  VideoProgramDemo
//
//  Created by xuxueyong on 2017/9/29.
//  Copyright © 2017年 xinma. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class XMPlayerView: UIView {
    // 视频层
    fileprivate var playerLayer: AVPlayerLayer?
    // 播放器对象
    fileprivate var player: AVPlayer?
    // 播放资源
    fileprivate var playerItem: AVPlayerItem?
    // 黑色区域高度
    fileprivate let balckBagViewHeight = 40
    // 定时器
    fileprivate var link: CADisplayLink!
    // 是否正在播放
    fileprivate var isPlaying = true
    // 当前播放进度
    fileprivate var currentPlayProgress: CGFloat?
    // 当前缓冲进度
    fileprivate var currentBufferProgress: TimeInterval?
    // 初始frame
    var origanlFrame: CGRect?
    // 父视图 
    var iSuperView: UIView?
    // 屏幕状态
    var state: ScreenState = .smallScreen
    // 系统音量调节视图
    fileprivate var iVolumeSlider: UISlider!
    fileprivate var iVolumeView: MPVolumeView {
        let view = MPVolumeView()
        view.sizeToFit()
        for subView in view.subviews {
            print(subView.classForCoder)
            if NSStringFromClass(subView.classForCoder) == "MPVolumeSlider" {
                iVolumeSlider = subView as! UISlider
            }
        }
        return view
    }
    
    // 添加自定义button
    fileprivate lazy var iPanButton: XMPlayerButton = {
        let btn = XMPlayerButton()
        btn.delegate = self
        return btn
    }()
    
    // 屏幕🔒
    fileprivate lazy var iScreenLockButton: UIButton = {
        let btn = UIButton()
        btn.setImage(#imageLiteral(resourceName: "home_unlock_def"), for: .normal)
        btn.setImage(#imageLiteral(resourceName: "home_lock_def"), for: .selected)
        btn.addTarget(self, action: #selector(lockButtonClick(_:)), for: .touchUpInside)
        return btn
    }()
    
    // 退出全屏（返回）
    lazy var iExitFullScreenButton: UIButton = {
        let btn = UIButton()
        btn.setImage(#imageLiteral(resourceName: "nav_back_def"), for: .normal)
        btn.addTarget(self, action: #selector(exitFullScreen), for: .touchUpInside)
        return btn
    }()
    
    // 上面黑色区域
    fileprivate lazy var iTopBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.7
        return view
    }()
    
    // 下面黑色区域
    fileprivate lazy var iMenuView: XMPlayerMenuView = {
        let view = XMPlayerMenuView()
        view.backgroundColor = .black
        view.alpha = 0.7
        view.delegate = self
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        link = CADisplayLink(target: self, selector: #selector(update))
        link.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        
        iVolumeView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.width / 16 * 9)
        
        addSubview(iPanButton)
        iPanButton.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        addSubview(iTopBgView)
        iTopBgView.snp.makeConstraints { (make) in
            make.height.equalTo(balckBagViewHeight)
            make.top.left.right.equalTo(0)
        }
        
        iTopBgView.addSubview(iExitFullScreenButton)
        iExitFullScreenButton.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.width.equalTo(30)
            make.height.equalTo(30)
            make.centerY.equalTo(iTopBgView)
        }
        
        addSubview(iScreenLockButton)
        iScreenLockButton.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.centerY.equalTo(self)
        }
        
        addSubview(iMenuView)
        iMenuView.snp.makeConstraints { (make) in
            make.height.equalTo(balckBagViewHeight)
            make.left.right.bottom.equalTo(0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        playerLayer?.frame = bounds
    }
    
    func addPlayerSource(with url: String) {
        guard let url = URL(string: url) else { fatalError("链接错误") }
        
        // 创建视频资源
        playerItem = AVPlayerItem(url: url)
        // 监听状态改变
        playerItem!.addObserver(self, forKeyPath: PlayerObserveType.status.rawValue, options: NSKeyValueObservingOptions.new, context: nil)
        // 监听缓冲进度
        playerItem!.addObserver(self, forKeyPath: PlayerObserveType.buffer.rawValue, options: NSKeyValueObservingOptions.new, context: nil)
        // 监听缓存状态
        playerItem?.addObserver(self, forKeyPath: PlayerObserveType.bufferEmpty.rawValue, options: NSKeyValueObservingOptions.new, context: nil)
        playerItem?.addObserver(self, forKeyPath: PlayerObserveType.playKeep.rawValue, options: NSKeyValueObservingOptions.new, context: nil)
        // 将视频资源赋值给视频对象
        player = AVPlayer(playerItem: playerItem)
        // 初始化视频显示layer
        playerLayer = AVPlayerLayer(player: player)
        // 设置显示模式（aspect、fill）
        playerLayer?.contentsScale = UIScreen.main.scale
        playerLayer?.videoGravity = VideoVisualType.fill.rawValue
        // 位置放在最底下
        layer.insertSublayer(playerLayer!, at: 0)
    }
    
    deinit {
        playerItem?.removeObserver(self, forKeyPath: PlayerObserveType.status.rawValue)
        playerItem?.removeObserver(self, forKeyPath: PlayerObserveType.buffer.rawValue)
        playerItem?.removeObserver(self, forKeyPath: PlayerObserveType.bufferEmpty.rawValue)
        playerItem?.removeObserver(self, forKeyPath: PlayerObserveType.playKeep.rawValue)
    }
}

// MARK: - 处理监听事件

extension XMPlayerView {
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let playerItem = object as? AVPlayerItem else { return }
        if keyPath == PlayerObserveType.buffer.rawValue {
            // 缓冲进度处理
            let bufferSeconds = calculatorCurrentPlayerItemBuffer()
            let totalTime = CMTimeGetSeconds((player?.currentItem?.duration)!)
            let progress = bufferSeconds / totalTime
            iMenuView.iProgressBar.progress = Float(progress)
        } else if keyPath == PlayerObserveType.status.rawValue {
            if playerItem.status == .readyToPlay {
                player?.play()
                if !self.isPlaying {
                    self.player?.pause()
                }
            } else {
                player?.pause()
                print("加载异常")
            }
        } else if keyPath == PlayerObserveType.bufferEmpty.rawValue {
            print("缓冲不足")
            player?.pause()
        } else if keyPath == PlayerObserveType.playKeep.rawValue {
            print("缓冲完成，可继续播放")
            player?.play()
            if !self.isPlaying {
                self.player?.pause()
            }
        }
    }
}

// MARK: - 定时器更新

extension XMPlayerView {
    // 格式化时间
    func formatPlayTime(_ seconds: TimeInterval) -> String {
        if seconds.isNaN {
            return "00:00"
        }
        let minus = Int(seconds / 60)
        let second = Int(seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minus, second)
    }
    
    // link update
    func update() {
        // 暂停时，不用更新进度
        if !isPlaying {
            return
        }
        
        // 当前播放到的时间
        let currentTime = CMTimeGetSeconds((player?.currentTime())!)
        // 总时间
        let totalTime = TimeInterval((playerItem?.duration.value)!) / TimeInterval((playerItem?.duration.timescale)!) // timescale 时间压缩比
        
        // 拼接字符串
        let timeText = "\(formatPlayTime(currentTime))/\(formatPlayTime(totalTime))"
        // 更新播放时间
        iMenuView.iTimeLabel.text = timeText
        
         //  更新播放进度 (非拖拽情况下)
        if !iMenuView.isDragSlider {
            currentPlayProgress = CGFloat(currentTime / totalTime)
            iMenuView.iSlideBar.value = Float(currentPlayProgress!)
        }
    }
    
    // 计算当前player的缓冲进度
    func calculatorCurrentPlayerItemBuffer() -> TimeInterval {
        guard let loadedTimeRanges = player?.currentItem?.loadedTimeRanges, let first = loadedTimeRanges.first  else{
             return currentBufferProgress ?? 0
        }
        let timeRange = first.timeRangeValue
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let duration = CMTimeGetSeconds(timeRange.duration)
        let result = startSeconds + duration
        currentBufferProgress = result
        return result
    }
}

// MARK: - XMPlayerMenuViewDelegate

extension XMPlayerView: XMPlayerMenuViewDelegate {
    
    func sliderTouchUpOutSide(_ slider: UISlider) {
        if player?.status == AVPlayerStatus.readyToPlay {
            let duration = slider.value * Float(CMTimeGetSeconds((player?.currentItem?.duration)!))
            if duration.isNaN {
                return
            }
            let seekTime = CMTimeMake(Int64(duration), 1)
            player?.pause()
            // 指定视频播放进度位置
            player?.seek(to: seekTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { (b) in
                // code
            })
        }
    }
    
    func playOrPauseEvent(_ button: UIButton) {
        button.isSelected = isPlaying
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else if player?.status == AVPlayerStatus.readyToPlay {
            player?.play()
            isPlaying = true
        }
    }
    
    func fullScreenButtonDidClick(_ button: UIButton) {
        entranceFullScreen()
        
    }
    

    // 进入全屏
    func entranceFullScreen() {
        if state != .smallScreen { return }
        state = .animating
        
        // 记录进入全屏时的 frame 和 父视图
        origanlFrame = frame
        iSuperView = superview
        
        // 将视图移到 window上
        let windowRect = convert(frame, to: UIApplication.shared.keyWindow)
        removeFromSuperview()
        frame = windowRect
        UIApplication.shared.keyWindow?.addSubview(self)
        
        // 执行动画
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let `self` = self else { return }
            self.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2);
            let screenHeight = self.superview?.frame.size.height
            let screenWidth = self.superview?.frame.size.width
            self.snp.remakeConstraints({ (make) in
                make.width.equalTo(screenHeight!)
                make.height.equalTo(screenWidth!)
                make.left.equalTo((screenWidth! - screenHeight!) * 0.5)
                make.top.equalTo((screenHeight! - screenWidth!) * 0.5)
            })
            self.layoutIfNeeded()
        }) { [weak self] (b) in
            guard let `self` = self else { return }
            self.state = .fullScreen
        }
        refreshStatusBarOrientation(.landscapeRight)
    }
    
    // 退出全屏
    func exitFullScreen() {
        if state != .fullScreen { return }
        state = .animating
        
        let tempFrame = iSuperView?.convert(origanlFrame!, to: UIApplication.shared.keyWindow)
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let `self` = self else { return }
            self.transform = CGAffineTransform.identity
            self.frame = tempFrame!
            self.removeFromSuperview()
            self.iSuperView?.addSubview(self)
            self.snp.remakeConstraints({ (make) in
                make.top.left.right.equalTo(0)
                make.width.equalTo((self.origanlFrame?.size.width)!)
                make.height.equalTo((self.origanlFrame?.size.height)!)
            })
            self.layoutIfNeeded()
        }) { [weak self] (b) in
            guard let `self` = self else { return }
            self.state = .smallScreen
        }
        refreshStatusBarOrientation(.portrait)
    }
    
    func refreshStatusBarOrientation(_ orientation: UIInterfaceOrientation) {
        UIApplication.shared.setStatusBarOrientation(orientation, animated: true)
    }
}


// MARK: - XMPlayerButtonDelegate

extension XMPlayerView: XMPlayerButtonDelegate {
    
    // 开始触摸
    func touchesBeganWithPoint(_ point: CGPoint) {
        // 记录触摸的点
        iPanButton.startPoint = point
        
        // 记录音量、或者亮度
        if point.x <= self.frame.size.width * 0.5 {
            iPanButton.startVB = UIScreen.main.brightness
        } else {
            iPanButton.startVB = CGFloat(iVolumeSlider.value)
        }
        
        // 记录当前播放的进度
        let currentTime = CMTimeGetSeconds((player?.currentTime())!)
        let totalTime = TimeInterval((playerItem?.duration.value)!) / TimeInterval((playerItem?.duration.timescale)!)
        iPanButton.startPlayProgress = CGFloat(currentTime / totalTime)
    }
    
    // 手指滑动
    func touchesMoveWithPoint(_ point: CGPoint) {
        // 计算手指滑动的距离
        let panPoint = CGPoint(x: point.x - (iPanButton.startPoint?.x)!, y: point.y - (iPanButton.startPoint?.y)!)
        
        // 判断手指滑动的方向
        if iPanButton.direction == .directionNone {
            let absX = abs(panPoint.x)
            let absY = abs(panPoint.y)
            
            if absX > 10 &&  absY > 10 {
                if absX > absY {
                    iPanButton.direction = .directionLeftOrRight
                } else {
                   iPanButton.direction = .directionUpOrDown
                }
            }
        }
        
        if iPanButton.direction == .directionNone {
            return
        } else if iPanButton.direction == .directionUpOrDown {
            // 调节亮度
            if (iPanButton.startPoint?.x)! <= self.frame.size.width * 0.5 {
                
                 UIScreen.main.brightness = iPanButton.startVB! - panPoint.y / 30 / 10
            } else {
            // 调节音量
                if panPoint.y < 0 {
                    iVolumeSlider.value =  Float(iPanButton.startVB! + -panPoint.y / 30 / 20)
                    if Float(iPanButton.startVB! + -panPoint.y / 30 / 20) - iVolumeSlider.value >= 0.1 {
                        iVolumeSlider.value = 0
                       iVolumeSlider.value =  Float(iPanButton.startVB! + -panPoint.y / 20 / 10)
                    }
                } else {
                    iVolumeSlider.value = Float(iPanButton.startVB! - panPoint.y / 30 / 20)
                }
            }
        } else if iPanButton.direction == .directionLeftOrRight {
            currentPlayProgress = iPanButton.startPlayProgress! + panPoint.x / 30 / 20
            if currentPlayProgress! > 1 {
                currentPlayProgress = 1
            } else if currentPlayProgress! < 0 {
                currentPlayProgress = 0
            }
        }
    }
    
    // 结束触摸
    func touchesEndWithPoint(_ point: CGPoint) {
        
        if iPanButton.direction == .directionLeftOrRight {
            iMenuView.iSlideBar.value = Float(currentPlayProgress!)
            sliderTouchUpOutSide(iMenuView.iSlideBar)
        }
        iPanButton.direction = .directionNone
    }
    
    // 隐藏OR显示 上下黑色区域
    func screenDidClick() {
        if iScreenLockButton.isSelected {
            iScreenLockButton.isHidden = !iScreenLockButton.isHidden
        } else {
            iMenuView.isHidden = !iMenuView.isHidden
            iTopBgView.isHidden = !iTopBgView.isHidden
            iScreenLockButton.isHidden = !iScreenLockButton.isHidden
        }
    }
}

// MARK: - 屏幕锁点击
extension XMPlayerView {
    
    func lockButtonClick(_ button: UIButton) {
        button.isSelected = !button.isSelected
        if button.isSelected {
             iMenuView.isHidden = true
            iTopBgView.isHidden = true
        } else {
            iMenuView.isHidden = false
            iTopBgView.isHidden = false
        }
    }
}

// 屏幕状态
enum ScreenState {
    case fullScreen
    case smallScreen
    case animating
}

// 视频显示模式
enum VideoVisualType: String {
    case aspect = "AVLayerVideoGravityResizeAspect"
    case fill = "AVLayerVideoGravityResizeAspectFill"
}

// 监听类型
enum PlayerObserveType: String {
    case status = "status"
    case buffer = "loadedTimeRanges"
    // 缓存不足
    case bufferEmpty = "playbackBufferEmpty"
    // 缓存完成可继续播放
    case playKeep = "playbackLikelyToKeepUp"
}
