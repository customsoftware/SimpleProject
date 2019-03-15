//
//  CloudKitManager.swift
//  SimpleProjects
//
//  Created by Kenneth Cluff on 3/14/19.
//  Copyright © 2019 Kenneth Cluff. All rights reserved.
//

import UIKit
import CloudKit
import os

class CloudKitManager: NSObject {
    static let isLocal = false
    let container = CKContainer.default()
    
    private var showingTemporaryAlert = false
    private(set) var currentUserRecordID: CKRecord.ID?
    private(set) lazy var privateDatabase = container.privateCloudDatabase
    private(set) lazy var publicDatabase = container.publicCloudDatabase
    private(set) lazy var sharedDatabase = container.sharedCloudDatabase
    private(set) lazy var customZone: CKRecordZone? = self.checkForCustomZone()
    
    private(set) var serialQueue = OperationQueue()
    var accountStatus: CKAccountStatus? {
        didSet {
            var aStatus: CKAccountStatus = CKAccountStatus.couldNotDetermine
            if let status = accountStatus {
                aStatus = status
            }
//            _ = cloudDelegates.compactMap({ $0?.handleUpdatedStatus(aStatus) })
        }
    }
    
    override init() {
        super.init()
        serialQueue.maxConcurrentOperationCount = 1
        serialQueue.name = "serialQueue"
        getUserID()
        configureForCloudKitAccess()
    }
}

// MARK: - These are inherited methods
extension CloudKitManager: CloudKitCapable {
    func setUserID(_ userID: CKRecord.ID) {
        guard let _ = currentUserRecordID else {
            currentUserRecordID = userID
            return
        }
        os_log(OSLogType.error, "%{public}@", "Once the user ID is set, you can't update it without exiting the app.")
    }

    func checkForCustomZone() -> CKRecordZone? {
        fatalError("checkforCustomZone must be overwritten")
    }
    func setupZones() {
        fatalError("setupZones must be overwritten")
    }
    func showConnectionError(_ error: String) {
        fatalError("showConnectionError must be overwritten")
    }
    func throwServerErrorAlert(with entity: String, and operationType: OperationType) {
        if !showingTemporaryAlert {
            showingTemporaryAlert = true
            let resultString = "A record for \(entity) couldn't be \(operationType.rawValue). Please try again later."
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Server Error", message: resultString, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                    self.showingTemporaryAlert = false
                })
                alert.addAction(okAction)
                alert.display()
            }
        }
    }
}
    
extension CloudKitManager: PersistentStore {
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
