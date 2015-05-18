//
//  CommentViewController.swift
//  Lolita-public
//
//  Created by Sam on 5/1/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import Foundation

import UIKit


class CommentViewController: UITableViewController {
    
    var feedData =  Feed()
    var commentsData : CommentsData?
    
    let currentUserName : String = AVUser.currentUser()!.username!
    var currentUserAvatarImageUrl = (AVUser.currentUser().objectForKey("avatarImage") as! AVFile).url
    

    private weak var commentTextField: UITextField!
    
    
    lazy var rowHeightCache: NSCache? = {
        return NSCache()
        }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reload()
        tableView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    func reload(){
    
        println("加载数据")
        
        refreshControl?.beginRefreshing()
        
        weak var weakSelf = self
        
        CommentsData.loadComments("Comments",feedData.id!) { (data, error) -> () in
            
            weakSelf!.refreshControl?.endRefreshing()
            
            if error != nil{
                println(error)
                SVProgressHUD.showInfoWithStatus("网络繁忙请重试")
            }
            if data != nil{
                
                weakSelf?.commentsData = data
                weakSelf?.tableView.reloadData()

                
            }
        }

    
    }
    
    
    
    @IBAction func sendButtonPressed(sender: UIButton) {
        
        let content = commentTextField.text
        if count(content) == 0 {
            alert("不能回复空消息")
        }else{
            var commentObject = AVObject(className: "Comments")
            var addingComment = SingleComment()
            
            commentObject["feedID"] = feedData.id
            addingComment.feedID = feedData.id
            
            commentObject["commentInfo"] = content
            addingComment.commentInfo = content
            
            commentObject["commentUserID"] = AVUser.currentUser()?.objectId
            addingComment.commentUserName = currentUserName
            
            addingComment.commentTime = "刚刚"
            addingComment.commentUserAvatar = currentUserAvatarImageUrl
            
            commentObject.saveInBackground()
            commentsData?.comments.insert(addingComment, atIndex: 0)
            
            commentTextField.text = ""
            commentTextField.placeholder = "随手写点吧"
            
            println(commentsData?.comments)
            
            tableView.reloadData()
        }
        
    }
    

    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return 1
        case 1:
            return self.commentsData?.comments.count ?? 0
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        // Configure the cell...
        
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCellWithIdentifier("homeCell", forIndexPath: indexPath) as! HomeFeedsCell
            let cell = cell as! HomeFeedsCell
            //let cell = tableView.dequeueReusableCellWithIdentifier("CellIdentifier") as! Cell
            cell.status = feedData
            if cell.photoDidSelected == nil{
                cell.photoDidSelected = { (status:Feed!,index:Int)-> Void in
                    //                println("\(status.text) \(index)")  // $$$$$
                    weak var weakSelf = self
                    
                    
                    
                    let vc = PhotoBrowserlViewController.photoBrowserViewController()
                    
                    vc.urls = status.postImageUrls
                    vc.selectedIndex = index
                    //vc.modalTransitionStyle = UIModalTransitionStyle.PartialCurl
                    
                    weakSelf!.presentViewController(vc, animated: true, completion: nil)
                    
                }
            }
            cell.delegate = self
            cell.indexPath = indexPath
            
        case 1:
            cell = tableView.dequeueReusableCellWithIdentifier("commentListCell") as! CommentListCell
            let cell = cell as! CommentListCell
            
            let comment = commentsData!.comments[indexPath.row]
            cell.singleComment = comment
            //comment!.receiverName = commen!t.commentUserName
            
