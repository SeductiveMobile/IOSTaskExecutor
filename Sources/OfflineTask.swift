//
//  OfflineTask.swift
//  HiveOnline
//
//  Created by Malkevych Bohdan on 21.11.17.
//  Copyright © 2017 Seductive. All rights reserved.
//

import Foundation


class OfflineTask: NSObject, OfflineTaskProtocol {
    private(set) var identifier: String
    private(set) var status: OfflineTaskStatus
    private(set) var executeOptions: [TaskExecuteOption] = []
    let type: String?
    
    let object: NSCoding
    
    init(type: String? = nil, status: OfflineTaskStatus = .new, object: NSCoding, executeOptions: [TaskExecuteOption] = []) {
        self.identifier = UUID().uuidString
        self.type = type
        self.status = status
        self.object = object
    }
    
    //MARK: - NSCoding
    
    enum CodingKeys: String {
        case identifier, type, status, object, executeOptions
    }
    
    required convenience init?(coder decoder: NSCoder) {
        let type = decoder.decodeObject(forKey: CodingKeys.type.rawValue) as? String
        
        guard let identifier = decoder.decodeObject(forKey: CodingKeys.identifier.rawValue) as? String,
            let rawObject = decoder.decodeObject(forKey: CodingKeys.object.rawValue) as? Data,
            let object = NSKeyedUnarchiver.unarchiveObject(with: rawObject) as? NSCoding,
            let executeOptions = decoder.decodeObject(forKey: CodingKeys.executeOptions.rawValue) as? [TaskExecuteOption]
        else {
            return nil
        }
        
        self.init(type: type, status: .restored, object: object, executeOptions: executeOptions)
        self.identifier = identifier
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(identifier, forKey: CodingKeys.identifier.rawValue)
        aCoder.encode(type, forKey: CodingKeys.type.rawValue)
        let rawObject = NSKeyedArchiver.archivedData(withRootObject: object)
        aCoder.encode(rawObject, forKey: CodingKeys.object.rawValue)
        aCoder.encode(executeOptions, forKey: CodingKeys.executeOptions.rawValue)
    }
}

