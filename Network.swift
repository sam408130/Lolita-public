//
//  Network.swift
//  Lolita-public
//
//  Created by Sam on 4/30/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import Foundation


class SimpleNetwork{
    

    
    // 定义闭包类型，类型别名－> 首字母一定要大写
    typealias Completion = (result: AnyObject?, error: NSError?) -> ()
    
    /**
    异步加载图像
    
    :param: urlString  URLstring
    :param: completion 完成时的回调
    */
    func requestImage(urlString:String,_ completion:Completion){
        downloadImage(urlString) {(result, error) -> () in
            if error != nil{
                completion(result: nil, error: error)
            }
            else{
                /// 取到图片保存在沙盒的路径 并搞出来
                let path = self.fullImageCachePath(urlString)
                /// 从沙盒加载到内存，这个方法可以在不需要时自动释放
                var image = UIImage(contentsOfFile: path)
                
                dispatch_async(dispatch_get_main_queue()){ () -> Void in
                    completion(result: image, error: nil)
                }
            }
        }
    }
    
    /**
    下载多张图片
    
    :param: urlString  下载地址数组
    :param: completion 回调
    */
    func downloadImages(urls:[String], _ completion : Completion){
        
        /// 利用调度组统一监听一组异步任务执行完毕
        let grop = dispatch_group_create()
        
        /// 遍历链接数组进入调度组
        for url in urls{
            dispatch_group_enter(grop)
            downloadImage(url) { (result, error) -> () in
                dispatch_group_leave(grop)
            }
        }
        
        /// 全部执行完毕后才会调用
        dispatch_group_notify(grop, dispatch_get_main_queue()) { () -> Void in
            completion(result: nil, error: nil)
        }
        
    }
    
    /**
    下载图像并且保存到沙盒
    
    :param: urlString  urlString
    :param: completion 完成回调
    */
    func downloadImage(urlString:String, _ completion : Completion){
        var path = urlString.md5
        
        path = cachePath!.stringByAppendingPathComponent(path)
        
        if NSFileManager.defaultManager().fileExistsAtPath(path){
            //            println("\(urlString) 图片已经被缓存")
            completion(result: nil, error: nil)
            return
        }
        
        if let url = NSURL(string: urlString){
            println("url:\(url)")
            /// 开始下载图片
            self.session!.downloadTaskWithURL(url) { (location, _, error) -> Void in
                if error != nil{
                    completion(result: nil, error: error)
                    return
                }
                
                /// 复制到指定位置
                NSFileManager.defaultManager().copyItemAtPath(location.path!, toPath: path, error: nil)  // $$$$$
                
                completion(result: nil, error: nil)
                
                }.resume()
        }else {
            let error = NSError(domain: SimpleNetwork.errorDomain, code: -1, userInfo: ["error": "无法创建 URL"])
            completion(result: nil, error: error)
        }
        
    }
    
    /// 获取完整的URL路径
    func fullImageCachePath(urlString:String) ->String{
        var path = urlString.md5
        return cachePath!.stringByAppendingPathComponent(path)
    }
    
    /// MARK: - 完整的图像缓存路径
    /// 完整的图像缓存路径
    private lazy var cachePath:String? = {
        var path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last as!String
        path = path.stringByAppendingPathComponent(imageCachePath)
        
        /// 这个属性是判断是否是文件夹
        var isDirectory : ObjCBool = true   // $$$$$
        
        let exists = NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDirectory)
        
        println("打印缓存地址isDirectory： \(isDirectory) exists \(exists) path: \(path)")
        
        /// 如果文件存在并且还不是文件夹，就直接删了
        if exists && !isDirectory{
            NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
        }
        
        /// 创建文件夹 withIntermediateDirectories 是否智能创建文件夹
        NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: nil)
        return path
        }()
    
    
    private static var imageCachePath = "com.itheima.imagecache"
    private static let errorDomain = "com.dsxlocal.error"
    
    private lazy var session:NSURLSession? = {
        return NSURLSession.sharedSession()
        }()
    
}