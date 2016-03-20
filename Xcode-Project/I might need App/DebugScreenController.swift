//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
import UIKit

class DebugScreenController: UIViewController {

    var filling:Bool = false;
    
    @IBOutlet weak var fillButton: UIButton!
    
    @IBOutlet weak var stopButton: UIButton!
    
    @IBOutlet weak var createdLabel: UILabel!
    
    @IBOutlet weak var infoLabel0: UILabel!
    @IBOutlet weak var infoLabel1: UILabel!
    @IBOutlet weak var infoLabel2: UILabel!
    
    override func viewDidLoad() {
        self.updateInfo(self)
    }
    
    @IBAction func updateInfo(sender: AnyObject) {
        infoLabel0.text = "step0.snapCount = \(DatabaseManager.step0!.snapCount)  .maxSnapCount = \(DatabaseManager.step0!.maxSnapCount)"
        infoLabel1.text = "step1.snapCount = \(DatabaseManager.step1!.snapCount)  .maxSnapCount = \(DatabaseManager.step1!.maxSnapCount)"
        infoLabel2.text = "step2.snapCount = \(DatabaseManager.step2!.snapCount)  .maxSnapCount = \(DatabaseManager.step2!.maxSnapCount)"
    }
    
    @IBAction func printDatabase(sender: AnyObject) {
        DatabaseManager.printOverview()
    }
    
    @IBAction func stopFillWithDummys(sender: AnyObject) {
        filling = false
    }
    
    @IBAction func fillWithDummys(sender: AnyObject) {
        fillButton.enabled = false
        self.stopButton.enabled = true
        filling = true
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            let dummy1 = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("dummy-1", ofType: "jpg")!)
            let dummy2 = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("dummy-2", ofType: "jpg")!)
            let dummy3 = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("dummy-3", ofType: "jpg")!)
            let dummy4 = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("dummy-4", ofType: "jpg")!)
            let dummy5 = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("dummy-5", ofType: "jpg")!)
            
            var i:Int=0
            
            while(self.filling) {
                
                let diceRoll = Int(arc4random_uniform(5) + 1)
                var img = dummy1;
                if diceRoll == 2 {
                    img = dummy2
                } else if diceRoll == 3 {
                    img = dummy3
                } else if diceRoll == 4 {
                    img = dummy4
                } else if diceRoll == 5 {
                    img = dummy5
                }
                
                DatabaseManager.createSnap(photo: img!)
                DatabaseManager.save()
                
                i++
                dispatch_async(dispatch_get_main_queue(), {
                    self.createdLabel.text = "(\(i) created)"
                })
            }
            
            print("Finished")
            dispatch_async(dispatch_get_main_queue(), {
                self.fillButton.enabled = true
                self.stopButton.enabled = false
            })
        }
        
    }
    
}
