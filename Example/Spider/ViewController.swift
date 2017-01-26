//
//  ViewController.swift
//  Spider
//
//  Created by Dmitriy Shulzhenko on 01/19/2017.
//  Copyright (c) 2017 Dmitriy Shulzhenko. All rights reserved.
//

import UIKit
import Spider

class ViewController: UIViewController, SpiderDelegateProtocol {
    
    @IBOutlet var londonItem: UIBarButtonItem!
    @IBOutlet var minskItem: UIBarButtonItem!
    @IBOutlet var kievItem: UIBarButtonItem!
    
    var selectedCityID: Int = 0
    var forecastUpdateRequest: URLRequest {
        let url = URL(string: openweatherForecastApiDomain.appending("?id=\(selectedCityID)&APPID=\(openweatherAPPID)&units=metric"))!
        let req = URLRequest(url: url)
        return req
    }
    
    lazy var spider: Spider = {
        let storageController = PersistentStorageController(modelName: "Model")
        let networkController = NetworkController()
        return Spider(storageController, networkController: networkController)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spider.delegate = self
    }
    
    @IBAction func itemSelected(_ sender: UIBarButtonItem) {
        switch sender {
        case self.kievItem: self.selectedCityID = 703448
        case self.minskItem: self.selectedCityID = 625144
        case self.londonItem: self.selectedCityID = 5056033

        default:
            break
        }
        /*deleteInfo().writeInfo().*/
        spider.sendRequest(forecastUpdateRequest).deleteInfo().writeInfo().execute(forEntity: Forecast.entityName)
        
        
    }
    
    @IBAction func printCurrentStore(_ sender: Any) {
        let psc = spider.storageController as! PersistentStorageController
        print(psc.fetchAllForecast())
    }
    
    func spider(_ spider: Spider,
                didGet response: TempObjectStorageProtocol?,
                error: Error?) {
        
    }
    
    func spider(_ spider: Spider, didFinishExecuting operation: SpiderOperationType) {
//        switch operation {
//        case .writeInfo:
//            let psc = self.spider.storageController as! PersistentStorageController
//            self.forecastModel = psc.fetchAllForecast()
//        default:
//            break;
//        }
    }

}

