//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
import CoreData

public class CoreData : NSObject {

    let managedObjectModel : NSManagedObjectModel
    let persistentStoreCoordinator : NSPersistentStoreCoordinator
    
    private init(storeType : String, documentName : String?, schemaName : String, options : [NSObject : AnyObject]?) {

        let bundle = NSBundle(forClass:object_getClass(CoreData))
        var modelURL = bundle.URLForResource(schemaName, withExtension: "mom")
        if (modelURL == nil) {
            modelURL = bundle.URLForResource(schemaName, withExtension: "momd")
        }
        managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL!)!

        var storeURL : NSURL?
        if (storeType != NSInMemoryStoreType) {
            storeURL = CoreData.applicationDocumentsDirectory().URLByAppendingPathComponent(documentName!)
            NSLog("%@", storeURL!.path!);
        }

        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
            try persistentStoreCoordinator.addPersistentStoreWithType(storeType, configuration: nil, URL: storeURL, options: options)
        } catch {
            NSLog("Unresolved error")
            abort()
        }
    }

    public convenience init(sqliteDocumentName : String, schemaName : String) {
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        self.init(storeType: NSSQLiteStoreType, documentName: sqliteDocumentName, schemaName: schemaName, options: options)
    }

    public convenience init(inMemorySchemaName : String) {
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        self.init(storeType: NSInMemoryStoreType, documentName: nil, schemaName: inMemorySchemaName, options: options)
    }

    private class func applicationDocumentsDirectory() -> NSURL {
        //return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
        return NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask).last!
    }

    public func createManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        return managedObjectContext
    }
    

}