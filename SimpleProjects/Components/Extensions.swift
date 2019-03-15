//
//  Extensions.swift
//  SimpleProjects
//
//  Created by Kenneth Cluff on 3/14/19.
//  Copyright © 2019 Kenneth Cluff. All rights reserved.
//

import UIKit
import os

extension UIAlertController {
    func display() {
        guard let vc = getViewController() else {
            let errorString = String(format: "No way to present error: %@", message ?? "Presenting alert failed for now window. There is a deeper error." )
            os_log(OSLogType.debug, "%{public}@", errorString)
            return
        }
        
        vc.present(self, animated: true, completion: nil)
    }
    
    private func getViewController() -> UIViewController? {
        return UIApplication.shared.topMostViewController()
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        return self.keyWindow?.rootViewController?.topMostViewController()
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        guard presentedViewController != nil else { return self }
        
        switch presentedViewController {
        case let navigation as UINavigationController:
            return navigation.visibleViewController!.topMostViewController()
        case let tab as UITabBarController:
            guard let selectedTab = tab.selectedViewController else {
                return tab.topMostViewController()
            }
            return selectedTab.topMostViewController()
        default:
            return presentedViewController!.topMostViewController()
        }
    }
    
    func askAreYouSure(_ actionToPeform: String?, _ handleIfYes: @escaping ActionHandler, _ handleIfNo: ActionHandler?) {
        let alert = UIAlertController(title: "Are You Sure", message: actionToPeform, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { (action) in
            handleIfYes(action)
        }
        let noAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            if let handleIfNo = handleIfNo {
                handleIfNo(action)
            }
        }
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true, completion: nil)
    }
}

