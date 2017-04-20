
//  Created by Dmitriy Shulzhenko on 9/5/16.
//  Copyright © 2016 . All rights reserved.
//

import Foundation

public enum SpiderOperationType {
    case request
    case write
    case delete
}

public protocol DataRequestProtocol { }

public protocol DataTaskProtocol { }

// This is your storage for any network responce
// Storage will be used to update model

public protocol TempObjectStorageProtocol { }

// Entity object. Can be subclass of NSManagedObject, or smth else

public protocol EntityProtocol { }

// Persistant storage controller. E.g. Core data stack controller or other.

public protocol PersistentStorageControllerProtocol {
    
    func update(_ entity: EntityProtocol.Type, with objects: TempObjectStorageProtocol, done: @escaping SpiderCallback)
    
    func remove(_ entity: EntityProtocol.Type, incoming objects: TempObjectStorageProtocol, done: @escaping SpiderCallback)
}

// MARK: Network manager

public typealias SpiderNetworkResponseBlock = (_ objects: TempObjectStorageProtocol? , _ error: Error? ) -> (Void)

public typealias SpiderCallback = () -> (Void)

public protocol NetworkControllerProtocol {
    
    func execute(_ dataRequest: DataRequestProtocol, response: @escaping SpiderNetworkResponseBlock) -> DataTaskProtocol
}

// MARK: Delegate

public protocol SpiderDelegateProtocol: class {
    
    func spider(_ spider: Spider, didExecute task: DataTaskProtocol)
    
    func spider(_ spider: Spider, didGet response: TempObjectStorageProtocol?,  error: Error?)
    
    func spider(_ spider: Spider, willExecute operation: SpiderOperationType, execute: @escaping SpiderCallback)
    
    func spider(_ spider: Spider, didFinishExecuting operation: SpiderOperationType)
}

// MARK: Data source

public protocol SpiderDataSourceProtocol: class {
    
    func spider(_ spider: Spider, requestForOperation: SpiderOperationType, entity: EntityProtocol.Type) -> DataRequestProtocol
}

// MARK: Queue provider

public protocol SpiderQueueProviderProtocol: class {
    
    func spider(_ spider: Spider, queueForOperation: SpiderOperationType, entity: EntityProtocol.Type) -> DispatchQueue
}

// MARK: Operation terminator

public protocol SpiderOperationTerminatorProtocol: class {
    
    func spider(_ spider: Spider, shouldTerminate operation: SpiderOperationType, entity: EntityProtocol.Type) -> Bool
}

// MARK: DispatchGroup with storage

