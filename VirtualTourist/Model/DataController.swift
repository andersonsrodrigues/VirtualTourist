//
//  DataController.swift
//  VirtualTourist
//
//  Created by Anderson Rodrigues on 04/03/2020.
//  Copyright © 2020 Anderson Rodrigues. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
    
    /// associate viewContext variable with all context from persistent container
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    let backgroundContext: NSManagedObjectContext!
    
    /// Initialize the persistent container with the model name
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
        
        backgroundContext = persistentContainer.newBackgroundContext()
    }
    
    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    /// Load all persistence container stores
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            self.autoSaveViewContext()
            self.configureContexts()
            completion?()
        }
    }
}

// MARK: - Autosaving

extension DataController {
    func autoSaveViewContext(interval: TimeInterval = 30) {
        guard interval > 0 else {
            fatalError("cannot set negative autosave interval")
            return
        }
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
