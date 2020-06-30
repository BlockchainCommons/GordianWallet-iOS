//
//  CoreDataService.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import CoreData

class CoreDataService {
            
    // MARK: - Core Data stack
    static var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "FullyNoded2")
        
        // get the store description
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Could not retrieve a persistent store description.")
        }
        
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.blockchaincommons.standupios.FullyNoded2")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    
    static var viewContext: NSManagedObjectContext {
        let viewContext = CoreDataService.persistentContainer.viewContext
        viewContext.automaticallyMergesChangesFromParent = true
        return viewContext
    }
        
    // MARK: - Core Data Saving support
    class func saveContext () {
        DispatchQueue.main.async {
            let context = CoreDataService.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
    
    class func deleteAllData(entity: ENTITY, completion: @escaping ((Bool)) -> Void) {
        let managedContext = CoreDataService.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.rawValue)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let stuff = try managedContext.fetch(fetchRequest)
            for thing in stuff as! [NSManagedObject] {
                managedContext.delete(thing)
            }
            try managedContext.save()
            completion(true)
        } catch {
            completion(false)
        }
    }
    
    class func saveEntity(dict: [String:Any], entityName: ENTITY, completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        DispatchQueue.main.async {
            let context = CoreDataService.viewContext
            guard let entity = NSEntityDescription.entity(forEntityName: entityName.rawValue, in: context) else {
                completion((false, "unable to access \(entityName.rawValue)"))
                return
            }
                    
            let credential = NSManagedObject(entity: entity, insertInto: context)
            var succ = Bool()
            for (key, value) in dict {
                credential.setValue(value, forKey: key)
                do {
                    try context.save()
                    succ = true
                    
                } catch {
                    succ = false
                    
                }
            }
            if succ {
                completion((true, nil))
                
            } else {
                completion((false, "error saving entity"))
                
            }
        }
    }
        
    class func retrieveEntity(entityName: ENTITY, completion: @escaping ((entity: [[String:Any]]?, errorDescription: String?)) -> Void) {
        DispatchQueue.main.async {
            let context = CoreDataService.viewContext
            var fetchRequest:NSFetchRequest<NSFetchRequestResult>? = NSFetchRequest<NSFetchRequestResult>(entityName: entityName.rawValue)
            fetchRequest?.returnsObjectsAsFaults = false
            fetchRequest?.resultType = .dictionaryResultType
            do {
                if fetchRequest != nil {
                    if let results = try context.fetch(fetchRequest!) as? [[String:Any]] {
                        fetchRequest = nil
                        completion((results, nil))
                    } else {
                        fetchRequest = nil
                        completion((nil, "error fetching entity"))
                    }
                }
            } catch {
                fetchRequest = nil
                completion((nil, "Error fetching \(entityName)"))
            }
        }
    }
    
    class func updateNode(nodeToUpdate: UUID, newCredentials: [String:Any], completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        DispatchQueue.main.async {
            let context = CoreDataService.viewContext
            var fetchRequest:NSFetchRequest<NSManagedObject>? = NSFetchRequest<NSManagedObject>(entityName: ENTITY.nodes.rawValue)
            fetchRequest?.returnsObjectsAsFaults = false
            do {
                if fetchRequest != nil {
                    var results:[NSManagedObject]? = try context.fetch(fetchRequest!)
                    if results != nil {
                        if results!.count > 0 {
                            var success = false
                            for data in results! {
                                if nodeToUpdate == data.value(forKey: "id") as? UUID {
                                    for (keyToUpdate, newValue) in newCredentials {
                                        data.setValue(newValue, forKey: keyToUpdate)
                                        do {
                                            try context.save()
                                            success = true
                                            
                                        } catch {
                                            success = false
                                            
                                        }
                                    }
                                }
                            }
                            results = nil
                            fetchRequest = nil
                            if success {
                                print("updated")
                                completion((true, nil))
                                
                            } else {
                                print("update failed")
                                completion((false, "error editing"))
                                
                            }
                        } else {
                            completion((false, "no results"))
                            
                        }
                    } else {
                        completion((false, "no results"))
                        
                    }
                } else {
                    completion((false, "failed"))
                    
                }
            } catch {
               completion((false, "failed"))
                
            }
        }
    }
    
    class func updateEntity(id: UUID, keyToUpdate: String, newValue: Any, entityName: ENTITY, completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        DispatchQueue.main.async {
            let context = CoreDataService.viewContext
            var fetchRequest:NSFetchRequest<NSManagedObject>? = NSFetchRequest<NSManagedObject>(entityName: entityName.rawValue)
            fetchRequest?.returnsObjectsAsFaults = false
            do {
                if fetchRequest != nil {
                    var results:[NSManagedObject]? = try context.fetch(fetchRequest!)
                    if results != nil {
                        if results!.count > 0 {
                            var success = false
                            for (i, data) in results!.enumerated() {
                                if id == data.value(forKey: "id") as? UUID {
                                    data.setValue(newValue, forKey: keyToUpdate)
                                    do {
                                        try context.save()
                                        success = true
                                        
                                    } catch {
                                        success = false
                                        
                                    }
                                }
                                if i + 1 == results!.count {
                                    fetchRequest = nil
                                    results = nil
                                    if success {
                                        #if DEBUG
                                        print("updated successfully")
                                        #endif
                                        completion((true, nil))
                                        
                                    } else {
                                        completion((false, "error editing"))
                                        
                                    }
                                }
                            }
                        } else {
                            completion((false, "no results"))
                            
                        }
                    }
                }
            } catch {
                completion((false, "failed"))
                
            }
        }
    }
    
    class func deleteEntity(id: UUID, entityName: ENTITY, completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        DispatchQueue.main.async {
            let context = CoreDataService.viewContext
            var fetchRequest:NSFetchRequest<NSManagedObject>? = NSFetchRequest<NSManagedObject>(entityName: entityName.rawValue)
            fetchRequest?.returnsObjectsAsFaults = false
            do {
                if fetchRequest != nil {
                    var results:[NSManagedObject]? = try context.fetch(fetchRequest!)
                    var succ = Bool()
                    if results != nil {
                        if results!.count > 0 {
                            for (index, data) in results!.enumerated() {
                                if id == data.value(forKey: "id") as? UUID {
                                    context.delete(results![index] as NSManagedObject)
                                    do {
                                        try context.save()
                                        succ = true
                                        
                                    } catch {
                                        succ = false
                                        
                                    }
                                }
                            }
                            results = nil
                            fetchRequest = nil
                            if succ {
                                completion((true, nil))
                                
                            } else {
                                completion((false, "error deleting"))
                                
                            }
                        } else {
                            completion((false, "no results for that entity to delete"))
                            
                        }
                    } else {
                        completion((false, "no results for that entity to delete"))
                        
                    }
                } else {
                    completion((false, "failed trying to delete that entity"))
                    
                }
            } catch {
                completion((false, "failed trying to delete that entity"))
                
            }
        }
    }
    
}
