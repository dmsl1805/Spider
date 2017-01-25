
//  Created by Dmitriy Shulzhenko on 9/5/16.
//  Copyright © 2016 . All rights reserved.
//

import Foundation

@objc public enum SpiderOperationType: Int {
    case sendRequest
    case writeInfo
    case deleteInfo
    //case postInfo
    //case downloadData
    //case writeData
    //case deleteData
}

// This is your storage for any network responce
// Storage will be used to update model

@objc public protocol TempObjectStorageProtocol: class{ }


// Entity object. Can be subclass of NSManagedObject, or smth else

@objc public protocol EntityProtocol {
    
    @objc static var entityName: String { get }
    
    // Entity that contains some data (NSData, Image, ets.)
    
    //    @objc optional var dataRemoutePaths: [String] { get }
    //
    //    @objc optional var dataNames: [String] { get }
    
}


// Persistant storage controller. E.g. Core data stack controller or other.

@objc public protocol PersistentStorageControllerProtocol {
    
    @objc optional func update(_ entityName: String, with objects: TempObjectStorageProtocol)
    
    @objc optional func remove(_ entityName: String, new objects: TempObjectStorageProtocol)
    
    //    @objc optional func fetchWithoutData(name: String) -> [EntityProtocol]?
    
    //    @objc optional func write(data dataStore: [TempObjectStorageProtocol], completed:((_ error: Error?) -> Void))
    
    //    @objc func delete(data named: String, completed:((_ error: Error?) -> Void))
    
    //    @objc optional func get(data named: String) -> Data?
    
    //
    //    @objc optional var entitiesCount: Int { get }
    //
    //    @objc optional func entity(atIndex index: Int) -> EntityProtocol
    //
    //    @objc optional func index(of entity: EntityProtocol) -> NSNumber?
    //
    //    @objc optional func fetch(withName name: String) -> EntityProtocol
    //
    //    @objc optional func fetch(withPredicate predicate: NSPredicate?,
    //                              name: String) -> [EntityProtocol]?
    //
    
}


// MARK: Network manager

public typealias NetworkResponseBlock = (_ objects: TempObjectStorageProtocol? , _ error: Error? ) -> (Void)

@objc public protocol NetworkControllerProtocol {
    
    @objc func executeRequest(_ request: URLRequest, response: @escaping NetworkResponseBlock) -> URLSessionTask
    
    //    @objc optional func download(from: String,
    //                                 response: NetworkDataResponseBlock) -> URLSessionTask
    //
}


@objc public protocol SpiderDelegateProtocol {
    
    @objc optional func spider(_ spider: Spider,
                               didExecute task: URLSessionTask)
    
    @objc optional func spider(_ spider: Spider,
                               didGet response: TempObjectStorageProtocol?,
                               error: Error?)
    
    @objc optional func spider(_ spider: Spider,
                               didFinishExecuting operation: SpiderOperationType)
    
//    @objc optional func spider(_ spider: Spider,
//                               didDownload dataStore: TempObjectStorageProtocol?,
//                               forEntity: EntityProtocol,
//                               error: Error?)
//    
//    @objc optional func spider(_ spider: Spider,
//                               willWrite dataStore: TempObjectStorageProtocol,
//                               forEntity: EntityProtocol)
    
    @objc optional func spider(_ spider: Spider,
                               queueForOperation: SpiderOperationType,
                               entityName: String) -> DispatchQueue
    
    //    @objc optional func spider(_ spider: SpiderProtocol,
    //                               shouldTerminate operation: SpiderOperationType) -> Bool
}


private var objectsStorageAssociationKey: UInt8 = 0
private var entityNameAssociationKey: UInt8 = 0

