//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
import UIKit

class StartPage2ViewController: UIViewController {
    
    internal var previousViewController:UIViewController?

    /// Hide Statusbar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let nextViewController:StartPage3ViewController = segue.destinationViewController as? StartPage3ViewController {
            nextViewController.previousViewController = self
        }
    }
    
    @IBAction func back(sender: UIButton) {
        if let previousViewController = self.previousViewController {
            self.navigationController!.popToViewController(previousViewController, animated: true)
        } else {
            print("previousViewController not set!")
        }
    }
    
}
