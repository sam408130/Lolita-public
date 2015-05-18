//
//  FeedsData.swift
//  Lolita-public
//
//  Created by Sam on 4/26/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import UIKit


var imageBox  = ["avatarImage","postImage1","postImage2","postImage3","postImage4","postImage5","postImage6","postImage7","postImage8","postImage9"]

class FeedsData {
    
    
    var feedsData = [Feed]()
    
    
    
    class func loadFeed(AVobjectName:String , completion :(data: FeedsData?, error:NSError?)->()){
        
        let net = NetworkManager.sharedManager
        
        var query = AVQuery(className: AVobjectName)
        query.findObjectsInBackgroundWithBlock{
            
            (objects:[AnyObject]?,error:NSError?)  in
            if error == nil {
        
                var mydata = FeedsData()
                
                for object in objects! {
                    
                    let feed = Feed()
                    feed.id = object.objectId
                    feed.text = object["postInfo"] as? String
                    feed.star = object["star"] as! Int
                    feed.comments_count = object["comment"] as! Int
                    feed.userID = object["userID"] as? String
                    
                    //let userObject = AVUser.query()!.getObjectWithId(feed.userID)
                    
                    var Userquery = AVUser.query()
                    Userquery.getObjectInBackgroundWithId(feed.userID){
                        (userObject: AVObject? ,error:NSError?) in
                        if error == nil {
                            feed.username = userObject!["username"] as? String
                            if let avatarImageFile = userObject!["avatarImage"] as? AVFile {
                                feed.avatarImageUrl = avatarImageFile.url
                            }

                        }
                    }
                    
                    
                    if let time = object.createdAt{
                        let current = NSDate()
                        let delta = current.timeIntervalSinceDate(time!)
                        if delta <= 60 {
                            feed.postTime =  "刚刚"
                        } else if delta < 3600 {
                            feed.postTime = "\(Int(delta/60.0))分钟前"
                        } else if delta < 86400 {
                            feed.postTime = "\(Int(delta/3600.0))小时前"
                        } else {
                            feed.postTime = "\(Int(delta/86400.0))天前"
                        }
                        
                    }
                    
                    
                    
                    for objectKey in imageBox{
                        
                        if let avatarImageFile = object[objectKey] as? AVFile{

                            feed.postImageUrls.insert(avatarImageFile.url, atIndex: 0)
                            
                        }
                        
                        
                    }

                   
                    mydata.feedsData.insert(feed, atIndex: 0)


                    
                }
                

                if let urls = FeedsData.pictureURLs(mydata.feedsData){
                    net.downloadImages(urls) { (_, _) -> () in
                        // 回调通知视图控制器刷新数据
                        completion(data: mydata, error: nil)
                    }

                }else{
                    completion(data: mydata, error: nil)
                }
                
                
                
                
            }
            else{
                completion(data: nil, error: error!)
                return
            }
        }
        
    }
    
    
    class func pictureURLs(statuses: [Feed]?) -> [String]? {
        
        // 如果数据为空直接返回
        if statuses == nil {
            return nil
        }
        
        // 遍历数组
        var list = [String]()
        
        for status in statuses! {
            // 继续遍历 pic_urls
            if status.postImageUrls.count > 0{
                for url in status.postImageUrls{
                    list.append(url)
                }
            }
        }
        
        if list.count > 0 {
            return list
        } else {
            return nil
        }
    }
    
    
    
    
    
}

class Feed : NSObject {
    
    var postTime : String?
    
    var id : String?
    
    var text : String?
    
    //var reposts_count : Int = 0
    
    //var attitudes_count : Int = 0
    
    
    var star : Int = 0
    
    var comments_count : Int = 0
    
    var postImageUrls = [String]()
    
    var userID : String?
    
    var avatarImageUrl : String?
    
    var username : String?
    
    


}

class CommentsData {
    
    var comments = [SingleComment]()
    
    class func loadComments(AVobjectName:String, _ feedID:String , completion :(data: CommentsData?, error:NSError?)->()){
        
        let net = NetworkManager.sharedManager
        
        var query = AVQuery(className: AVobjectName)
        query.whereKey("feedID", equalTo: feedID)
        query.findObjectsInBackgroundWithBlock{
            
            (objects:[AnyObject]?,error:NSError?)  in
            if error == nil {
                
                var mydata = CommentsData()
                
                for object in objects! {
                    
                    let singleComment = SingleComment()
                    
                    singleComment.id = object.objectId
                    singleComment.commentInfo = object["commentInfo"] as? String
                    singleComment.commentUserID = object["commentUserID"] as? String
                    singleComment.feedID = object["feedID"] as? String
                    
                    let userObject = AVUser.query().getObjectWithId(singleComment.commentUserID)
                    singleComment.commentUserName = userObject["username"] as? String
                    if let avatarImageFile = userObject!["avatarImage"] as? AVFile {
                    
                        singleComment.commentUserAvatar = avatarImageFile.url 
                    }
                    if let time = object.createdAt{
                        let current = NSDate()
                        let delta = current.timeIntervalSinceDate(time!)
                        if delta <= 60 {
                            singleComment.commentTime =  "刚刚"
                        } else if delta < 3600 {
                            singleComment.commentTime = "\(Int(delta/60.0))分钟前"
                        } else if delta < 86400 {
                            singleComment.commentTime = "\(Int(delta/3600.0))小时前"
                        } else {
                            singleComment.commentTime = "\(Int(delta/86400.0))天前"
                        }
                        
                    }

                    mydata.comments.insert(singleComment, atIndex: 0)
                    
                }
                
                if let urls = CommentsData.pictureURLs(mydata.comments){
                    net.downloadImages(urls) { (_, _) -> () in
                        // 回调通知视图控制器刷新数据
                        completion(data: mydata, error: nil)
                    }
                    
                }else{
                    completion(data: mydata, error: nil)
                }
                
                
                
                
                
            }else{
                completion(data: nil, error: error!)
                return
        
            }
        }
    }
    
    
    class func pictureURLs(statuses: [SingleComment]?) -> [String]? {
        
        // 如果数据为空直接返回
        if statuses == nil {
            return nil
        }
        
        // 遍历数组
        var list = [String]()
        
        for status in statuses! {
            // 继续遍历 pic_urls
            if let url = status.commentUserAvatar{
                list.append(url)
            }
            
        }
        
        if list.count > 0 {
            return list
        } else {
            return nil
        }
    }
    

}

class SingleComment : NSObject {
    
    var id : String?
    
    var commentInfo : String?
    
    var commentUserID : String?
    
    var feedID : String?
    
    var commentUserName : String?
    
    var commentUserAvatar : String?
    
    var commentTime : String?
    
    var receiverName : String?
}














