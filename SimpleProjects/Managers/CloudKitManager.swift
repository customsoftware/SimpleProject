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
    let cloudLog = OSLog(subsystem: "com.customsoftware.simpleproject.plist", category: "cloudkit")
    static let isLocal = false
    let container = CKContainer.default()
    
    private var showingiCloudAuthenticationAlert = false
    private var showingTemporaryAlert = false
    private(set) var currentUserRecordID: CKRecord.ID?
    private(set) lazy var privateDatabase = container.privateCloudDatabase
    private(set) lazy var publicDatabase = container.publicCloudDatabase
    private(set) lazy var sharedDatabase = container.sharedCloudDatabase
    private(set) lazy var customZone: CKRecordZone? = self.checkForCustomZone()
    var changeTokens = [String: CKServerChangeToken]()
    var cloudKitMeta = [String: Any]()
    var isSubscriptionLocallyCached = false {
        didSet {
            UserDefaults.standard.set(isSubscriptionLocallyCached, forKey: SimpleProject.CloudKitMetaData.isSubscribedToDBChangesKey)
        }
    }
    
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
    func setForCloudKit() {
        let initialLoadDone = UserDefaults.standard.bool(forKey: "InitialCloudKitLoad")
        guard !initialLoadDone else { return }
        // This is used for a one-time load of local data into the cloud. Not needed???
        UserDefaults.standard.set(true, forKey: "InitialCloudKitLoad")
    }
    
    func handleNotification(_ userInfo: [String : NSObject]) {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) // Here
        guard let subscriptionID = notification.subscriptionID,
            let _ = SimpleProjectSubscriptionIDs(rawValue: subscriptionID) else { return }
        os_log(OSLogType.default, log: cloudLog, "Cloud update received")
        
        // TODO: Here we need to fetch all the updated records from the server...
    }
    
    func setMetaInformation() {
        cloudKitMeta = SimpleProject.metaDictionary
    }
    
    func restoreTokensAndState() {
//        isSubscriptionLocallyCached = UserDefaults.standard.bool(forKey: SimpleProject.CloudKitMetaData.CloudKitTokenKeys.isSubscribedToDBChangesKey)
//        if let journalToken = UserDefaults.standard.retrieveToken(for: ReflectionsConstants.CloudKitMetaData.CloudKitTokenKeys.journalChangeTokenKey) {
//            journalChangeToken = journalToken
//        }
//        if let entryToken = UserDefaults.standard.retrieveToken(for: ReflectionsConstants.CloudKitMetaData.CloudKitTokenKeys.entryChangeTokenKey) {
//            entryChangeToken = entryToken
//        }
//        if let journalZoneToken = UserDefaults.standard.retrieveToken(for: ReflectionsConstants.CloudKitMetaData.CloudKitTokenKeys.journalZoneChangeTokenKey) {
//            journalZoneChangeToken = journalZoneToken
//        }
//        if let entryZoneToken = UserDefaults.standard.retrieveToken(for: ReflectionsConstants.CloudKitMetaData.CloudKitTokenKeys.entryZoneChangeTokenKey) {
//            entryZoneChangeToken = entryZoneToken
//        }
    }
    
    func uploadChangedObjects(savedIDs: [ModelObject], deletedIDs: [CloudKitObject]) {
        
    }
    
    func update(_ database: CKDatabase, with records: [CKRecord], whileRemoving deletedRecordIDs: [CKRecord.ID], with handler: @escaping CloudKitOperationHandler) {
        
    }
    
    func fetchRecords(for type: String) {
        // Fetch the zone change ID's
        // Fetch the records in each of the updated zones
    }
    
    func throwAuthenticationRequestAlert() {
        if !showingiCloudAuthenticationAlert {
            showingiCloudAuthenticationAlert = true
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Sign into iCloud", message: "Sign into iCloud to share your saved journal entries on other devices. Tap 'Settings.' Then sign into iCloud using your Apple ID. Enable iCloud Drive once you are logged in.\nIf you don't have an iCloud account, tap 'Create a new Apple ID'.", preferredStyle: .alert)
                let goToSettings = UIAlertAction(title: "Go to Settings", style: .default) { (action) in
                    let settingsUrl = URL(string: UIApplication.openSettingsURLString)
                    if let url = settingsUrl {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                    self.showingiCloudAuthenticationAlert = false
                }
                let dontRemindMe = UIAlertAction(title: "Don't remind me", style: .destructive, handler: { (action) in
                    UserDefaults.standard.set(true, forKey: "noLogonAlertKey")
                    UserDefaults.standard.synchronize()
                    self.showingiCloudAuthenticationAlert = false
                })
                let canxAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    self.showingiCloudAuthenticationAlert = false
                })
                alert.addAction(goToSettings)
                alert.addAction(dontRemindMe)
                alert.addAction(canxAction)
                alert.display()
            }
        }
    }
    
    func testForSubscriptions() {
        privateDatabase.fetchAllSubscriptions { (subscriptions, error) in
            if let error = error {
                let result = ErrorEngine.handleError(error)
                switch result {
                default:()
                }
            } else {
                if subscriptions?.count == 0 {
                    self.setupSubscriptions()
                }
            }
        }
    }
    
    func setupSubscriptions() {
        guard !isSubscriptionLocallyCached,
            let subscriptionKeys = cloudKitMeta["SubscriptionKeys"] as? [String] else { return }
        
        var subscriptionList = [CKDatabaseSubscription]()
        subscriptionKeys.forEach({ subscriptionList.append(buildDatabaseSubscription(with: $0)) })
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptionList, subscriptionIDsToDelete: nil)
        
        operation.modifySubscriptionsCompletionBlock = { (_, _, error) in
            if let error = error {
                let errorHandlerResult = ErrorEngine.handleError(error)
                switch errorHandlerResult {
                case .majorReset:
                    os_log(OSLogType.error, "%{public}@", error.localizedDescription)
                    fatalError("Kaboom!")
                case .serverProblem:
                    self.throwServerErrorAlert(with: "Subscriptions", and: .create)
                case .resolveConflict:
                    os_log(OSLogType.error, "%{public}@", error.localizedDescription)
                    fatalError("How did this happen?: CKRecordChangedErrorServerRecordKey")
                case .tryAgain:
                    let ckError = error as! CKError
                    let waitInterval = ckError.userInfo[CKErrorRetryAfterKey] as! TimeInterval
                    DispatchQueue.global().asyncAfter(deadline: .now() + waitInterval, execute: {
                        self.setupSubscriptions()
                    })
                case .setupZones, .doNothing, .requestAuthentication, .handlePartial, .errorString(_):()
                }
            } else {
                self.isSubscriptionLocallyCached = true
            }
        }
        
        operation.qualityOfService = .utility
        privateDatabase.add(operation)
    }
    
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
    func showConnectionError(_ errorMessage: String) {
        let alert = UIAlertController(title: "CloudKit Error", message: errorMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.display()
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

fileprivate extension CloudKitManager {
    func buildDatabaseSubscription(with subscriptionID: String) -> CKDatabaseSubscription {
        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        return subscription
    }
}
    
extension CloudKitManager: PersistentStore {
    func resetAll() { }
    
    func flushDeleted<T>(_ listOfObjects: [T]) { }
    
    func retrieveList<T>(_ predicate: NSPredicate) -> [T] {
        let retValue = [T]()
        return retValue
    }
    
    func save<T>(_ listOfModels: [T]) -> SaveResults {
        return .failed(error: CoreDataErrors.otherError)
    }
    
    func retrieveSingle<T>(_ objectID: String) -> T? {
        return nil
    }
}
