//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
import UIKit

class MigrationScreenController: UIViewController {
    
    var returnViewController:UIViewController!
    var returnSegueIdentifier:String!
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if returnViewController == nil && returnSegueIdentifier == nil {
            print("Warning! returnViewController & returnSegueIdentifier are not set! One must be set!")
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // NavigationBar verstecken
        if let navigationController = self.navigationController {
            navigationController.setNavigationBarHidden(true, animated: animated)
        }
        
        // Progress initialisieren
        updateProgress()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // NavigationBar zeigen
        if let navigationController = self.navigationController {
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        print("start Thread")
        DatabaseManager.checkout()
        
        DatabaseManager.checkinForPrivateQueue()
        
        DatabaseManager.managedObjectContext.performBlock { () -> Void in
        
            print("Thread started")
        
            
            MigrationManager.prepareForMigration()
            
            // operateNext so lange aufrufen bis es nil ist
            var result = MigrationManager.MigrationState.KeepProcessing
            while result != MigrationManager.MigrationState.Migrated {
                
                // process() aufrufen
                result = MigrationManager.process()
                
                // Update UI on Main-Thread
                dispatch_async(dispatch_get_main_queue()) {
                    self.updateProgress()
                }
            }
            DatabaseManager.checkout()
            
            // zuruckkehren
            dispatch_async(dispatch_get_main_queue()) {
                
                DatabaseManager.checkin()
                DatabaseManager.managedObjectContext.refreshAllObjects()
                
                if let navigationController = self.navigationController {
                    if let returnViewController = self.returnViewController {
                        navigationController.popToViewController(returnViewController, animated: true)
                    }
                }
                if self.returnSegueIdentifier != nil {
                    self.performSegueWithIdentifier(self.returnSegueIdentifier, sender: self)
                }
                
            }
        }
    }
    
    private func updateProgress() {
        progressBar.progress = MigrationManager.progress
        progressLabel.text = MigrationManager.progressDescription
    }
}