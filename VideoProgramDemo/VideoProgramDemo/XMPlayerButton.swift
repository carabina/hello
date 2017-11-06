//
//  XMPlayerButton.swift
//  VideoProgramDemo
//
//  Created by xuxueyong on 2017/9/30.
//  Copyright © 2017年 xinma. All rights reserved.
//

import UIKit

protocol XMPlayerButtonDelegate: class {
    
    func touchesBeganWithPoint(_ point: CGPoint)
    func touchesMoveWithPoint(_ point: CGPoint)
    func touchesEndWithPoint(_ point: CGPoint)
    
    func screenDidClick()
}

/**
    进度、亮度、音量调节
    通过touchesBegan、 touchesMove、 touchesEnd  
    不用UIPanGestureRecg， 防止手饰冲突、和滑动方向不确定
 
    通过获取方向值，和各个方向上的值大于 30 才触发响应的事件
 
 */
class XMPlayerButton: UIButton {
    var delegate: XMPlayerButtonDelegate?
    // 记录开始触摸的坐标
    var startPoint: CGPoint?
    // 记录开始滑动时的音量、亮度
    var startVB: CGFloat?
    // 记录滑动方向
    var direction: Direction = .directionNone
    // 记录开始滑动时的播放进度
    var startPlayProgress: CGFloat?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let point = touch?.location(in: self)
        guard let de = delegate else { return }
        de.touchesBeganWithPoint(point!)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let point = touch?.location(in: self)
        guard let de = delegate else { return }
        de.touchesMoveWithPoint(point!)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let point = touch?.location(in: self)
        guard let de = delegate else { return }
        de.touchesEndWithPoint(point!)
        de.screenDidClick()
        
    }
}

// 手指滑动方向
enum Direction {
    case directionLeftOrRight
    case directionUpOrDown
    case directionNone
}
