
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
    
    // Entity that contains some data (NSData, Image, ets.) <Name: URL>
    
    @objc optional var data: Dictionary<String, URL> { get }
    
}


// Persistant storage controller. E.g. Core data stack controller or other.

@objc public protocol PersistentStorageControllerProtocol {
    
    @objc optional func update(_ entityName: String, with objects: TempObjectStorageProtocol, callback: SpiderCallback)
    
    @objc optional func remove(_ entityName: String, new objects: TempObjectStorageProtocol, callback: SpiderCallback)
    
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

public typealias SpiderNetworkResponseBlock = (_ objects: TempObjectStorageProtocol? , _ error: Error? ) -> (Void)
public typealias SpiderCallback = () -> (Void)

@objc public protocol NetworkControllerProtocol {
    
    @objc func executeRequest(_ request: URLRequest, response: @escaping SpiderNetworkResponseBlock) -> URLSessionTask
    
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
    var objectsStorage: TempObjectStorageProtocol? {
        get {
            return objc_getAssociatedObject(self, &objectsStorageAssociationKey) as? TempObjectStorageProtocol
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

public class Spider: NSObject {
    
    public var networkController: NetworkControllerProtocol
    public var storageController: PersistentStorageControllerProtocol
    public var request: URLRequest?
    public weak var delegate: SpiderDelegateProtocol?
    
    //You can modify "operations" before calling "execute".
    //But be aware - "operations" will be removed after "execute" was called
    public typealias SpiderOperationBlock = (_ dispatchGroup: DispatchGroup) -> Void
    public lazy var operations = [SpiderOperationBlock]()
    
    public var delegateQueue: DispatchQueue = DispatchQueue(label: "com.spider.delegateQueue")
    private let defaultQueue: DispatchQueue = DispatchQueue(label: "com.spider.defaultQueue")
    private let executionQueue: DispatchQueue = DispatchQueue(label: "com.spider.executionQueue")

    //    internal lazy var downloadOperations = [SpiderOperation]()
//    internal lazy var downloadEntities = [T]()
    
    public init(_ storageController: PersistentStorageControllerProtocol,
                networkController: NetworkControllerProtocol,
                request: URLRequest? = nil) {
        self.storageController = storageController
        self.networkController = networkController
        self.request = request
    }
    
    public func sendRequest(_ request: URLRequest? = nil) -> Self {
        guard request != nil || self.request != nil else {
            return self
        }
        operations.append{ [unowned self] group in
            self.enter(group)
            self.queue(forOperation: .sendRequest, entity: group.entityName).async {
                let task = self.networkController.executeRequest(request ?? self.request!, response: { response, error in
                    self.delegateQueue.sync {
                        self.delegate?.spider?(self, didGet: response, error: error)
                    }
                    if let resp = response {
                        group.objectsStorage = resp
                    }
                    self.leave(group, .sendRequest)
                })
                self.delegateQueue.sync {
                    self.delegate?.spider?(self, didExecute: task)
                }
            }
        }
        return self
    }
    
    public func writeInfo() -> Self {
        operations.append{ [unowned self] group in
            self.enter(group)
            guard let objectsStorage = group.objectsStorage else {
                group.leave()
                return
            }
            self.queue(forOperation: .writeInfo, entity: group.entityName).async {
                self.storageController.update!(group.entityName, with: objectsStorage) { self.leave(group, .writeInfo) }
            }
        }
        return self
    }

    public func deleteInfo() -> Self {
        operations.append{ [unowned self] group in
            self.enter(group)
            guard let objectsStorage = group.objectsStorage else {
                group.leave()
                return
            }
            self.queue(forOperation: .deleteInfo, entity: group.entityName).async {
                self.storageController.remove!(group.entityName, new: objectsStorage) { self.leave(group, .writeInfo) }
            }
        }
        return self
    }

    private func leave(_ group: DispatchGroup, _ operation: SpiderOperationType ) {
        self.delegateQueue.sync {
            self.delegate?.spider?(self, didFinishExecuting: operation)
        }
        group.leave()
    }
    
    private func enter(_ group: DispatchGroup) {
        group.wait()
        group.enter()
    }
    
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
        executionQueue.async { [unowned self] in
            group.entityName = entityName
            let ops = self.operations
            self.operations = [SpiderOperationBlock]()
            ops.forEach { operation in
                operation(group)
            }
        }
    }
    
    private func queue(forOperation operation: SpiderOperationType, entity name: String) -> DispatchQueue {
        let queue = delegate?.spider?(self, queueForOperation: operation, entityName: name) ?? defaultQueue
        return queue
    }
}
