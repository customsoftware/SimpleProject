//
//  ClientModel.swift
//  SimpleProjects
//
//  Created by Kenneth Cluff on 3/14/19.
//  Copyright © 2019 Kenneth Cluff. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

struct ClientModel {
    // MARK: - Standard items
    static var owningZone: CKRecordZone? = Core.shared.cloud.customZone
    let recordType = "Client"
    let id: String
    var isLocalDeleted: Bool = false
    var isDirty: Bool = false
    var lastUpdated: Date = Date()
    var recordName: String
    var changeTag: String = ""
    var updatedBy: CKRecord.ID? = Core.shared.cloud.currentUserRecordID
    
    // MARK: - Object critical values
    var clientName: String
    var isActive: Bool = false
    
    init(_ name: String, _ newID: String = Core.getIDString() ) {
        clientName = name
        id = newID
        recordName = id
        
    }
    
    mutating func editName(_ newName: String) {
        clientName = newName
        lastUpdated = Date()
        isDirty = true
    }
    
    mutating func setActive(_ isActive: Bool) {
        self.isActive = isActive
        lastUpdated = Date()
        isDirty = true
    }
}

extension ClientModel: CloudKitObject {
    static func initFrom(_ record: CKRecord) -> CloudKitObject? {
        guard let recordName = record[.recordName] as? String,
            let clientName = record[.clientName] as? String else { return nil }
        
        var retValue = ClientModel(clientName, recordName)
        retValue.setCloudMetaTags(record)
        return retValue
    }
    
    mutating func updateFromCloud(_ record: CKRecord) {
        setCloudMetaTags(record)
        guard let clientName = record[.clientName] as? String else { return }
        editName(clientName)
    }
    
    func managedObjectRepresentation() -> NSManagedObject {
        let retValue = Client(context: Core.shared.data.viewContext)
        retValue.name = clientName
        retValue.id = id
        retValue.isLocalDeleted = isLocalDeleted
        return retValue
    }
}

extension ClientModel: CoreDataObject {
    func ckRecordRepresentation() -> CKRecord {
        let retValue = CKRecord(recordType: recordType, recordID: cloudKitRecordID)
        retValue[.clientName] = clientName
        return retValue
    }
    
    static func initFromStore(_ record: NSManagedObject) -> ModelObject? {
        guard let clientObject = record as? Client,
            let clientName = clientObject.name,
            let clientID = clientObject.id else { return nil }
        let retValue = ClientModel(clientName, clientID)
        
        return retValue
    }
    
    mutating func updateFromStore(_ record: NSManagedObject) {
        guard let client = record as? Client,
            let clientName = client.name else { return }
        editName(clientName)
    }
}

fileprivate enum ClientKeys: String {
    case recordName
    case lastUpdated
    case changeTag
    case clientName
}

fileprivate extension CKRecord {
    subscript(key: ClientKeys) -> Any? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue as? CKRecordValue
        }
    }
}
