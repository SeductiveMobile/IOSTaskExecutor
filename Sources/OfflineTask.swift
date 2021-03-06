//
//  OfflineTask.swift
//  HiveOnline
//
//  Created by Malkevych Bohdan on 21.11.17.
//  Copyright © 2017 Seductive. All rights reserved.
//

import Foundation


public class OfflineTask: NSObject, OfflineTaskProtocol {
    private(set) public var identifier: String
    private(set) public var status: OfflineTaskStatus
    private(set) public var executeOptions: [TaskExecuteOption]
    private(set) public var maxAttemptsExecuteTask: Int
    private(set) public var executedCount: Int
    public let type: String?
    public let object: NSCoding
    
    public init(type: String? = nil, status: OfflineTaskStatus = .new, object: NSCoding,
                executeOptions: [TaskExecuteOption] = [], maxAttemptsExecuteTask: Int = 0) {
        self.identifier = UUID().uuidString
        self.executedCount = 0
        self.type = type
        self.status = status
        self.object = object
        self.executeOptions = executeOptions
        self.maxAttemptsExecuteTask = maxAttemptsExecuteTask
    }
    
    public func incrementExecuteCount() {
        executedCount += 1
    }
    
    //MARK: - NSCoding
    
    private enum CodingKeys: String {
        case identifier, type, status, object, executeOptions, maxAttemptsExecuteTask, executedCount
    }
    
    required public convenience init?(coder decoder: NSCoder) {
        let type = decoder.decodeObject(forKey: CodingKeys.type.rawValue) as? String
        let maxAttemptsExecuteTask = decoder.decodeInteger(forKey: CodingKeys.maxAttemptsExecuteTask.rawValue)
        let executedCount = decoder.decodeInteger(forKey: CodingKeys.executedCount.rawValue)
        
        guard
            let identifier = decoder.decodeObject(forKey: CodingKeys.identifier.rawValue) as? String,
            let rawObject = decoder.decodeObject(forKey: CodingKeys.object.rawValue) as? Data,
            let object = NSKeyedUnarchiver.unarchiveObject(with: rawObject) as? NSCoding,
            let executeOptions = decoder.decodeObject(forKey: CodingKeys.executeOptions.rawValue) as? [TaskExecuteOption]
        else {
            return nil
        }

        self.init(type: type, status: .restored,
                  object: object, executeOptions: executeOptions,
                  maxAttemptsExecuteTask: maxAttemptsExecuteTask)
        self.identifier = identifier
        self.executedCount = executedCount
    }
    
    public func encode(with aCoder: NSCoder) {
        let rawObject = NSKeyedArchiver.archivedData(withRootObject: object)

        aCoder.encode(identifier, forKey: CodingKeys.identifier.rawValue)
        aCoder.encode(type, forKey: CodingKeys.type.rawValue)
        aCoder.encode(rawObject, forKey: CodingKeys.object.rawValue)
        aCoder.encode(executeOptions, forKey: CodingKeys.executeOptions.rawValue)
        aCoder.encode(maxAttemptsExecuteTask, forKey: CodingKeys.maxAttemptsExecuteTask.rawValue)
        aCoder.encode(executedCount, forKey: CodingKeys.executedCount.rawValue)
    }
}

