//
//  CommentListCell.swift
//  Lolita-public
//
//  Created by Sam on 5/1/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import Foundation

import UIKit

class CommentListCell: UITableViewCell {
    
    
    @IBOutlet weak var avatarImage: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var commentInfoLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var sepratorHeightContraint: NSLayoutConstraint!
    
    @IBOutlet weak var sepratorView: UIImageView!
    
    
    var singleComment : SingleComment? {
        didSet{
            usernameLabel.text = singleComment!.commentUserName
            commentInfoLabel.text = singleComment!.commentInfo
            timeLabel.text = singleComment!.commentTime
            if let iconUrl = singleComment?.commentUserAvatar {
                NetworkManager.sharedManager.requestImage(iconUrl) { (result, error) -> () in
                    if let image = result as? UIImage {
                        self.avatarImage.image = image
                    }
                }
            }
            
        }
    }
    
    class var identifier : String {
        get {
            return "CommentListCell"
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        sepratorHeightContraint.constant = 1.0 / UIScreen.mainScreen().scale
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