fileprivate var objectsStorageAssociationKey: UInt8 = 0
fileprivate var entityNameAssociationKey: UInt8 = 0
private extension DispatchGroup {
    var objectsStorage: TempObjectStorageProtocol? {
        get {
            return objc_getAssociatedObject(self, &objectsStorageAssociationKey) as? TempObjectStorageProtocol
        }
        set {
            objc_setAssociatedObject(self, &objectsStorageAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    var entityType: EntityProtocol.Type {
        get {
            return objc_getAssociatedObject(self, &entityNameAssociationKey) as! EntityProtocol.Type
        }
        set {
            objc_setAssociatedObject(self, &entityNameAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}

public class Spider: NSObject {
    
    private let defaultQueue: DispatchQueue = DispatchQueue(label: "com.spider.defaultQueue")
    private let executionQueue: DispatchQueue = DispatchQueue(label: "com.spider.executionQueue")
    
    public typealias SpiderOperationBlock = (_ dispatchGroup: DispatchGroup) -> Void
    //You can modify "operations" to add your custom before calling "execute".
    //But be aware - "operations" will be removed after "execute" was called
    public lazy var operations = [SpiderOperationBlock]()
    
    public var networkController: NetworkControllerProtocol
    public var storageController: PersistentStorageControllerProtocol
    public weak var delegate: SpiderDelegateProtocol?
    public weak var dataSource: SpiderDataSourceProtocol?
    public weak var queueProvider: SpiderQueueProviderProtocol?
    public weak var operationTerminator: SpiderOperationTerminatorProtocol?
    
    public var delegateQueue: DispatchQueue = DispatchQueue(label: "com.spider.delegateQueue")
    
    public var isLogsEnabled = false
    
    public init(_ storageController: PersistentStorageControllerProtocol,
                networkController: NetworkControllerProtocol) {
        self.storageController = storageController
        self.networkController = networkController
    }
    
    public func request() -> Self {
        operations.append{ [unowned self] group in
            self.perform(on: group, operation: .request) {
                if let request = self.dataSource?.spider(self, requestForOperation: .request, entity: group.entityType) {
                    let task = self.networkController.execute(request) { response, error in
                        self.delegateQueue.sync {
                            self.delegate?.spider(self, didGet: response, error: error)
                        }
                        if let resp = response {
                            group.objectsStorage = resp
                        }
                        self.leave(group, .request)
                    }
                    self.delegateQueue.sync {
                        self.delegate?.spider(self, didExecute: task)
                    }
                } else {
                    self.log("dataSource.requestForOperation - request is nil", .request)
                    self.leave(group, .request)
                }
            }
        }
        return self
    }
    
    public func write() -> Self {
        operations.append{ [unowned self] group in
            self.performWithStore(on: group, operation: .write) { [unowned self] store in
                self.storageController.update(group.entityType, with: store) {
                    self.leave(group, .write)
                }
            }
        }
        return self
    }
    
    public func delete() -> Self {
        operations.append{ [unowned self] group in
            self.performWithStore(on: group, operation: .delete) { [unowned self] store in
                self.storageController.remove(group.entityType, incoming: store) {
                    self.leave(group, .delete)
                }
            }
        }
        return self
    }
    
    public func execute<Entity: EntityProtocol>(forEntity entity: Entity.Type) {
        guard operations.count > 0 else { return }
        let group = DispatchGroup()
        executionQueue.async { [unowned self] in
            group.entityType = entity
            let ops = self.operations
            self.operations = [SpiderOperationBlock]()
            ops.forEach { operation in
                operation(group)
            }
        }
    }
    
    private func leave(_ group: DispatchGroup, _ operation: SpiderOperationType ) {
        self.delegateQueue.sync {
            self.delegate?.spider(self, didFinishExecuting: operation)
        }
        group.leave()
    }
    
    private func enter(_ group: DispatchGroup) {
        group.wait()
        group.enter()
    }
    
    private func queue(forOperation operation: SpiderOperationType, entity: EntityProtocol.Type) -> DispatchQueue {
        return queueProvider?.spider(self, queueForOperation: operation, entity: entity) ?? defaultQueue
    }
    
    private func terminate(operation: SpiderOperationType, entity: EntityProtocol.Type) -> Bool {
        return operationTerminator?.spider(self, shouldTerminate: operation, entity: entity) ?? false
    }
    
    private func askDelegateOrExecute(operation: SpiderOperationType, block: @escaping SpiderCallback) {
        if let delegate = self.delegate {
            delegate.spider(self, willExecute: operation, execute: block)
        } else {
            block()
        }
    }
    
    private func performWithStore(on group: DispatchGroup, operation: SpiderOperationType, block: @escaping (_ store: TempObjectStorageProtocol) -> Void) {
        perform(on: group, operation: operation) {
            guard let store = group.objectsStorage else {
                self.log("objectsStorage is nil", .delete)
                group.leave()
                return
            }
            block(store)
        }
    }
    
    private func perform(on group: DispatchGroup, operation: SpiderOperationType, block: @escaping SpiderCallback) {
        self.enter(group)
        self.queue(forOperation: operation, entity: group.entityType).async {
            guard self.terminate(operation: operation, entity: group.entityType) == false else {
                self.log("terminated ", operation)
                return
            }
            self.askDelegateOrExecute(operation: operation, block: block)
        }
    }
    
    private func log(_ message: String, _ operation: SpiderOperationType) {
        if isLogsEnabled {
            print("Spider log: \(message). In operation: \(operation)")
        }
    }
}
