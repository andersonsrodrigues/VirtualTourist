//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Anderson Rodrigues on 02/03/2020.
//  Copyright © 2020 Anderson Rodrigues. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    // Initialize the DataController
    let dataController = DataController(modelName: "VirtualTourist")

    // MARK: Functions
    
    func checkIfFirstLaunch() {
        if !UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            UserDefaults.standard.set(-54.49218800000003, forKey: "centerLongitude")
            UserDefaults.standard.set(-14.366880000000037, forKey: "centerLatitude")
            UserDefaults.standard.set(66.19203694805657, forKey: "zoomLatitude")
            UserDefaults.standard.set(40.60546900000003, forKey: "zoomLongitude")
            UserDefaults.standard.synchronize()
        }
    }
    
    // MARK: UIApplicationDelegate
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Usually this is not overridden. Using the "did finish launching" method is more typical
        checkIfFirstLaunch()

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        dataController.load()
        
        let navigationController = window?.rootViewController as! UINavigationController
        let travelLocationsMapViewController = navigationController.topViewController as! TravelLocationsMapViewController
        travelLocationsMapViewController.dataController = dataController
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        saveContext()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        saveContext()
    }

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = dataController.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

