//
//  NetworkResponse.swift
//  Spider
//
//  Created by Dmitriy Shulzhenko on 1/23/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Spider


class NetworkResponse: NSObject, TempObjectStorageProtocol {
    
    var objects: Dictionary<String, Any>
    
    init(_ objects: Dictionary<String, Any>) {
        self.objects = objects
    }
    
}

class NetworkImageResponse: NSObject, TempObjectStorageProtocol {
    
    var image: UIImage
    
    init(_ image: UIImage) {
        self.image = image
    }
    
}
