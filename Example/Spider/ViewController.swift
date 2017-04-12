//
//  ViewController.swift
//  Spider
//
//  Created by Dmitriy Shulzhenko on 01/19/2017.
//  Copyright (c) 2017 Dmitriy Shulzhenko. All rights reserved.
//

import UIKit
import Spider

class ViewController: UIViewController, SpiderDelegateProtocol, SpiderDataSourceProtocol {


    @IBOutlet var londonItem: UIBarButtonItem!
    @IBOutlet var minskItem: UIBarButtonItem!
    @IBOutlet var kievItem: UIBarButtonItem!
    
    var selectedCityID: Int = 0
    var forecastUpdateRequest: URLRequest {
        let url = URL(string: openweatherForecastApiDomain.appending("?id=\(selectedCityID)&APPID=\(openweatherAPPID)&units=metric"))!
        let req = URLRequest(url: url)
        return req
    }
    
    let imageRequest = URLRequest(url: URL(string: "http://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74393/world.topo.200407.3x5400x2700.png")!)
    
    lazy var spider: Spider = {
        let storageController = PersistentStorageController(modelName: "Model")
        let networkController = NetworkController()
        return Spider(storageController, networkController: networkController)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spider.delegate = self
        spider.dataSource = self
        spider.delegateQueue = DispatchQueue.main
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
        spider.request().delete().write().execute(forEntity: Forecast.entityName)
//        spider.sendRequest(forecastUpdateRequest).deleteInfo().writeInfo().execute(forEntity: Forecast.entityName)
        
        
    }
    
    @IBAction func printCurrentStore(_ sender: Any) {
        let psc = spider.storageController as! PersistentStorageController
        psc.fetchAllForecast().forEach { forecast in
            print("city \(forecast.city_id) forecast - \(forecast.weather_descr ?? "") temp - \(forecast.temp.description)")
        }
//        print(psc.fetchAllForecast())
    }
    
    func spider(_ spider: Spider,
                didGet response: TempObjectStorageProtocol?,
                error: Error?) {
        print("did get response", response ?? "response nil", error ?? "error nil")
    }
    
    func spider(_ spider: Spider, didExecute task: URLSessionTask) {
        print("did execute", task)
    }
    
    func spider(_ spider: Spider, didFinishExecuting operation: SpiderOperationType) {
        print("did finish executing", operation)
//        switch operation {
//        case .writeInfo:
//            let psc = self.spider.storageController as! PersistentStorageController
//            self.forecastModel = psc.fetchAllForecast()
//        default:
//            break;
//        }
    }
    
    func spider(_ spider: Spider, requestForOperation: SpiderOperationType, entity: String) -> DataRequestProtocol {
        return forecastUpdateRequest

    }

    func spider(_ spider: Spider, didExecute task: DataTaskProtocol) {
        //
    }

}

