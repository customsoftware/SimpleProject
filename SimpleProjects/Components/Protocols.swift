//
//  Protocols.swift
//  SimpleProjects
//
//  Created by Kenneth Cluff on 3/14/19.
//  Copyright © 2019 Kenneth Cluff. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

protocol CloudStatusUpdate {
    func handleUpdatedStatus(_ status: CKAccountStatus)
}

protocol PersistentStore: AnyObject {
    static var isLocal: Bool { get }
    func save(_ listOfModels: [ModelObject]) -> SaveResults
    func flushDeleted(_ listOfObjects: [ModelObject])
    func retrieveSingle(_ objectID: String) -> ModelObject?
    func retrieveList(_ predicate: NSPredicate) -> [ModelObject]
    func resetAll()
}

protocol Synchronizer {
    static var remoteStore: PersistentStore { get }
    static var localStore: PersistentStore { get }
    // This is the code that synchronizes a local store with a remote store
    func merge(local: [ModelObject], with remote: [ModelObject]) -> SaveResults
    func removeDeleted(_ objectList: [ModelObject])
    func saveNew(local: [ModelObject], to remoteStore: PersistentStore)
    func shouldSync(remote: ModelObject, into local: ModelObject) -> ShouldDo
}

protocol ModelObject {
    var id: String { get }
    var isLocalDeleted: Bool { get set }
    var lastUpdated: Date { get set }
    var isDirty: Bool { get set }
    
    mutating func markDeleted()
    mutating func clean()
}

extension ModelObject {
    mutating func clean() {
        isDirty = false
    }
    
    mutating func markDeleted() {
        isLocalDeleted = true
        isDirty = true
        lastUpdated = Date()
    }
}

protocol CloudKitObject: ModelObject {
    var recordName: String { get set }
    var changeTag: String { get set }
    var recordType: String { get }
    var updatedBy: CKRecord.ID? { get set }
    static var owningZone: CKRecordZone? { get }
    
    static func initFrom(_ record: CKRecord) -> CloudKitObject?
    mutating func updateFromCloud(_ record: CKRecord)
    func ckRecordRepresentation() -> CKRecord
    mutating func setCloudMetaTags(_ record: CKRecord)
}

extension CloudKitObject {
    mutating func setCloudMetaTags(_ record: CKRecord) {
        guard let cloudChangeTag = record.recordChangeTag,
            let cloudLastUpdated = record.modificationDate,
            let updateMadeBy = record.lastModifiedUserRecordID else { return }
        let cloudName = record.recordID.recordName
        
        updatedBy = updateMadeBy
        changeTag = cloudChangeTag
        lastUpdated = cloudLastUpdated
        recordName = cloudName
    }

    var cloudKitRecordID: CKRecord.ID {
        let recordIDRoot = id
        let zone = Self.owningZone!.zoneID
        let recordID = CKRecord.ID.init(recordName: recordIDRoot, zoneID: zone)
        return recordID
    }
}

protocol CoreDataObject: ModelObject {
    static func initFromStore(_ record: NSManagedObject) -> ModelObject?
    mutating func updateFromStore(_ record: NSManagedObject)
    func managedObjectRepresentation() -> NSManagedObject
}
