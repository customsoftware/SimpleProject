//
//  Core.swift
//  SimpleProjects
//
//  Created by Kenneth Cluff on 3/14/19.
//  Copyright © 2019 Kenneth Cluff. All rights reserved.
//

import Foundation
import os

class Core {
    static let shared = Core()
    
    lazy var isWatch: Bool = {
        var retValue = false
        
        if #available(watchOS 3, *) {
            retValue = true
        }
        
        return retValue
    }()
    
    lazy var cloudKitIsAvailable: Bool = {
        return true
    }()
    
    let cloud: CloudKitManager
    let data: CoreDataManager
    
    init() {
        cloud = CloudKitManager()
        
        if let dictionary = Bundle.main.infoDictionary,
            let cloudKitMeta = dictionary["CustomSoftwareMetaData"] as? [String: Any],
            let containerName = cloudKitMeta["PersistentContainerName"] as? String {
            data = CoreDataManager(containerName)
        } else {
            data = CoreDataManager("CustomSoftware")
        }
        
        _ = cloud.accountStatus
    }
    
    static func getIDString() -> String {
        return UUID().uuidString
    }
}
