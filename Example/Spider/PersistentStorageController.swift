//
//  PersistentStorageController.swift
//
//  Created by Dmitriy Shulzhenko on 1/11/17.
//  Copyright © 2017 Dmitriy Shulzhenko. All rights reserved.
//

import CoreData
import Spider

class PersistentStorageController: NSObject {
    private let modelName: String
    private var _contextStore: (main: NSManagedObjectContext, background: NSManagedObjectContext)!
    public var contextStore: (main: NSManagedObjectContext, background: NSManagedObjectContext) {
        get {
            if _contextStore == nil {
                let options = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
                let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd")!
                let objectModel = NSManagedObjectModel(contentsOf: modelURL)!
                let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
                let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
                var directory: ObjCBool = ObjCBool(false)
                if ( !FileManager.default.fileExists(atPath: docDir.path, isDirectory: &directory) ) {
                    do {
                        try FileManager.default.createDirectory(atPath: docDir.path, withIntermediateDirectories: true, attributes: nil)
                    } catch let error as NSError  {
                        print("Could not create directory for persistent store\(error), \(error.userInfo)")
                    }
                }
                let storeURL = docDir.appendingPathComponent("xModel")
                do {
                    try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                                      configurationName: nil,
                                                                      at: storeURL,
                                                                      options: options)
                } catch let error as NSError  {
                    print("Could not create persistent store\(error), \(error.userInfo)")
                }
                
                let main = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
                main.persistentStoreCoordinator = persistentStoreCoordinator
                let background = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                background.persistentStoreCoordinator = persistentStoreCoordinator
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(mergeFromNotification(notification:)),
                                                       name: .NSManagedObjectContextDidSave,
                                                       object: background)
                _contextStore = (main, background)
            }
            return _contextStore
        }
    }
    
    init(modelName name: String) {
        self.modelName = name
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func save() {
        guard self.contextStore.background.hasChanges else { return }
        do {
            try self.contextStore.background.save()
        } catch let error as NSError  {
            print("Could not save background context\(error), \(error.userInfo)")
        }
    }
    
    @objc private func mergeFromNotification(notification: Notification) -> Void {
        guard notification.object as! NSManagedObjectContext === self.contextStore.background else { return }
        self.contextStore.main.mergeChanges(fromContextDidSave: notification)
    }
}


extension PersistentStorageController: PersistentStorageControllerProtocol {
    
    func update(_ entity: EntityProtocol.Type, with objects: TempObjectStorageProtocol, done: @escaping () -> (Void)) {

        let objects = objects as! NetworkResponse
        let list = objects.objects["list"] as! Array<Dictionary<String, Any>>
        list.forEach({ forecast in
            let entity = insertEntity(Forecast.entityName) as! Forecast
            let dateTxt = forecast["dt_txt"] as! String
            let format = DateFormatter()
            format.dateFormat = "yyyy-mm-dd HH:mm:ss"
            let date = format.date(from: dateTxt)
            entity.date = date as NSDate?
            
            let city = objects.objects["city"] as! Dictionary<String, Any>
            let cityId = city["id"] as! Int32
            entity.city_id = cityId
            
            if let clouds = (forecast["clouds"] as? Dictionary<String, Any>)?["all"] as? Int16 {
                entity.clouds = clouds
            }
            if let rain = (forecast["rain"] as? Dictionary<String, Any>)?["3h"] as? Float {
                entity.rain = rain
            }
            if let snow = (forecast["snow"] as? Dictionary<String, Any>)?["3h"] as? Float {
                entity.snow = snow
            }
            if let temp = (forecast["main"] as? Dictionary<String, Any>)?["temp"] as? Float {
                entity.temp = temp
            }
            if let wind = (forecast["wind"] as? Dictionary<String, Any>)?["speed"] as? Float {
                entity.wind = wind
            }
            let weather = ((forecast["weather"] as? Array<Any>)?.first as? Dictionary<String, Any>)?["description"] as? String
            entity.weather_descr = weather
        })
        
        save()
        done()
    }
    
    func remove(_ entity: EntityProtocol.Type, incoming objects: TempObjectStorageProtocol, done: @escaping () -> (Void)) {
        fetch(Forecast.entityName)?.forEach({[unowned self] entity in
            let objectInBg = self.contextStore.background.object(with: (entity as! NSManagedObject).objectID)
            self.contextStore.background.delete(objectInBg)
        })
        
        save()
        done()
    }

    
    //MARK: Custom helpers
    
    func insertEntity(_ name: String) -> EntityProtocol {
        return NSEntityDescription.insertNewObject(forEntityName: name,
                                                   into: self.contextStore.background) as! EntityProtocol
    }
    
    func fetchAllForecast() -> [Forecast] {
        let sortDescr = NSSortDescriptor(key: "date",
                                         ascending: true)
        return fetch(Forecast.entityName,
                     andSort: [sortDescr]) as! [Forecast]
    }
    
    func fetch(_ entityName: String,
               withPredicate predicate: NSPredicate? = nil,
               andSort sortDescriptors: [NSSortDescriptor]? = nil) -> [EntityProtocol]? {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: entityName, in: self.contextStore.main)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        do {
            let results = try self.contextStore.main.fetch(request)
            return (results as! [EntityProtocol])
        } catch let error {
            print("error while fetching with predicate \(predicate?.description ?? "nil"), from persistent store, error: \(error)")
            return nil
        }
    }
    

}

extension Forecast: EntityProtocol {
    public static var entityName: String {
        let req: NSFetchRequest<Forecast> = Forecast.fetchRequest()
        return req.entityName ?? "Forecast"
    }
}


