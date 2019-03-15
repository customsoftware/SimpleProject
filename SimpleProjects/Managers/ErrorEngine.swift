//
//  ErrorEngine.swift
//  SimpleProjects
//
//  Created by Kenneth Cluff on 3/15/19.
//  Copyright © 2019 Kenneth Cluff. All rights reserved.
//

import Foundation
import CloudKit
import os

enum ServerErrorAction: CaseIterable {
    typealias AllCases = [ServerErrorAction]
    
    static var allCases: [ServerErrorAction] {
        return [.tryAgain,
                .doNothing,
                .resolveConflict,
                .serverProblem("Server Problem"),
                .requestAuthentication,
                .handlePartial,
                .errorString("Error String"),
                .majorReset]
    }
    
    @available(*, unavailable, message: "Only for exhaustiveness checking, don't call")
    func _assertExhaustiveness(of actions: ServerErrorAction, never: Never) {
        switch actions {
        case .tryAgain,
             .doNothing,
             .resolveConflict,
             .serverProblem,
             .requestAuthentication,
             .handlePartial,
             .errorString(_),
             .setupZones,
             .majorReset:
            break
        }
    }
    
    case tryAgain
    case doNothing
    case resolveConflict
    case serverProblem(String)
    case requestAuthentication
    case handlePartial
    case errorString(String)
    case majorReset
    case setupZones
}

class ErrorEngine: NSObject {
    static let errorLog = OSLog(subsystem: "com.customsoftware.reflections.plist", category: "errors")
    
    static func handleError(_ error: Error) -> ServerErrorAction {
        var tellTheUser = ServerErrorAction.doNothing
        if let cloudError = error as? CKError {
            
            os_log(OSLogType.error, log: ErrorEngine.errorLog, "%{public}@", cloudError.localizedDescription)
            
            switch cloudError.code {
            case .internalError, .serverRejectedRequest, .invalidArguments, .permissionFailure:
                tellTheUser = .serverProblem(cloudError.localizedDescription)
                
            case .changeTokenExpired:
                tellTheUser = .majorReset
                
            case .zoneBusy, .serviceUnavailable, .requestRateLimited:
                tellTheUser = .tryAgain
                
            case .serverRecordChanged:
                tellTheUser = .resolveConflict
                
            case .unknownItem:
                tellTheUser = .tryAgain
                
            case .notAuthenticated:
                tellTheUser = .requestAuthentication
                
            case .zoneNotFound:
                tellTheUser = .setupZones
                
            default:
                tellTheUser = .errorString(cloudError.localizedDescription)
            }
        } else {
            os_log(OSLogType.error, log: ErrorEngine.errorLog, "%{public}@", error.localizedDescription)
        }
        return tellTheUser
    }
}
