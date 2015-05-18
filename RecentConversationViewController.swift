//
//  RecentConversationViewController.swift
//  Lolita-public
//
//  Created by Sam on 5/5/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import UIKit

class RecentConversationViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,IMEventObserver {

    
    let kConversationCellIdentifier = "ConversationIdentifier"
    
    var _tableView = UITableView()
    var _recentConversations = NSMutableArray()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frameSize:CGSize = self.view.frame.size
        let navSize:CGSize = self.navigationController!.navigationBar.frame.size
        
        _tableView = UITableView(frame: CGRectMake(0, navSize.height+24, frameSize.width, frameSize.height - navSize.height), style: UITableViewStyle.Plain)
        _tableView.delegate = self
        _tableView.dataSource = self
        _tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: kConversationCellIdentifier)
        self.view.addSubview(_tableView)
        
        _recentConversations = NSMutableArray(capacity: 20)
        let store:ConversationStore = ConversationStore.sharedInstance()
        store.addEventObserver(self, forConversation: "*")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let store = ConversationStore.sharedInstance()
        let recentConvs = store.recentConversations()
        _recentConversations.removeAllObjects()
        _recentConversations.addObjectsFromArray(recentConvs)
        _tableView.reloadData()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _recentConversations.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let conv = _recentConversations.objectAtIndex(indexPath.row) as! AVIMConversation
        var cell = _tableView.dequeueReusableCellWithIdentifier(kConversationCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        let members = conv.members
        if (count(conv.name) > 0) {
            cell.textLabel?.text = conv.name
        }else{
            let displayname = ConversationUtils.getConversationDisplayname(conv)
            if (members.count < 3){
                cell.textLabel?.text = displayname
            }else{
                cell.textLabel?.text = "\(displayname)等\(members.count)人"
            }
        }
        
        return cell
        
    }
    
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let conv  = _recentConversations.objectAtIndex(indexPath.row) as! AVIMConversation
        let sb = UIStoryboard(name: "Message", bundle: nil)
        let chatViewController = sb.instantiateViewControllerWithIdentifier("ChatViewControllerIdentifier") as!  ChatViewController
        chatViewController.conversation = conv
        self.navigationController?.pushViewController(chatViewController, animated: true)
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
    func newMessageArrived(message: Message!, conversation: AVIMConversation!) {
        let store : ConversationStore = ConversationStore.sharedInstance()
        if (message.eventType == EventInvited){
            store.quitConversation(conversation)
        }
        
        let recentConvs = store.recentConversations()
        _recentConversations.removeAllObjects()
        _recentConversations.addObjectsFromArray(recentConvs)
        _tableView.reloadData()
    }
    
    func messageDelivered(message: Message!, conversation: AVIMConversation!) {
        
    }
    
    
    
    
    
    
}