private extension DispatchGroup {
    var objectsStorage: TempObjectStorageProtocol {
        get {
            return objc_getAssociatedObject(self, &objectsStorageAssociationKey) as! TempObjectStorageProtocol
        }
        set {
            objc_setAssociatedObject(self, &objectsStorageAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    var entityName: String {
        get {
            return objc_getAssociatedObject(self, &entityNameAssociationKey) as! String
        }
        set {
            objc_setAssociatedObject(self, &entityNameAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}

private let defaultQueueLabel: String = "com.spider.defaultQueue"

public class Spider: NSObject {
    
    public var delegateQueue: DispatchQueue
    public var networkController: NetworkControllerProtocol
    public var storageController: PersistentStorageControllerProtocol
    public var request: URLRequest?
    public weak var delegate: SpiderDelegateProtocol?
    
    //You can modify "operations" before calling "execute".
    //But be aware - "operations" will be removed after "execute" was called
    public typealias SpiderOperationBlock = (_ dispatchGroup: DispatchGroup, _ objectsStorage: inout TempObjectStorageProtocol?) -> Void
    public lazy var operations = [SpiderOperationBlock]()
    

    //    internal lazy var downloadOperations = [SpiderOperation]()
//    internal lazy var downloadEntities = [T]()
    
    public init(_ storageController: PersistentStorageControllerProtocol,
                networkController: NetworkControllerProtocol,
                request: URLRequest? = nil,
                delegate: SpiderDelegateProtocol? = nil,
                delegateQueue: DispatchQueue = DispatchQueue.main) {
        self.storageController = storageController
        self.networkController = networkController
        self.request = request
        self.delegate = delegate
        self.delegateQueue = delegateQueue
        super.init()
    }
    
    public func sendRequest(_ request: URLRequest? = nil) -> Spider {
        guard request != nil || self.request != nil else {
            return self
        }
        operations.append{ [unowned self] group, store in
            group.wait()
            group.enter()
            self.queue(forOperation: .sendRequest, entity: group.entityName).async {
                let task = self.networkController.executeRequest(request ?? self.request!, response: { response, error in
                    self.delegateQueue.sync {
                        self.delegate?.spider?(self, didGet: response, error: error)
                    }
                    if let resp = response {
                        group.objectsStorage = resp
                    }
                    self.delegateQueue.sync {
                        self.delegate?.spider?(self, didFinishExecuting: .sendRequest)
                    }
                    group.leave()
                })
                self.delegateQueue.sync {
                    self.delegate?.spider?(self, didExecute: task)
                }
            }
        }
        
//        let op = SpiderOperation { [unowned self] operation in
//            if let terminate = self.delegate?.spider?(self, shouldTerminate: .getInfo), terminate == true {
//                self.delegateQueue.addOperation {
//                    self.delegate?.spider?(self, didFinishExecuting: .getInfo)
//                }
//                operation.finish()
//            }
//            let task = self.networkController.executeRequest(request ?? self.request!, response: { resp, error in
//                self.delegateQueue.addOperation {
//                    self.delegate?.spider?(self, didGet: resp, error: error)
//                }
//                operation.objectStorage = resp
//                self.delegateQueue.addOperation {
//                    self.delegate?.spider?(self, didFinishExecuting: .getInfo)
//                }
//                operation.finish()
//            })
//            self.delegateQueue.addOperation {
//                self.delegate?.spider?(self, didExecute: task)
//            }
//        }
//        //TODO: Allow user suspend task and than execute it
//        //            let resume = self.delegate?.spider?(self, didExecute: task!, {
//        //                if case .suspended = task!.state {
//        //                    task!.resume()
//        //                }
//        //            })
//        //
//        //            if resume == nil, case .suspended = task!.state {
//        //                task!.resume()
//        //            }
//        if let newDependency = operations.last {
//            op.addDependency(newDependency)
//        }
//        operations.append(op)
        return self
    }
    
//    public func writeInfo() -> Spider {
//        let op = SpiderOperation { [unowned self] operation in
//            self.delegateQueue.addOperation {
//                if let terminate = self.delegate?.spider?(self, shouldTerminate: .getInfo), terminate == true {
//                    self.delegate?.spider?(self, didFinishExecuting: .writeInfo)
//                    operation.finish()
//                }
//            }
//            if let store = operation.objectStorage {
//                self.storageController.update!(self.entityName, with: store)
//            }
//            self.delegateQueue.addOperation {
//                self.delegate?.spider?(self, didFinishExecuting: .writeInfo)
//            }
//            operation.finish()
//        }
//        if let newDependency = operations.last {
//            op.addDependency(newDependency)
//        }
//        operations.append(op)
//        return self
//    }
    
//    public func deleteInfo() -> Spider {
//        let op = SpiderOperation { [unowned self] (operation) in
//            self.delegateQueue.addOperation {
//                if let terminate = self.delegate?.spider?(self, shouldTerminate: .getInfo), terminate == true {
//                    self.delegate?.spider?(self, didFinishExecuting: .deleteInfo)
//                    operation.finish()
//                }
//            }
//            if let storage = operation.objectStorage {
//                self.storageController.remove!(self.entityName, new: storage)
//            }
//            self.delegateQueue.addOperation {
//                self.delegate?.spider?(self, didFinishExecuting: .deleteInfo)
//            }
//            operation.finish()
//        }
//        if let newDependency = operations.last {
//            op.addDependency(newDependency)
//        }
//        operations.append(op)
//        return self
//    }
    
//    private func addDownloadOperations() {
//        downloadEntities.forEach({ [unowned self] entity in
//            guard entity.dataRemoutePaths != nil, entity.dataRemoutePaths!.count > 0  else { return }
//            
//            entity.dataRemoutePaths!.forEach({ path in
//                let op = SpiderOperation { operation in
//                    if let task = self.networkManager.download?(from: path, response: { dataStore, error -> (Void) in
//                        self.delegate?.spider?(self, didDownload: dataStore, forEntity: entity, error: error)
//                        if let store = dataStore {
//                            operation.objectStorage = [store]
//                        }
//                        operation.finish()
//                    }) {
//                        self.delegate?.spider?(self, didExecute: task)
//                    } else {
//                        self.delegate?.spider?(self, didFinishExecuting: .downloadData)
//                        operation.finish()
//                    }
//                }
//                op.queuePriority = self.delegate?.spider?(self, queuePiority: entity, dataPath: path) ?? .normal
//                op.qualityOfService = self.delegate?.spider?(self, qualityOfService: entity, dataPath: path) ?? .default
//                if let newDependency = self.operations.last {
//                    op.addDependency(newDependency)
//                }
//                self.operations.append(op)
//            })
//        })
//    }
//    
//    public func downloadData(_ forEntities: [T]? = nil) -> Spider<T> {
//        self.downloadEntities = forEntities ?? self.persistentStore.fetchWithoutData?(name: T.entityName) as? [T] ?? [T]()
//        self.addDownloadOperations()
//        return self
//    }

    public func execute(forEntity entityName: String) {
        guard operations.count > 0 else { return }
        let group = DispatchGroup()
        group.entityName = entityName
        var storage: TempObjectStorageProtocol? = nil
        self.operations.forEach { operation in
            operation(group, &storage)
        }
        operations = [SpiderOperationBlock]()
    }
    
    private func queue(forOperation operation: SpiderOperationType, entity name: String) -> DispatchQueue {
        return delegate?.spider?(self, queueForOperation: operation, entityName: name) ?? DispatchQueue(label: defaultQueueLabel)
    }
}
