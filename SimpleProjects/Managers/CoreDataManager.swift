//
//  CoreDataManager.swift
//  SimpleProjects
//
//  Created by Kenneth Cluff on 3/14/19.
//  Copyright © 2019 Kenneth Cluff. All rights reserved.
//

import Foundation
import CoreData
import os

enum CoreDataErrors: Error {
    case otherError
}

class CoreDataManager {
    static let isLocal = true
    static let coreDataErrorDomain = "com.customsoftware.simpleprojects.coredata"
    
    let containerName: String
    let container: NSPersistentContainer
    
    lazy var viewContext: NSManagedObjectContext = {
        return container.viewContext
    }()
    
    lazy var cacheContext: NSManagedObjectContext = {
        return container.newBackgroundContext()
    }()
    
    init(_ containerName: String) {
        self.containerName = containerName
        self.container = NSPersistentContainer(name: containerName)
        self.loadContainer()
    }
    
    private func loadContainer() {
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            let failureReason = "The container failed to update."
            if let error = error as NSError? {
                var dict = [String: AnyObject]()
                dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
                dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
                
//                dict[NSUnderlyingErrorKey] = error as NSError
//                let wrappedError = NSError(domain: coreDataErrorDomain, code: 9999, userInfo: dict)
//                Crashlytics.sharedInstance().recordError(wrappedError)
//                Crashlytics.sharedInstance().recordError(error)
//
                switch error {
                default:
                    os_log(OSLogType.error, "%{public}@", error.localizedDescription)
                    fatalError("There was a problem: \(failureReason). \(error.localizedDescription)")
                }
            }
        })
    }
}

extension CoreDataManager: PersistentStore {
    func flushDeleted<T>(_ listOfObjects: [T]) { }
    
    func retrieveList<T>(_ predicate: NSPredicate) -> [T] {
        let retValue = [T]()
        return retValue
    }
    
    func save<T>(_ listOfModels: [T]) -> SaveResults {
        return .failed(error: CoreDataErrors.otherError)
    }
    
    func retrieveSingle<T>(_ objectID: UUID) -> T? {
        return nil
    }
}
