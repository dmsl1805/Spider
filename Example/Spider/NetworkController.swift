//
//  NetworkController.swift
//  Spider
//
//  Created by Dmitriy Shulzhenko on 1/23/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Spider

class NetworkController: NSObject, NetworkControllerProtocol {
    
    func executeRequest(_ request: URLRequest,
                        response: @escaping SpiderNetworkResponseBlock) -> URLSessionTask {
        
        logRequest(request)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [unowned self] (data, urlResponse, error) in
            self.logResponse(request, response: urlResponse, error: error)
            if error == nil {
                if let data = data {
                    do {
                        let jsonValue = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, Any>
                        response(NetworkResponse(jsonValue), nil)
                    } catch let error {
                        response(nil, error)
                    }
                }
            } else {
                response(nil, error)
            }
        })
        task.resume()
        return task
    }
    
    func logResponse(_ request: URLRequest, response: URLResponse?, error: Error?) {
        if let err = error {
            ePrint(err, "was caused by:", request)
        } else {
            iPrint(response ?? "cannot get any response or error", " for: ", request)
        }
    }
    
    func logRequest(_ request: URLRequest) {
        wPrint("execute request: ", request)
    }
}
