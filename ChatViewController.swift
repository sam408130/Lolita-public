//
//  ChatViewController.swift
//  Lolita-public
//
//  Created by Sam on 5/5/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import UIKit
import Foundation

class ChatViewController: UIViewController ,UITableViewDataSource,UITableViewDelegate,IMEventObserver,FCMessageCellDelegate,ConversationOperationDelegate,UUInputFunctionViewDelegate{
    

    
    var _tableView = UITableView()
    var _inputView = UUInputFunctionView()
    var _messages = NSMutableArray()
    var _quitConversation:Bool = false
    var verticalOffset : CGFloat = 0.0
    var _refreshHead = MJRefreshBaseView()

    var messages = NSMutableArray()
    var tableView = UITableView()
    var refreshHead = MJRefreshHeaderView()
    
    
    var conversation = AVIMConversation()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "ChatRoom"
        self.view.backgroundColor = UIColor.whiteColor()
        
        _tableView = UITableView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height - 40), style: UITableViewStyle.Plain)
        //_tableView.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height - 40)
        
        _tableView.delegate = self
        _tableView.dataSource = self
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
        _tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        _tableView.userInteractionEnabled = true
        
        
        self.view.addSubview(_tableView)
        
        _messages = NSMutableArray(capacity: 100)
        _quitConversation = false
        
        initNavigationButton()
        
        addRefreshViews()
        
        let store : ConversationStore = ConversationStore.sharedInstance()
        store.queryMoreMessages(self.conversation, from: "", timestamp: Int64(NSDate().timeIntervalSince1970 * 1000), limit: Int32(15), callback: {
            
            (objects:[AnyObject]! , error: NSError!) in
                dispatch_async(dispatch_get_main_queue()){
                    self._messages.addObjectsFromArray(objects)
                    self._tableView.reloadData()
                    if (self._messages.count > 1){
                        self._tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self._messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
                        
                    }
            }
            
        })
    
    }
    
    
    func addRefreshViews(){
        weak var weakSelf = self
        _refreshHead = MJRefreshHeaderView.header()
        _refreshHead.scrollView = _tableView
        let refreshBlock : BeginRefreshingBlock = {
            (refreshView : MJRefreshBaseView! )  -> Void in
                
                var lastestMessageId = ""
                var ts = Int64(NSDate().timeIntervalSince1970 * 1000)
                if (weakSelf?._messages.count > 0){
                    lastestMessageId = (weakSelf?._messages[0] as! Message).imMessage.messageId
                }
            let store = ConversationStore.sharedInstance()
            store.queryMoreMessages(weakSelf?.conversation, from: lastestMessageId, timestamp: ts, limit: Int32(15), callback: {
                
                (objects:[AnyObject]! , error:NSError!) in
                dispatch_async(dispatch_get_main_queue()){
                    for(var i = objects.count - 1; i >= 0 ; i--){
                        weakSelf?._messages.insertObject(objects[i], atIndex: 0)
                    }
                    weakSelf?.tableView.reloadData()
                    if (weakSelf?._messages.count > 0){
                        weakSelf?.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self._messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
                    }
                    weakSelf?.refreshHead.endRefreshing()
                    
                    
                }
            })
                
                
        }
            
        
    }
    
    func initNavigationButton(){
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"group.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "pressddButtonDetail:")
    
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardChange:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardChange:", name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "tableViewScrollToButtom", name: UIKeyboardDidShowNotification, object: nil)
        
        let store = ConversationStore.sharedInstance()
        store.addEventObserver(self, forConversation: self.conversation.conversationId)
        if (self.conversation.transient){
            self.conversation.joinWithCallback({
                (succeeded:Bool ,error:NSError!) -> Void in
                    if(error != nil){
                        println("failed to join transient conversation")
                    }
                    else{
                        println("join transient conversation id = \(self.conversation.conversationId)")
                    }
            })
        }
        
        
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if (self.conversation.transient){
            self.conversation.quitWithCallback({
                (succeeded:Bool,error:NSError!) -> Void in
                    if(error == nil){
                        println("failed to join transient conversation")
                    }
                    else{
                        println("join transient conversation id = \(self.conversation.conversationId)")
                    }
                
            })
        }
    
        let store = ConversationStore.sharedInstance()
        if (_quitConversation){
            store.quitConversation(self.conversation)
        }else{
            store.openConversation(self.conversation)
        }
        
        store.removeEventObserver(self, forConversation: self.conversation.conversationId)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        
    }
    
    
    
    func tableViewScrollToButtom(){
        if (_messages.count == 0){
            return
        }
        let indexPath = NSIndexPath(forRow: _messages.count - 1, inSection: 0)
        _tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
    
    
    
    func keyboardChange(notification:NSNotification){
        let userInfo = notification.userInfo!
        
        
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double
        let animationCurve = UIViewAnimationCurve(rawValue:userInfo[UIKeyboardAnimationCurveUserInfoKey]!.integerValue)!
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
       
        
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        
        if (notification.name == UIKeyboardWillShowNotification){
            if (self.view.frame.origin.y >= 0){
                verticalOffset = keyboardEndFrame.size.height > 252 ? keyboardEndFrame.size.height:252
                self.view.frame = CGRectOffset(self.view.frame, 0, -verticalOffset)
                
                
            }
        }else{
            if (self.view.frame.origin.y < 0){
                self.view.frame = CGRectOffset(self.view.frame, 0, verticalOffset)
            }
        }
    
    
        UIView.commitAnimations()
    }
    
    
    func pressddButtonDetail(sender:AnyObject){
        let storyboard = UIStoryboard(name: "Message", bundle: nil)
        var detailController = storyboard.instantiateViewControllerWithIdentifier("ConversationDetailIdentifier") as! ConversationDetailViewController
        detailController.conversation = self.conversation
        detailController.delegate = self
        self.navigationController?.pushViewController(detailController, animated: true)
    }
    
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _messages.count
    }
    
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("CellID") as! FCMessageCell
        cell.delegate = self
        
        let frame = FCMessageFrame()
        frame.message = (_messages[indexPath.row]) as! Message
        cell.messageFrame = frame
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let frame = FCMessageFrame()
        frame.message = (_messages[indexPath.row]) as! Message
        return frame.cellHeight
    }
    
    //IMEventObserver
    
    func newMessageArrived(message: Message!, conversation: AVIMConversation!) {
        if (message.eventType == EventKicked){
            let profile : UserProfile = AVUserStore.sharedInstance().getUserProfile(message.byClient)
            let alertView : UIAlertView = UIAlertView(title: nil, message: "剔除了你", delegate: nil, cancelButtonTitle: "知道了")
            alertView.show()
            self.exitConversation(conversation)
            return
        }else{
            _messages.addObject(message)
            _tableView.reloadData()
        }
    }
    
    func messageDelivered(message: Message!, conversation: AVIMConversation!) {
        
    }
    
    //UUInputFunctionViewDelegate
    //text
    
    func UUInputFunctionViewMethod(funcView: UUInputFunctionView!, sendMessage message: String!) {
        if count(message) > 0 {
            let avMessage : AVIMTextMessage = AVIMTextMessage(text: message, attributes: nil)
            self.conversation.sendMessage(avMessage, callback: {
                
                (succeeded:Bool , error:NSError!) in
                if (error == nil){
                    self.alert(error.description)
                }else{
                    let store = ConversationStore.sharedInstance()
                    store.newMessageSent(avMessage, conversation: self.conversation)
                    let msg : Message = Message(AVIMMessage: avMessage)
                    self._messages.addObject(msg)
                    self._tableView.reloadData()
                    self._tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
                }
            })
        }
    }
    
    //image
    func UUInputFunctionViewMethod(funcView: UUInputFunctionView!, sendPicture image: UIImage!) {
        if (image != nil){
            var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last as! String
            let filePath : String = paths.stringByAppendingPathComponent("Image.jpg")
            let fileManager = NSFileManager.defaultManager()
            fileManager.removeItemAtPath(filePath, error: nil)
            UIImageJPEGRepresentation(image, 0.6).writeToFile(filePath, atomically: true)
            
            
            let avMessage : AVIMImageMessage = AVIMImageMessage(text: nil, attachedFilePath: filePath, attributes: nil)
            self.conversation.sendMessage(avMessage, callback: {
                
                    (succeeded:Bool , error:NSError!) in
                    if (error != nil){
                        self.alert(error.description)
                    }else{
                        ConversationStore.sharedInstance().newMessageSent(avMessage, conversation: self.conversation)
                        let msg = Message(AVIMMessage: avMessage)
                        self._messages.addObject(msg)
                        self._tableView.reloadData()
                        self._tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
                    }
                })
            
          }
        
    }
    
    //audio
    func UUInputFunctionViewMethod(funcView: UUInputFunctionView!, sendVoice voice: NSData!, time second: Int) {
        if ((voice) != nil){
            var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last as! String
            let filePath : String = paths.stringByAppendingPathComponent("audio.mp3")
            let fileManager = NSFileManager.defaultManager()
            fileManager.removeItemAtPath(filePath, error: nil)
            voice.writeToFile(filePath, atomically: true)
            
            let avMessage = AVIMAudioMessage(text: nil, attachedFilePath: filePath, attributes: nil)
            self.conversation.sendMessage(avMessage, callback: {
                
                (succeeded:Bool , error:NSError!) in
                if (error != nil){
                    self.alert(error.description)
                }else{
                    ConversationStore.sharedInstance().newMessageSent(avMessage, conversation: self.conversation)
                    let msg = Message(AVIMMessage: avMessage)
                    self._messages.addObject(msg)
                    self._tableView.reloadData()
                    self._tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
                }
            })

        }
    }
    
    
    
    func headImageDidClick(cell: FCMessageCell!, userId: String!) {
        let alert : UIAlertView = UIAlertView(title: "Tips", message: "HeadImageClick!!", delegate: nil, cancelButtonTitle: "sure")
        alert.show()
    }
    
    func exitConversation(conversation: AVIMConversation!) {
        _quitConversation = true
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func switch2NewConversation(newConversation: AVIMConversation!) {
        self.navigationController?.popViewControllerAnimated(true)
        let newVC = UIStoryboard(name: "Message", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewControllerIdentifier") as! ChatViewController
        newVC.conversation = newConversation
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
}
