//
//  ViewController.swift
//  Spider
//
//  Created by Dmitriy Shulzhenko on 01/19/2017.
//  Copyright (c) 2017 Dmitriy Shulzhenko. All rights reserved.
//

import UIKit
import Spider

class ViewController: UIViewController, SpiderDelegateProtocol, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var londonItem: UIBarButtonItem!
    @IBOutlet var minskItem: UIBarButtonItem!
    @IBOutlet var kievItem: UIBarButtonItem!
    
    var forecastModel = [Forecast]()
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
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
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
        spider.sendRequest(forecastUpdateRequest).deleteInfo().writeInfo().execute(forEntity: Forecast.entityName)
    }
    
    @IBAction func printCurrentStore(_ sender: Any) {
        let psc = spider.storageController as! PersistentStorageController
        print(psc.fetchAllForecast())
    }
    
    func spider(_ spider: SpiderProtocol,
                didGet response: TempObjectStorageProtocol?,
                error: Error?) {
        
    }
    
    func spider(_ spider: SpiderProtocol, didFinishExecuting operation: SpiderOperationType) {
        switch operation {
        case .writeInfo:
            let psc = self.spider.storageController as! PersistentStorageController
            self.forecastModel = psc.fetchAllForecast()
            self.tableView.reloadData()
        default:
            break;
        }
    }
    
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forecastModel.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(forecastModel[indexPath.row].date)"
        cell.detailTextLabel?.text = "\(forecastModel[indexPath.row].weather_descr)"
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
}

