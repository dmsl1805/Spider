//  Operation.swift
//
//  Created by Dmitriy Shulzhenko on 9/2/16.
//  Copyright © 2016. All rights reserved.
//

//import UIKit

import Foundation

public typealias SpiderOperationExecutionBlock = (_ currentOperation: SpiderOperationProtocol) -> Void

public class SpiderOperation : Operation, SpiderOperationProtocol {
    
    public var dependents: [SpiderOperationProtocol]? = Array<SpiderOperationProtocol>()

    public var objectStorage: TempObjectStorageProtocol? {
        didSet {
            self.dependents?.forEach { op in
                op.objectStorage = objectStorage
            }
        }
    }
    
    public override func addDependency(_ op: Operation) {
        super.addDependency(op)
        var dependents = (op as? SpiderOperationProtocol)?.dependents
        dependents?.append(self)
        (op as? SpiderOperationProtocol)?.dependents = dependents
    }

    public var executionBlocks: [SpiderOperationExecutionBlock]
    
    open func addExecutionBlock(_ block: @escaping SpiderOperationExecutionBlock) {
        executionBlocks.append(block)
    }
    
    private var currentExecuting: Bool = false {
        willSet {  willChangeValue(forKey: "isExecuting") }
        didSet { didChangeValue(forKey: "isExecuting") }
    }
    override public var isExecuting: Bool {
        get { return currentExecuting }
        set {
            guard currentExecuting != newValue else { return }
            currentExecuting = newValue
        }
    }
    
    private var currentFinished: Bool = false {
        willSet { willChangeValue(forKey: "isFinished") }
        didSet { didChangeValue(forKey: "isFinished") }
    }
    override public var isFinished: Bool {
        get { return currentFinished }
        set {
            guard currentFinished != newValue else { return }
            currentFinished = newValue
        }
    }
    
    private var currentCancelled: Bool = false{
        willSet { willChangeValue(forKey: "isCancelled") }
        didSet { didChangeValue(forKey: "isCancelled") }
    }
    override public var isCancelled: Bool {
        get { return currentCancelled }
        set {
            guard currentCancelled != newValue else { return }
            currentCancelled = newValue
        }
    }
    
    private var isAsync: Bool = true
    override public var isAsynchronous: Bool { return isAsync }
    
    override public func start() {
        guard !isCancelled && !isFinished else { return }
        isExecuting = true
        isFinished = false
        for block in executionBlocks {
            block(self)
        }
    }
    
    public init(isAsync: Bool? = true, executionBlock: @escaping SpiderOperationExecutionBlock) {
        self.executionBlocks = [executionBlock]
        self.isAsync = isAsync!
    }
    
    public func finish() -> Void {
        currentExecuting = false
        currentFinished = true
    }
}
