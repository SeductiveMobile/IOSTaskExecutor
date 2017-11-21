//
//  Test.swift
//  OfflineTaskQueue
//
//  Created by Malkevych Bohdan on 16.11.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import UIKit


public class OfflineTaskQueue {
    fileprivate let UserDefaultsKey = "4ier.labs.OfflineTask.UserDefaultsKey"
    fileprivate let queue = DispatchQueue(label: "4ier.labs.OfflineTask", attributes: .concurrent)
    fileprivate var tasksQueue: [OfflineTaskProtocol] = [] { didSet { saveTasksQueue() } }
    fileprivate var observers: [OfflineTaskProtocolObserver] = []
    
    //MARK: - Weak Singltone
    
    private static weak var weakInstance: OfflineTaskQueue?
    
    static var manager: OfflineTaskQueue {
        get {
            if let instance = weakInstance {
                return instance
            } else {
                let newInstance = OfflineTaskQueue()
                weakInstance = newInstance
                return newInstance
            }
        }
    }
    
    private init() {
        recoverSavedQueue()
    }
    
    //MARK: - Mutating
    
    func addObserver(_ observer: OfflineTaskProtocolObserver) {
        queue.async(flags: .barrier) {
            self.observers.append(observer)
            let tasksToExecute = self.tasksFor(executeOptions: observer.executeOptions)
            guard !tasksToExecute.isEmpty else { return }
            self.notifyObservers([observer], aboutTasks: tasksToExecute)
        }
    }
    
    func finishTask(_ task: OfflineTaskProtocol) {
        queue.async(flags: .barrier) {
            guard let index = self.tasksQueue.index(where: { $0.identifier == task.identifier }) else {
                print("Can't find task with \(task.identifier) identifier")
                return
            }
            self.tasksQueue.remove(at: index)
        }
    }
    
    func addTask(_ task: OfflineTaskProtocol) {
        queue.async(flags: .barrier) {
            self.tasksQueue.append(task)
            let observersToNotify = self.observersFor(executeOptions: task.executeOptions)
            self.notifyObservers(observersToNotify, aboutTasks: [task])
        }
    }
    
    //MARK: - Accessors
    
    var countActiveTasks: Int {
        var count: Int = 0
        queue.sync { count = self.tasksQueue.count }
        return count
    }
    
    var activeTasks: [OfflineTaskProtocol] {
        var tasks: [OfflineTaskProtocol] = []
        queue.sync { tasks = self.tasksQueue }
        return tasks
    }
}

fileprivate extension OfflineTaskQueue {
    func saveTasksQueue() {
        let rawObject = NSKeyedArchiver.archivedData(withRootObject: tasksQueue)
        UserDefaults.standard.set(rawObject, forKey: UserDefaultsKey)
        UserDefaults.standard.synchronize()
        print("Tasks saved: \(tasksQueue.count)")
    }
    
    func recoverSavedQueue() {
        if let data = UserDefaults.standard.value(forKey: UserDefaultsKey) as? Data,
            let tasksQueue = NSKeyedUnarchiver.unarchiveObject(with: data) as? [OfflineTaskProtocol] {
            print("Tasks recovered: \(tasksQueue.count)")
            self.tasksQueue = tasksQueue
        }
    }
}

//MARK: - Private

fileprivate extension OfflineTaskQueue {
    func notifyObservers(_ observers: [OfflineTaskProtocolObserver], aboutTasks: [OfflineTaskProtocol]) {
        observers.forEach { $0.taskQueue(self, updatedTasks: aboutTasks) }
    }
    
    func observersFor(executeOptions: [TaskExecuteOption]) -> [OfflineTaskProtocolObserver] {
        return observers.filter { $0.executeOptions.filter(executeOptions.contains).count > 0 }
    }
    
    func tasksFor(executeOptions: [TaskExecuteOption]) -> [OfflineTaskProtocol] {
        return tasksQueue.filter { $0.executeOptions.filter(executeOptions.contains).count > 0 }
    }
}
