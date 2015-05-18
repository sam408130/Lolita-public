//
//  ChangeNameViewController.swift
//  Lolita-public
//
//  Created by Sam on 5/5/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import UIKit

class ChangeNameViewController: UIViewController , ConversationOperationDelegate{
    
    
    var _textField = UITextField()
    var oldName : String = ""
    var delegate = ConversationOperationDelegate?()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frameSize : CGSize = self.view.frame.size
        _textField = UITextField(frame: CGRectMake(10, 94, frameSize.width - 20, 30))
        _textField.font = UIFont.systemFontOfSize(18)
        _textField.text = self.oldName
        _textField.placeholder = "please input something..."
        _textField.borderStyle = UITextBorderStyle.RoundedRect
        self.view.addSubview(_textField)
        self.view.backgroundColor = UIColor.whiteColor()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: UIBarButtonItemStyle.Plain, target: self, action: "pressedButtonOK:")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    
    func pressedButtonOK(sender:AnyObject){
        let newValue:String = _textField.text
        let conv = AVIMConversation()
        if ( newValue.compare(self.oldName) != NSComparisonResult.OrderedSame ){
                self.delegate!.changeName!(newValue, conversation: nil)
            }
        self.navigationController?.popViewControllerAnimated(true)
        
    }
}
