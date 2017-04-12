//
//  NetworkController.swift
//  Spider
//
//  Created by Dmitriy Shulzhenko on 1/23/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Spider

extension URLSessionTask: DataTaskProtocol { }
extension URLRequest: DataRequestProtocol { }

class NetworkController: NSObject, NetworkControllerProtocol {
    func execute(_ dataRequest: DataRequestProtocol, response: @escaping SpiderNetworkResponseBlock) -> DataTaskProtocol {
        guard let request = dataRequest as? URLRequest else {
            fatalError()
        }
        logRequest(request)
        let task = URLSession.shared.downloadTask(with: request) { (dataUrl, urlResponse, error) in
            self.logResponse(request, response: urlResponse, error: error)
            if error == nil {
                do {
                    let data = try Data(contentsOf: dataUrl!)
                    do {
                        let jsonValue = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, Any>
                        response(NetworkResponse(jsonValue), nil)
                    } catch let error {
                        if let image = UIImage(data: data) {
                            response(NetworkImageResponse(image), nil)
                        } else {
                            response(nil, error)
                        }
                    }
                } catch {
                    response(nil, error)
                }
            } else {
                response(nil, error)
            }
        }
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
