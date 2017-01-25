
//  Created by Dmitriy Shulzhenko on 9/5/16.
//  Copyright © 2016 . All rights reserved.
//

import Foundation


public class Spider: NSObject, SpiderProtocol {
    
    public var delegateQueue: DispatchQueue
    public var networkController: NetworkControllerProtocol
    public var storageController: PersistentStorageControllerProtocol
    public var request: URLRequest?
    public var entityName: Any!
    public weak var delegate: SpiderDelegateProtocol?
    
    //You can modify "operations" before calling "execute".
    //But be aware - "operations" will be removed after "execute" was called
    public typealias SpiderOperationBlock = (_ dispatchGroup: DispatchGroup) -> (Void)

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
        
        guard request != nil || self.request != nil else { return self }
        
        operations.append{ [unowned self] group in
            group.wait()
            group.enter()
            
            let task = self.networkController.executeRequest(request ?? self.request!, response: { resp, error in
                self.delegateQueue.sync {
                    self.delegate?.spider?(self, didGet: resp, error: error)
                }
//                operation.objectStorage = resp
                self.delegateQueue.sync {
                    self.delegate?.spider?(self, didFinishExecuting: .getInfo)
                }
                group.leave()
            })
            self.delegateQueue.sync {
                self.delegate?.spider?(self, didExecute: task)
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

//    public func execute(forEntity entityName: Any) {
//        guard operations.count > 0 else { return }
//        self.entityName = entityName
//        self.executionQueue.addOperations(operations, waitUntilFinished: false)
//        operations = [SpiderOperation]()
//    }
}
