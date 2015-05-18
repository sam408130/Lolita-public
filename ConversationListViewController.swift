//
//  ConversationListViewController.swift
//  Lolita-public
//
//  Created by Sam on 5/7/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import UIKit

class ConversationListViewController : UIViewController , UITableViewDataSource , UITableViewDelegate {

    
    
    var _tableView = UITableView()
    var _conversations = NSMutableArray()
    let kConversationCellIdentifier = "ConversationCellIdentifier"
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "我参加的群聊"
        let frameSize = self.view.frame.size
        
        _tableView = UITableView(frame: CGRectMake(0, 0, frameSize.width, frameSize.height), style: UITableViewStyle.Plain)
        _tableView.dataSource = self
        _tableView.delegate = self
        
        _tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: kConversationCellIdentifier)
        self.view.addSubview(_tableView)
        
//        var imClient = AVIMClient()
//        var query : AVIMConversationQuery = imClient.conversationQuery()
//        query.whereKey(kAVIMKeyMember, containedIn: [AVUser.currentUser().objectId])
//        //query.whereKey(AVIMATTR)
//        query.findConversationsWithCallback({
//            (objects:[AnyObject]! , error:NSError!) in
//                self._conversations = NSMutableArray(array: objects)
//                self._tableView.reloadData()
//        })
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "新建", style: UIBarButtonItemStyle.Plain, target: self, action: "pressedButtonCreate:")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func pressedButtonCreate(sender:AnyObject){
        
        var contactsVC = UIStoryboard(name: "Message", bundle: nil).instantiateViewControllerWithIdentifier("ContactsViewIdentifier") as! ContactsViewController
        contactsVC.action = .AddNewMembers
        contactsVC.delegate = self
        self.navigationController?.pushViewController(contactsVC, animated: true)
        
    }

    
}



extension ConversationListViewController : ConversationOperationDelegate  {
    
    func addMembers(clients: [AnyObject]!, conversation: AVIMConversation!) {
        
        if (clients.count < 1){
            return
        }
        
        let currentUserId : String = AVUser.currentUser().objectId
        var convMembers = NSMutableArray(array: clients)
        let _clients : NSArray = clients
        
        if ( !(_clients.containsObject(currentUserId)) ){
            convMembers.addObject(currentUserId)
        }
        //var imClient  = ConversationStore.sharedInstance().imClient as AVIMClient
        var imClient = AVIMClient()
        println("!!!!!\(imClient)")
        imClient.createConversationWithName("", clientIds: convMembers as [AnyObject], attributes: ["type":kConversationType_Group.hashValue ], options: AVIMConversationOptionNone, callback: {
            (conversation:AVIMConversation! , error:NSError!) in
            if (error != nil){
                self.alert(error.description)
            }else{
                
                self._conversations.insertObject(conversation, atIndex: 0)
                self._tableView.reloadData()
            }
        })
        
        println(_conversations)

    }
    
}

extension ConversationListViewController : UITableViewDataSource , UITableViewDelegate  {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return  1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _conversations.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var conv = _conversations[indexPath.row] as! AVIMConversation
        var cell = _tableView.dequeueReusableCellWithIdentifier(kConversationCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        if ( count(conv.name) > 0 ){
            cell.textLabel?.text = conv.name
        }else{
            let displayName = ConversationUtils.getConversationDisplayname(conv)
            if (conv.members.count < 3){
                cell.textLabel?.text = displayName
            }else{
                cell.textLabel?.text = "\(displayName)等\(conv.members.count)人"
            }
        }
        
        return cell
  
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let conv = _conversations[indexPath.row] as! AVIMConversation
        var ChatVC = UIStoryboard(name: "Message", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewControllerIdentifier") as! ChatViewController
        
        
        self.navigationController?.pushViewController(ChatVC, animated: true)
    
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
}












