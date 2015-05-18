//
//  NetworkManager.swift
//  Lolita-public
//
//  Created by Sam on 4/30/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import Foundation

class NetworkManager {
    
    private static let instance = NetworkManager()
    
    class var sharedManager:NetworkManager{
        return instance
    }
    
    typealias Completion = (result:AnyObject?,error:NSError?) ->()
    
    // 隔离一层大框架
    private let net = SimpleNetwork()
    
    
    
    ///  异步下载网路图像
    ///
    ///  :param: urlString  urlString
    ///  :param: completion 完成回调
    func requestImage(urlString: String, _ completion: Completion) {
        
        net.requestImage(urlString, completion)
    }
    
    ///  完整的 URL 缓存路径
    func fullImageCachePath(urlString: String) -> String {
        
        return net.fullImageCachePath(urlString)
    }
    
    
    
    ///  下载多张图片
    ///
    ///  :param: urls       图片 URL 数组
    ///  :param: completion 所有图片下载完成后的回调
    func downloadImages(urls: [String], _ completion: Completion) {
        
        net.downloadImages(urls, completion)
    }
    
    ///  下载图像并且保存到沙盒
    ///
    ///  :param: urlString  urlString
    ///  :param: completion 完成回调
    func downloadImage(urlString: String, _ completion: Completion) {
        
        net.downloadImage(urlString, completion)
    }
    
    
    
}