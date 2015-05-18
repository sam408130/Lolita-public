//
//  CommentCell.swift
//  Lolita-public
//
//  Created by Sam on 5/1/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import Foundation

import UIKit

class CommentCell: UITableViewCell {
    
    
    @IBOutlet weak var sepratorImageView: UIImageView!
    
    @IBOutlet weak var sepratorHeightConstraint: NSLayoutConstraint!
    
    class var identifier : String{
        get{
            return "CommentCell"
        }
    }
    
    @IBOutlet weak var commentTextField: UITextField!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commentTextField.placeholder = "随手写点？"
        sepratorHeightConstraint.constant = 1.0 / UIScreen.mainScreen().scale
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

extension CommentCell : UITextFieldDelegate {
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if contains(string , "\n"){
            textField.resignFirstResponder()
            return false
        }
        return true
    }
}