//
//  Constants.swift
//  SimpleProjects
//
//  Created by Ken Cluff on 3/15/19.
//  Copyright © 2019 Kenneth Cluff. All rights reserved.
//

import Foundation

struct SimpleProject {
    struct CloudKitMetaData {
        static let isSubscribedToDBChangesKey = NSLocalizedString("isSubscribedToDBChangesKey", comment: "")
    }
    
    static let metaDictionary: [String: Any] = {
        let dictionary = Bundle.main.infoDictionary
        return (dictionary!["CustomSoftwareMetaData"] as? [String: Any])!
    }()
}
