//
//  ContactsViewController.swift
//  Lolita-public
//
//  Created by Sam on 5/6/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import UIKit

class ContactsViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,ConversationOperationDelegate , AVIMClientDelegate{

    
    var specificUsers  = NSArray()
    var delegate = ConversationOperationDelegate?()
    
    var _tableView = UITableView()
    var _allUsers = NSMutableArray()
    var _pickedUsers = NSMutableArray()
    var _refreshFooter = MJRefreshFooterView()
    
    var allUser = NSMutableArray()
    var tableView = UITableView()
    var refreshFooter = MJRefreshFooterView()
    
    let kContactCellIdentifier = "ContactIdentifier"
    
    
    enum ConversationActionType : Int {
        case ActionNone = 0
        case AddNewMembers = 1
        case KickoffMembers = 2
    }
    
    var action = ConversationActionType.ActionNone
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frameSize = self.view.frame.size
        let navSize = self.navigationController!.navigationBar.frame.size
        
        if (self.action != .ActionNone){
            _tableView = UITableView(frame: CGRectMake(0, 0, frameSize.width, frameSize.height) , style:UITableViewStyle.Plain)
            _tableView.allowsMultipleSelection = true
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title:"确定", style: UIBarButtonItemStyle.Plain, target: self, action: "pressedButtonOK:")
            
        }else{
            _tableView = UITableView(frame: CGRectMake(0, navSize.height + 24, frameSize.width, frameSize.height - navSize.height - 49), style: UITableViewStyle.Plain)
            _tableView.allowsMultipleSelection = false
        }
        
        _tableView.delegate = self
        _tableView.dataSource = self
        _tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: kContactCellIdentifier)
        self.view.addSubview(_tableView)
        
        
        _allUsers = NSMutableArray(capacity: 100)
        _pickedUsers = NSMutableArray(capacity: 100)
        
        if (self.specificUsers.count > 0) {
            _allUsers = NSMutableArray(array: self.specificUsers)
        }else{
            var query = AVUser.query()
            query.addAscendingOrder("username")
            query.whereKey("objectId", notEqualTo: AVUser.currentUser().objectId)
            query.limit = 100
            query.findObjectsInBackgroundWithBlock({
                (objects:[AnyObject]! , error:NSError!) in
                if error != nil {
                    self.alert(error.description)
                }else{
                    self._allUsers.addObjectsFromArray(objects)
                    self._tableView.reloadData()
                }
            })
            _refreshFooter = MJRefreshFooterView.footer()
            _refreshFooter.scrollView = _tableView
            weak var ws = self
            _refreshFooter.beginRefreshingBlock = {
                (refreshView : MJRefreshBaseView!) in
                    var query = AVUser.query()
                    query.addAscendingOrder("username")
                    query.limit = 100
                    query.skip = ws!.allUser.count
                    query.findObjectsInBackgroundWithBlock({
                        (objects:[AnyObject]! , error:NSError!) in
                            ws?.allUser.addObjectsFromArray(objects)
                            ws?.tableView.reloadData()
                            ws?.refreshFooter.endRefreshing()
                    })
            }
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit{
        _refreshFooter.free()
    }
    
    func pressedButtonOK(sender:AnyObject){
        
        self.navigationController?.popViewControllerAnimated(true)
        
        if (self.action != .ActionNone && _pickedUsers.count > 0){
            var clients = NSMutableArray(capacity: _pickedUsers.count)
            for (var i = 0 ; i < _pickedUsers.count ; i++){
                clients.addObject((_pickedUsers[i] as! AVUser).objectId)
            }
        
            if (self.action == .AddNewMembers){
                //self.delegate!.addMembers!(clients as [AnyObject], conversation: nil)
                
                self.delegate?.addMembers!(clients as [AnyObject], conversation: nil)
                
            }
            
            if (self.action == .KickoffMembers){
                self.delegate?.kickoffMembers!(clients as [AnyObject], conversation: nil)
            }
        }
        
    }
    
    
    
    //UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.action == .ActionNone){
            if (section == 0){
                return 1
            }else{
                return self._allUsers.count
            }
        }
        return _allUsers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (self.action == .ActionNone && indexPath.section == 0){
            var cell = tableView.dequeueReusableCellWithIdentifier(kContactCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
            
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            cell.textLabel?.text = "群聊"
            return cell
        }
        
        
        var cell = tableView.dequeueReusableCellWithIdentifier(kContactCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        
        cell.accessoryType = UITableViewCellAccessoryType.None
        let user = _allUsers.objectAtIndex(indexPath.row) as! AVUser
        cell.textLabel?.text = user.username
        return cell
        
        
        
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (self.action == .ActionNone){
            return 2
        }else{
            return 1
        }
    }
    
    
    //UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (self.action == .ActionNone && indexPath.section == 0){
            var conversationLV = UIStoryboard(name: "Message", bundle: nil).instantiateViewControllerWithIdentifier("ConversationListViewControllerIdentifier") as! ConversationListViewController
            self.navigationController?.pushViewController(conversationLV, animated: true)
        }
        
        if (self.action != .ActionNone){
            var targetUser = _allUsers[indexPath.row] as! AVUser
            _pickedUsers.removeObject(targetUser)
            _pickedUsers.addObject(targetUser)
            return
        }
        
        var peerUser = _allUsers[indexPath.row] as! AVUser
        var currentUser = AVUser.currentUser()
        var clientIds = [currentUser.objectId , peerUser.objectId]
        var imClient = AVIMClient()
        imClient.delegate = self
        var query : AVIMConversationQuery = imClient.conversationQuery()
        query.limit = 10
        query.skip = 0
        //query.whereKey(kAVIMKeyMember, containsAllObjectsInArray: clientIds)
        //query.whereKey(AVIMAttr, equalTo: <#AnyObject!#>)
        println("~~~点击开启对话")
        println(query)
        query.findConversationsWithCallback{
            
            (objects:[AnyObject]! ,error:NSError!) in
            
                println(objects.count)
                if (error != nil){
                    self.alert(error.description)
                }else if(objects.count < 1) {
                
                    println("开始创建对话")
                    imClient.createConversationWithName(nil, clientIds: clientIds, attributes: ["type" : kConversationType_OneOne.hashValue], options: AVIMConversationOptionNone, callback: {
                    (conversation:AVIMConversation! , error:NSError!) in
                    if (error != nil){
                        self.alert(error.description)
                    }else{
                        self.openConversation(conversation)
                    }
                    
                })
            }else{
                println("进到这里了")
                var conversation : AVIMConversation = objects[0] as! AVIMConversation
                self.openConversation(conversation)
            }
        }


        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if (self.action != .ActionNone){
            var targetUser = _allUsers[indexPath.row] as! AVUser
            _pickedUsers.removeObject(targetUser)
        }
    }
    
    func openConversation(conversation:AVIMConversation){
        let chatVC = UIStoryboard(name: "Message", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewControllerIdentifier") as! ChatViewController
        chatVC.conversation = conversation
        self.navigationController?.pushViewController(chatVC, animated: true)
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (self.action == .ActionNone){
            if (section == 0){
                return 0
            }else{
                return 30
            }
        }else{
            return 0
        }
    }
    
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (self.action == .ActionNone){
            return nil
        }
        if (section == 0){
            return nil
        }
        
        var headerLabel = UILabel(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 30))
        headerLabel.text = "用户列表"
        headerLabel.backgroundColor = UIColor.lightGrayColor()
        headerLabel.textColor = UIColor.whiteColor()
        headerLabel.font = UIFont.systemFontOfSize(16)
        headerLabel.textAlignment = NSTextAlignment.Left
        return headerLabel
    }
    
    
    
    


}
