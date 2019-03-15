//
//  Enums.swift
//  SimpleProjects
//
//  Created by Kenneth Cluff on 3/14/19.
//  Copyright © 2019 Kenneth Cluff. All rights reserved.
//

import Foundation
import CloudKit

enum SaveResults {
    case successful
    case failed(error: Error)
}

enum ShouldDo {
    case yes
    case no
}

//typealias genericCallback = _ callback: () -> Void
typealias HandleCloudKitQuery = ([CKRecord], Error?) -> Void
typealias HandleCloudKitStatus = (CKAccountStatus, Error?) -> Void
typealias HandleCloudKitRecordID = (CKRecord.ID, Error?) -> Void
typealias CloudKitOperationHandler = ([CKRecord]?, [CKRecord.ID]?, Error?) -> Void
typealias ActionHandler = (Any) -> (Void)

enum OperationType: String {
    case update = "updated"
    case delete = "deleted"
    case create = "created"
    case fetch = "fetched"
}

enum CloudKitError: Error {
    case noAccount
    case restricted
    case noUser
}

enum Entities: String, CaseIterable {
    case Client
}
