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
    fileprivate let queue = DispatchQueue(label: "4ier.labs.OfflineTask")
    fileprivate var tasksQueue: [OfflineTaskProtocol] = [] { didSet { saveTasksQueue() } }
    fileprivate var observers: [OfflineTaskProtocolObserver] = []
    
    //MARK: - Weak Singltone
    
    private static weak var weakInstance: OfflineTaskQueue?
    
    public static var manager: OfflineTaskQueue {
        get {
            let instance = weakInstance ?? OfflineTaskQueue()
            weakInstance = instance
            return instance
        }
    }
    
    private init() {
        recoverSavedQueue()
    }
    
    //MARK: - Mutating
    
    public func addObserver(_ observer: OfflineTaskProtocolObserver) {
        queue.async(flags: .barrier) {
            self.observers.append(observer)
            let tasksToExecute = self.tasksFor(executeOptions: observer.executeOptions)
            guard !tasksToExecute.isEmpty else { return }
            self.notifyObservers([observer], aboutTasks: tasksToExecute)
            self.saveTasksQueue()
        }
    }
    
    public func finishTask(_ task: OfflineTaskProtocol) {
        queue.async(flags: .barrier) {
            guard let index = self.tasksQueue.index(where: { $0.identifier == task.identifier }) else {
                print("Can't find task with \(task.identifier) identifier")
                return
            }
            self.tasksQueue.remove(at: index)
        }
    }
    
    public func addTask(_ task: OfflineTaskProtocol) {
        queue.async(flags: .barrier) {
            let observersToNotify = self.observersFor(executeOptions: task.executeOptions)
            self.notifyObservers(observersToNotify, aboutTasks: [task])
            if !(observersToNotify.count != 0 && task.maxAttemptsExecuteTask == 1) {
                self.tasksQueue.append(task)
            }
        }
    }
    
    //MARK: - Accessors
    
    public var countActiveTasks: Int {
        return activeTasks.count
    }
    
    public var activeTasks: [OfflineTaskProtocol] {
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
            self.tasksQueue = removeExpiredTasksFrom(tasks: tasksQueue)
            print("Tasks recovered after removing expired: \(self.tasksQueue.count)")
        }
    }
}

//MARK: - Private

fileprivate extension OfflineTaskQueue {
    func notifyObservers(_ observers: [OfflineTaskProtocolObserver], aboutTasks: [OfflineTaskProtocol]) {
        DispatchQueue.main.async {
            observers.forEach {
                $0.taskQueue(self, updatedTasks: aboutTasks)
                self.incrementExecuteCountFor(tasks: aboutTasks)
            }
        }
    }
    
    func observersFor(executeOptions: [TaskExecuteOption]) -> [OfflineTaskProtocolObserver] {
        return observers.filter { $0.executeOptions.filter(executeOptions.contains).count > 0 }
    }

    func tasksFor(executeOptions: [TaskExecuteOption]) -> [OfflineTaskProtocol] {
        return tasksQueue.filter { $0.executeOptions.filter(executeOptions.contains).count > 0 }
    }
    
    func incrementExecuteCountFor(tasks: [OfflineTaskProtocol]) {
        tasks.forEach { $0.incrementExecuteCount() }
    }
    
    func removeExpiredTasksFrom(tasks: [OfflineTaskProtocol]) -> [OfflineTaskProtocol] {
        return tasks.filter { $0.executedCount != $0.maxAttemptsExecuteTask }
    }
}

