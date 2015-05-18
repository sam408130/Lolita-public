//
//  ConversationDetailViewController.swift
//  Lolita-public
//
//  Created by Sam on 5/5/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import UIKit

class ConversationDetailViewController: UIViewController ,ConversationOperationDelegate, UITableViewDataSource , UITableViewDelegate{

    var conversation : AVIMConversation = AVIMConversation()
    var delegate = ConversationOperationDelegate?()
    let kMemberCellIdentifier = "ChatDetailMemberCellIdentifier"
    let kMuteCellIdentifier = "ChatDetailMuteCellIdentifier"
    let kExitCellIdentifier = "ChatDetailExitCellIdentifier"
    
    private var tableView = UITableView()
    private var _memberProfiles = NSMutableArray()
    private var _tapGesture = UITapGestureRecognizer()
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frameSize = self.view.frame.size
        let navSize = self.navigationController!.navigationBar.frame.size
        tableView = UITableView(frame: CGRectMake(0, 0, frameSize.width, (frameSize.height - navSize.height)), style: UITableViewStyle.Plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(ConversationMemberGroupView.self, forCellReuseIdentifier: kMemberCellIdentifier)
        tableView.registerClass(ConversationMuteView.self, forCellReuseIdentifier: kMuteCellIdentifier)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: kExitCellIdentifier)
        
        self.view.addSubview(tableView)
        
