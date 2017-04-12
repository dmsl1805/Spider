//
//  ViewController.swift
//  Spider_Weather_App_Example
//
//  Created by Dmitriy Shulzhenko on 1/24/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

protocol ModelProtocol {
    
}

protocol ViewProtocol {
    func addSubviews()
    func configure(model: ModelProtocol)
}

class BasicCell: UITableViewCell, ViewProtocol {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubviews()
    }
    
    func addSubviews() { }
    
    func configure(model: ModelProtocol) { }
}

class SomeCell: BasicCell {
    let someCellImageView = UIImageView()
    let someCellLabel = UILabel()
    
    override func addSubviews() {
        addSubview(someCellLabel)
        addSubview(someCellImageView)
    }
    
    override func configure(model: ModelProtocol){
        textLabel?.text = (model as! SomeModel).textForLabel
    }
    
}

struct SomeModel: ModelProtocol {
    var textForLabel: String
}

class DataSource: NSObject, UITableViewDataSource {
    
    let cellIdentifier: String
    
    var model = [SomeModel]()
    
    init(cellIdentifier: String) {
        self.cellIdentifier = cellIdentifier
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        return cell
    }
}

class TableViewController: UITableViewController {

    let cellID: String = "Cell"
    let model = [SomeModel(textForLabel: "1"),SomeModel(textForLabel: "1"),SomeModel(textForLabel: "1"),SomeModel(textForLabel: "1"),SomeModel(textForLabel: "1"),SomeModel(textForLabel: "1"),SomeModel(textForLabel: "1"),SomeModel(textForLabel: "1"),SomeModel(textForLabel: "1"),SomeModel(textForLabel: "1")]
//    let tableView
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SomeCell.self, forCellReuseIdentifier: cellID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! BasicCell
        cell.configure(model: model[indexPath.row])
        return cell
    }

}

