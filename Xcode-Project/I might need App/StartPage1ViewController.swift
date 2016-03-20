//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
import UIKit

class StartPage1ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Navigationbar verstecken
        self.navigationController!.setNavigationBarHidden(true, animated: false)
    }
    
    /// Hide Statusbar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let nextViewController:StartPage2ViewController = segue.destinationViewController as? StartPage2ViewController {
            nextViewController.previousViewController = self
        }
    }
}
