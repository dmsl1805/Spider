//
//  PersistentStorageController.swift
//  Weather
//
//  Created by Dmitriy Shulzhenko on 1/11/17.
//  Copyright © 2017 Dmitriy Shulzhenko. All rights reserved.
//

import CoreData
import UIKit

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