            if comment.receiverName == nil {
                var attributed = NSMutableAttributedString(string: "\(comment.commentUserName!):\(comment.commentInfo!)")
                let nameRange = NSRange(location: 0, length: count(comment.commentUserName!))
                let contentRange = NSRange(location: count(comment.commentUserName!) + 1, length: count(comment.commentInfo!))
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.LolitaThemeDarkText()
                    ], range: nameRange)
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.blackColor()
                    ], range: contentRange)
                cell.commentInfoLabel.attributedText = attributed
            } else {
                var attributed = NSMutableAttributedString(string: "\(comment.commentUserName!)回复\(comment.receiverName!):\(comment.commentInfo!)")
                let nameRange = NSRange(location: 0, length: count(currentUserName))
                let replyRange = NSRange(location: count(currentUserName), length: 2)
                let recieverRange = NSRange(location: count(currentUserName) + 2, length: count(comment.receiverName!))
                let contentRange = NSRange(location: count(currentUserName) + 2 + count(comment.receiverName!) + 1, length: count(comment.commentInfo!))
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.LolitaThemeDarkText()
                    ], range: nameRange)
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.blackColor()
                    ], range: replyRange)
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.LolitaThemeDarkText()
                    ], range: recieverRange)
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.blackColor()
                    ], range: contentRange)
                cell.commentInfoLabel.attributedText = attributed
            }

            
            
            
            
            cell.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        case 2:
            cell = tableView.dequeueReusableCellWithIdentifier("commentCell") as! CommentCell
            let cell = cell as! CommentCell
            commentTextField = cell.commentTextField
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            // 判断是否已经缓存了行高
            if let h = rowHeightCache?.objectForKey("\(feedData.id)") as? NSNumber {
                //            println("从缓存返回 \(h)")
                return CGFloat(h.floatValue)
            } else {
                //            println("计算行高 \(__FUNCTION__) \(indexPath)")
                let cell = tableView.dequeueReusableCellWithIdentifier("homeCell") as! HomeFeedsCell
                let height = cell.cellHeight(feedData)
                
                // 将行高添加到缓存 - swift 中向 NSCache/NSArray/NSDictrionary 中添加数值不需要包装
                rowHeightCache!.setObject(height, forKey: "\(feedData.id)")
                
                return cell.cellHeight(feedData)
            }

        case 1:
            var height: CGFloat = 0.0
            let comment = commentsData!.comments[indexPath.row]
            if comment.receiverName == nil {
                var attributed = NSMutableAttributedString(string: "\(currentUserName):\(comment.commentInfo)")
                let nameRange = NSRange(location: 0, length: count(currentUserName))
                let contentRange = NSRange(location: count(currentUserName) + 1, length: count(comment.commentInfo!))
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.LolitaThemeDarkText()
                    ], range: nameRange)
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.blackColor()
                    ], range: contentRange)
                height = attributed.boundingRectWithSize(CGSize(width: UIScreen.mainScreen().bounds.width - 72.0, height: 20000.0),
                    options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil).height
            } else {
                var attributed = NSMutableAttributedString(string: "\(currentUserName)回复\(comment.receiverName):\(comment.commentInfo)")
                let nameRange = NSRange(location: 0, length: count(currentUserName))
                let replyRange = NSRange(location: count(currentUserName), length: 2)
                let recieverRange = NSRange(location: count(currentUserName) + 2, length: count(comment.receiverName!))
                let contentRange = NSRange(location: count(currentUserName) + 2 + count(comment.receiverName!) + 1, length: count(comment.commentInfo!))
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.LolitaThemeDarkText()
                    ], range: nameRange)
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.blackColor()
                    ], range: replyRange)
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.LolitaThemeDarkText()
                    ], range: recieverRange)
                attributed.addAttributes([
                    NSFontAttributeName             : UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName  : UIColor.blackColor()
                    ], range: contentRange)
                height = attributed.boundingRectWithSize(CGSize(width: UIScreen.mainScreen().bounds.width - 72.0, height: 20000.0), options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil).height
            }
            return max(height + 42.0 , 66.0)
        case 2:
            return 44.0
        default:
            return 0.0
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            //resetInputView()
            tableView.scrollToRowAtIndexPath(NSIndexPath(forItem: 0, inSection: 2), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.05 * Double(NSEC_PER_SEC))), dispatch_get_main_queue())
                {
                    [weak self] in
                    //self?.replyData = self?.infoData?.comment[indexPath.row] as? TwitterCommentListComment
                    //let replyTo = self?.replyData?.keeperName ?? "神秘人物"
                    let replyTo = self!.commentsData?.comments[indexPath.row].commentUserName
                    self!.commentsData?.comments[indexPath.row].receiverName = self!.currentUserName
                    self?.commentTextField?.placeholder = "回复:\(replyTo)"
                    self?.commentTextField?.becomeFirstResponder()
            }
            
        }
    }
    
    
}

extension CommentViewController: HomeFeedsCellDelegate {
    func HomeFeedsCellComment(indexPath: NSIndexPath) {
        commentTextField?.becomeFirstResponder()
    }
    func HomeFeedsCellStar(indexPath: NSIndexPath){
        
    }
    func HomeFeedsCellShare(indexPath: NSIndexPath){
        
    }
    
    
}
