//
//  CoreDataService.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

//import Foundation
import CoreData

class CoreDataService {
    
    static let sharedInstance = CoreDataService()
    
    private init() {}
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentCloudKitContainer(name: "FullyNoded2")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
        
    // MARK: - Core Data Saving support
    func saveContext () {
        
        let context = persistentContainer.viewContext
        
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
    
    func saveEntity(dict: [String:Any], entityName: ENTITY, completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        print("saveEntityToCoreData")
        
        let context = persistentContainer.viewContext
                
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
    
    func retrieveEntity(entityName: ENTITY, completion: @escaping ((entity: [[String:Any]]?, errorDescription: String?)) -> Void) {
        print("retrieveEntity")
        
        let context = persistentContainer.viewContext
        
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
    
    func updateNode(nodeToUpdate: UUID, newCredentials: [String:Any], completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        print("updateEntity")
        
        let context = persistentContainer.viewContext
        
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
    
    func updateEntity(id: UUID, keyToUpdate: String, newValue: Any, entityName: ENTITY, completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        print("updateEntity")
        
        let context = persistentContainer.viewContext
        
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
    
    func deleteEntity(id: UUID, entityName: ENTITY, completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        
        let context = persistentContainer.viewContext
        
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