        if (self.creatByCurrentUser()){
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "踢人", style: UIBarButtonItemStyle.Plain, target: self, action: "pressedButtonKickoff:")
        }
        
        AVUserStore.sharedInstance().fetchInfos(self.conversation.members){
            (objects:[AnyObject]! , error:NSError!) in
                self._memberProfiles = NSMutableArray(array: objects)
                dispatch_sync(dispatch_get_main_queue()){
                    self.tableView.reloadData()
                }
            
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    func creatByCurrentUser() -> Bool{
        let currentUser : String = AVUser.currentUser().objectId
        println(currentUser)
        println(self.conversation.creator)
        if (currentUser.compare(self.conversation.creator) == NSComparisonResult.OrderedSame){
            return true
        }else{
            return false
        }
    }
    
    
    
    
    
    func pressedButtonKickoff(sender:AnyObject){
        var query = AVUser.query()
        query.whereKey("objectId", containedIn: self.conversation.members)
        query.limit = 1000
        query.findObjectsInBackgroundWithBlock(){
            (objects : [AnyObject]! , error:NSError?) in
                if (error != nil){
                    //MessageDisplayer.displayError(error)
                    return
                }
                
                let storyboard = UIStoryboard(name: "Message", bundle: nil)
                let contactsController = storyboard.instantiateViewControllerWithIdentifier("ContactsViewIdentifier") as! ContactsViewController
                contactsController.action = .KickoffMembers
                contactsController.specificUsers = objects
                contactsController.delegate = self
                self.navigationController?.pushViewController(contactsController, animated: true)
                
                
            }
        
       
    }
    
    
    func addMembers2Conversation(){
        let storyboard = UIStoryboard(name: "Message", bundle: nil)
        let contactsController = storyboard.instantiateViewControllerWithIdentifier("ContactsViewIdentifier") as! ContactsViewController
        contactsController.action = .AddNewMembers
        contactsController.delegate = self
        self.navigationController?.pushViewController(contactsController, animated: true)

    }
    
    func isMultiPartiesConversation() -> Bool{
        var typeNumber = (self.conversation.attributes["type"]) as! NSNumber
        if (typeNumber.intValue == kConversationType_Group){
            return true
        }else{
            return false
        }
    }
    
    
    func memberCellCount() -> Int {
        let memberCount = Double(self.conversation.members.count)
        return Int(ceil(memberCount/4.0) + 1)
    }
    
    
    
    //UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var delta = 0
        if self.isMultiPartiesConversation() {
            delta = 1
        }
        return self.memberCellCount() + 2 + delta
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let index = indexPath.row
        let memberCellCount = self.memberCellCount()
        let enableChangeName = self.isMultiPartiesConversation()
        
        if (index < memberCellCount){
            var result = tableView.dequeueReusableCellWithIdentifier(kMemberCellIdentifier, forIndexPath: indexPath) as! ConversationMemberGroupView
            var avatarArray : NSArray = result.avatarArray()
            var usernameArray : NSArray = result.usernameArray()
            var tmpProfile = UserProfile()
            var tmpAvatarView = UIImageView()
            var tmpUsernameLable = UILabel()
            
            for(var i = index * 4; i < (index + 1) * 4 ; i++ ){
                tmpAvatarView = avatarArray[i - index * 4] as! UIImageView
                tmpUsernameLable = usernameArray[i - index * 4] as! UILabel
                if (i < _memberProfiles.count){
                    tmpProfile = _memberProfiles[i] as! UserProfile
                    tmpAvatarView.setImageWithURL(NSURL(fileURLWithPath: tmpProfile.avatarUrl), placeholderImage: UIImage(named: "default_avatar")!)
                    tmpUsernameLable.text = tmpProfile.nickname
                    tmpAvatarView.hidden = false
                    tmpAvatarView.userInteractionEnabled = false
                    tmpAvatarView.removeGestureRecognizer(_tapGesture)
                    tmpUsernameLable.hidden = false
                }else if (i == _memberProfiles.count){
                    tmpUsernameLable.text = ""
                    tmpAvatarView.image = UIImage(named: "add_member")
                    tmpAvatarView.hidden = false
                    tmpAvatarView.userInteractionEnabled = true
                    tmpAvatarView.addGestureRecognizer(_tapGesture)
                    tmpUsernameLable.hidden = false
                }else{
                    tmpAvatarView.hidden = true
                    tmpUsernameLable.hidden = true
                }
            }
        
            return result
        
        
        }else if (index == memberCellCount){
            let result = tableView.dequeueReusableCellWithIdentifier(kMuteCellIdentifier, forIndexPath: indexPath) as! ConversationMuteView
            result.delegate = self
            result.switchView.setOn(self.conversation.muted, animated: true)
            return result
        
        }else{
            let result = tableView.dequeueReusableCellWithIdentifier(kExitCellIdentifier, forIndexPath: indexPath) as! UITableViewCell

            if ( enableChangeName && (index == memberCellCount + 1) ){
                result.textLabel?.textAlignment = NSTextAlignment.Left
                result.textLabel?.textColor = UIColor.blackColor()
                if ((self.conversation.name) != nil){
                    result.textLabel?.text = "群聊名称:\(self.conversation.name)"
                }else{
                    result.textLabel?.text = "群聊名称:暂无"
                }
                result.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            }else{
                result.textLabel?.textAlignment = NSTextAlignment.Center
                result.textLabel?.textColor = UIColor.redColor()
                result.textLabel?.text = "退出当前会话"
                result.accessoryType = UITableViewCellAccessoryType.None
            }
            
            return result
            
        }
        
        
    }
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    //UITableViewDelegate
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        let index : Int = indexPath.row
        let memberCellCount : Int = self.memberCellCount()
        
        if (index > memberCellCount){
            
            let enableChangeName : Bool = self.isMultiPartiesConversation()
            if ( enableChangeName && (index == memberCellCount + 1) ){
                
                let changenameVC : ChangeNameViewController = ChangeNameViewController()
                changenameVC.delegate = self
                changenameVC.oldName = self.conversation.name
                self.navigationController?.pushViewController(changenameVC, animated: true)
            
            }else{
                self.navigationController?.popViewControllerAnimated(true)
                self.delegate?.exitConversation!(self.conversation)
            }
        }
        
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let index :Int = indexPath.row
        if (index < memberCellCount()) {
            return ConversationMemberGroupView.cellHeight()
        } else  if (index == memberCellCount()) {
            return ConversationMuteView.cellHeight()
        } else {
            return 44.0
        }
    }
    
    
    
    //ConversationOperationDelegate
    
    
    func addMembers(clients: [AnyObject]!, conversation: AVIMConversation!) {
        if (clients.count < 1){
            return
        }
        
        if (self.isMultiPartiesConversation()){
            self.conversation.addMembersWithClientIds(clients, callback: {
                
                (succeeded : Bool , error : NSError!) in
                if (succeeded){
                    self.tableView.reloadData()
                }else{
                    self.alert(error.description)
                }
                
            })
        }else{
            var newClients = NSMutableArray(array: self.conversation.members)
            newClients.addObjectsFromArray(clients)
            ConversationStore.sharedInstance().imClient.createConversationWithName(nil, clientIds: newClients as [AnyObject], attributes: ["type":kConversationType_Group.hashValue], options: AVIMConversationOptionNone, callback: {
                (conversation:AVIMConversation!, error:NSError!) in
                if (error != nil){
                    self.alert(error.description)
                }else{
                    self.navigationController?.popViewControllerAnimated(true)
                    self.delegate?.switch2NewConversation!(conversation)
                }
            })
            
        }
        
        
    }
    
    func kickoffMembers(client: [AnyObject]!, conversation: AVIMConversation!) {
        if (client.count < 1){
            return
        }
        self.conversation.removeMembersWithClientIds(client, callback: {
            (succeeded : Bool , error : NSError!) in
                if (succeeded){
                    self.tableView.reloadData()
                }else{
                    self.alert(error.description)
            }
        })
    }
    
    func mute(on: Bool, conversation: AVIMConversation!) {
        if on {
            self.conversation.muteWithCallback({
                (succeeded:Bool , error:NSError!) in
                    if (error != nil){
                        self.alert(error.description)
                    }
            })
        }else{
            self.conversation.unmuteWithCallback({
                (succeeded:Bool , error:NSError!) in
                if (error != nil){
                    self.alert(error.description)
                }
            })
        }
    }
    
    
    func changeName(newName: String!, conversation: AVIMConversation!) {
        var updateBuilder : AVIMConversationUpdateBuilder = self.conversation.newUpdateBuilder()
        updateBuilder.name = newName
        self.conversation.update(updateBuilder.dictionary(), callback: {
            (succeeded:Bool , error:NSError!) in
            if (error != nil){
                self.alert(error.description)
            }else{
                self.tableView.reloadData()
            }
        })
    }
    
    
    
    
    
    
    
}
