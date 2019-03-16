//
//  CloudKitProtocol.swift
//  SimpleProjects
//
//  Created by Kenneth Cluff on 3/15/19.
//  Copyright © 2019 Kenneth Cluff. All rights reserved.
//

import Foundation
import CloudKit
import os

protocol CloudKitCapable: AnyObject {
    var container: CKContainer { get }
    var privateDatabase: CKDatabase { get }
    var publicDatabase: CKDatabase { get }
    var sharedDatabase: CKDatabase { get }
    var currentUserRecordID: CKRecord.ID? { get }
    var serialQueue: OperationQueue { get }
    var accountStatus: CKAccountStatus? { get set }
    var isSubscriptionLocallyCached: Bool { get set }
    var changeTokens: [String: CKServerChangeToken] { get set }
    var cloudKitMeta: [String: Any] { get set }
    
    func getUserID()
    func setupZones()
    func checkForCustomZone() -> CKRecordZone?
    func setForCloudKit()
    func handleNotification(_ userInfo: [String: NSObject])
    func setMetaInformation()
    func restoreTokensAndState()
    func uploadChangedObjects(savedIDs: [ModelObject], deletedIDs: [CloudKitObject])
    func update(_ database: CKDatabase, with records: [CKRecord], whileRemoving deletedRecordIDs: [CKRecord.ID], with handler: @escaping CloudKitOperationHandler)
    func fetchRecords(for type: String)
    func throwServerErrorAlert(with entity: String, and operationType: OperationType)
    func throwAuthenticationRequestAlert()
    func showConnectionError(_ errorMessage: String)
    func setUserID(_ userID: CKRecord.ID)
    func configureForCloudKitAccess()
    func handleRemoteStatusChange(_ notification: NSNotification)
    func testForSubscriptions()
    func setupSubscriptions()
}

extension CloudKitCapable {
    func getUserID() {
        container.fetchUserRecordID { (userRecordID, error) in
            if let error = error {
                let errorHandlerResult = ErrorEngine.handleError(error)
                switch errorHandlerResult {
                case .setupZones:
                    self.setupZones()
                case .majorReset:
                    os_log(OSLogType.error, "%{public}@", error.localizedDescription)
                    fatalError("Kaboom!")
                    
                case .serverProblem:()
                self.throwServerErrorAlert(with: "User", and: .fetch)
                case .resolveConflict:
                    self.showConnectionError(error.localizedDescription)
                case .doNothing, .requestAuthentication, .handlePartial:()
                case .tryAgain:
                    let ckError = error as! CKError
                    guard let waitInterval = ckError.userInfo[CKErrorRetryAfterKey] as? Double else { return }
                    DispatchQueue.global().asyncAfter(deadline: .now() + waitInterval, execute: {
                        self.getUserID()
                    })
                case .errorString(let error):
                    self.showConnectionError(error)
                }
                
            } else if let userRecordID = userRecordID {
                self.setUserID(userRecordID)
            } else {
                _ = ErrorEngine.handleError(CloudKitError.noUser)
            }
        }
    }
    
    func configureForCloudKitAccess() {
        self.determineUserAccountStatus(for: container) { (status, error) in
            if let error = error {
                _ = ErrorEngine.handleError(error)
                self.accountStatus = .couldNotDetermine
            } else {
                self.accountStatus = status
            }
        }
    }
    
    func handleRemoteStatusChange(_ notification: NSNotification) {
        DispatchQueue.main.async { self.configureForCloudKitAccess() }
    }
    
    func handleAccountStatus(_ status: CKAccountStatus, with results: @escaping HandleCloudKitStatus) {
        switch status {
        case .available:
            results(status, nil)
        case .couldNotDetermine:
            container.accountStatus { (accountStatus, error) in
                results(accountStatus, error)
            }
        case .noAccount:
            results(status, CloudKitError.noAccount)
        case .restricted:
            results(status, CloudKitError.restricted)
        @unknown default:()
        }
    }
    
    func determineUserAccountStatus(for container: CKContainer, with results: @escaping HandleCloudKitStatus) {
        container.accountStatus { (status, error) in
            if let error = error {
                _ = ErrorEngine.handleError(error)
            } else {
                self.handleAccountStatus(status, with: results)
            }
        }
    }
    
    func testAccountStatus() -> Bool {
        let retValue = (accountStatus ?? .couldNotDetermine) == .available
        if !retValue {
            throwAuthenticationRequestAlert()
        }
        return retValue
    }
}
