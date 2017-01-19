
//  Created by Dmitriy Shulzhenko on 9/5/16.
//  Copyright © 2016 . All rights reserved.
//

import Foundation


public class Spider<T: EntityProtocol> : NSObject, SpiderProtocol {
    
    public var queue: OperationQueue
    public var networkController: NetworkControllerProtocol
    public var storageController: PersistentStorageControllerProtocol
    public var request: HTTPRequestProtocol
    public weak var delegate: SpiderDelegateProtocol?
    
    //You can modify "operations" before calling "execute".
    //But be aware - "operations" will be removed after "execute" was called
    public lazy var operations = [SpiderOperation]()
    
    //    internal lazy var downloadOperations = [SpiderOperation]()
    internal lazy var downloadEntities = [T]()
    
    public init(_ storageController: PersistentStorageControllerProtocol,
                networkController: NetworkControllerProtocol,
                request: HTTPRequestProtocol,
                delegate: SpiderDelegateProtocol? = nil,
                queue: OperationQueue? = OperationQueue()) {
        self.storageController = storageController
        self.networkController = networkController
        self.request = request
        self.delegate = delegate
        self.queue = queue!
        super.init()
    }

    
    public func sendRequest() -> Spider<T> {
        let op = SpiderOperation { [unowned self] operation in
            if let terminate = self.delegate?.spider?(self, shouldTerminate: .getInfo), terminate == true {
                self.delegate?.spider?(self, didFinishExecuting: .getInfo)
                operation.finish()
            }
            let task = self.networkController.executeRequest(self.request, response: { resp, error in
                self.delegate?.spider?(self, didGet: resp, error: error)
                operation.objectStorage = resp
                self.delegate?.spider?(self, didFinishExecuting: .getInfo)
                operation.finish()
            })
            self.delegate?.spider?(self, didExecute: task)
        }
        //TODO: Allow user suspend task and than execute it
        //            let resume = self.delegate?.spider?(self, didExecute: task!, {
        //                if case .suspended = task!.state {
        //                    task!.resume()
        //                }
        //            })
        //
        //            if resume == nil, case .suspended = task!.state {
        //                task!.resume()
        //            }
        if let newDependency = operations.last {
            op.addDependency(newDependency)
        }
        operations.append(op)
        return self
    }
    
    public func writeInfo() -> Spider<T> {
        let op = SpiderOperation { [unowned self] operation in
            if let terminate = self.delegate?.spider?(self, shouldTerminate: .getInfo), terminate == true {
                self.delegate?.spider?(self, didFinishExecuting: .getInfo)
                operation.finish()
            }
            if let store = operation.objectStorage {
                self.storageController.update?(name: T.entityName, with: store)
            }
            self.delegate?.spider?(self, didFinishExecuting: .writeInfo)
            operation.finish()
        }
        if let newDependency = operations.last {
            op.addDependency(newDependency)
        }
        operations.append(op)
        return self
    }
    
    public func deleteInfo() -> Spider<T> {
        let op = SpiderOperation { [unowned self] (operation) in
            if let terminate = self.delegate?.spider?(self, shouldTerminate: .getInfo), terminate == true {
                self.delegate?.spider?(self, didFinishExecuting: .getInfo)
                operation.finish()
            }
            if let storage = operation.objectStorage {
                self.storageController.remove?(name: T.entityName, new: storage)
            }
            self.delegate?.spider?(self, didFinishExecuting: .deleteInfo)
            operation.finish()
        }
        if let newDependency = operations.last {
            op.addDependency(newDependency)
        }
        operations.append(op)
        return self
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

    public func execute() {
        guard operations.count > 0 else { return }
        queue.addOperations(operations, waitUntilFinished: false)
        operations = [SpiderOperation]()
    }
}
