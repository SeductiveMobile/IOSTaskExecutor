//
//  OfflineTaskProtocol.swift
//  HiveOnline
//
//  Created by Malkevych Bohdan on 21.11.17.
//  Copyright © 2017 Seductive. All rights reserved.
//

import Foundation

public enum OfflineTaskStatus: Int {
    case new = 0
    case restored
}

public typealias TaskExecuteOption = Int

public protocol OfflineTaskProtocol: NSObjectProtocol, NSCoding {
    var identifier: String { get }
    var type: String? { get }
    var status: OfflineTaskStatus { get }
    var executeOptions: [TaskExecuteOption] { get }
    
    var object: NSCoding { get }
    
    /* Implement in future */
    // var maxAttamptsExecuteTask: Int = 0 // 0 infinity
    // var replaceTasksWithSameType: Bool = false
    
}
