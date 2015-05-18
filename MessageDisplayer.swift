//
//  MessageDisplayer.swift
//  Lolita-public
//
//  Created by Sam on 5/5/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.


import UIKit


class MessageDisplayer {
    

    func displayError(error : NSError) {

        let alertView = UIAlertView(title: "Failed", message: "code : \(error.code) , detail: \(error.description)", delegate: nil, cancelButtonTitle: "造了")
        
    }
    
    
}