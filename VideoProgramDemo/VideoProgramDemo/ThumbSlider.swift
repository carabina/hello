//
//  ThumbSlider.swift
//  VideoProgramDemo
//
//  Created by xuxueyong on 2017/9/29.
//  Copyright © 2017年 xinma. All rights reserved.
//

import UIKit

class ThumbSlider: UISlider {
    
    var lastBounds: CGRect?
    let SLIDER_Y_BOUND: CGFloat = 20

    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var tempRect = rect
        tempRect.origin.x = rect.origin.x
        tempRect.size.width = rect.size.width
        let result = super.thumbRect(forBounds: bounds, trackRect: tempRect, value: value)
        //记录下最终的frame
        lastBounds = result
        return result
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        //调用父类方法,找到能够处理event的view
        var result = super.hitTest(point, with: event)
        if result != self {
            /*如果这个view不是self,我们给slider扩充一下响应范围,
             这里的扩充范围数据就可以自己设置了
             */
            if point.y >= -15 &&
                point.y < ((lastBounds?.size.height)! + SLIDER_Y_BOUND) &&
                point.x >= 0 && point.x < self.bounds.width {
                //如果在扩充的范围类,就将event的处理权交给self
                result = self
            }
        }
        //否则,返回能够处理的view
        return result
    }
}
