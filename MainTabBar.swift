//
//  MainTabBar.swift
//  Lolita-public
//
//  Created by Sam on 4/26/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import UIKit

class MainTabBar: UITabBar {

    var composedButtonClicked:(()->())?
    
    override func awakeFromNib() {
        self.addSubview(composeBtn!)
        self.backgroundColor = UIColor(patternImage: UIImage(named: "tabbar_background")!)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        /// 设置按钮位置
        setButtonFrame()
    }
    
    func setButtonFrame(){
        
        let buttonCount = 5
        
        let w = self.bounds.width/CGFloat(buttonCount)
        let h = self.bounds.height
        
        var index = 0
        
        for view in self.subviews as![UIView]{
            if view is UIControl && !(view is  UIButton){
                let r = CGRectMake(CGFloat(index) * w, 0, w, h)
                
                view.frame = r
                
                /// 如果是后两个 就往右边靠
                index++
                if index == 2 {
                    index++
                }
                //                println(index)
            }
        }
        //composeBtn!.frame = CGRectMake(0, 0, w, h)
        //composeBtn!.center = CGPointMake(self.center.x, h * 0.5)
        
        
    }
    /// 创建撰写微博按钮
    lazy var composeBtn: UIButton? = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "tabbar_compose_icon_add"), forState: UIControlState.Normal)
        btn.setImage(UIImage(named: "tabbar_compose_icon_add_highlighted"), forState: UIControlState.Highlighted)
        btn.setBackgroundImage(UIImage(named: "tabbar_compose_button"), forState: UIControlState.Normal)
        btn.setBackgroundImage(UIImage(named: "tabbar_compose_button_highlighted"), forState: UIControlState.Highlighted)
        
        // 添加按钮的监听方法
        btn.addTarget(self, action: "clickCompose", forControlEvents: .TouchUpInside)
        
        return btn
        
        }()
    
    func clickCompose(){
        println("发微博")
        if composedButtonClicked != nil{
            composedButtonClicked!()
        }
    }
}
