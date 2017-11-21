//
//  OfflineTaskProtocolObserver.swift
//  HiveOnline
//
//  Created by Malkevych Bohdan on 21.11.17.
//  Copyright © 2017 Seductive. All rights reserved.
//

import Foundation

public protocol OfflineTaskProtocolObserver {
    var executeOptions: [TaskExecuteOption] { get }
    
    func taskQueue(_ queue: OfflineTaskQueue, updatedTasks tasks: [OfflineTaskProtocol])
}
