//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import UIKit
import Photos
import AssetsLibrary

class LandscapeViewController: UIViewController, UIScrollViewDelegate {
    
    /**
     * Speichert Zustand fuer prefersStatusBarHidden().
     * Bei Aenderung sollte self.setNeedsStatusBarAppearanceUpdate() aufgerufen werden damit diese aktiviert wird
     */
    private var shouldHideStatusBar:Bool = true
    
    /// Gibt an ob Statusbar versteckt sein soll
    override func prefersStatusBarHidden() -> Bool {
        return shouldHideStatusBar
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    internal var image:UIImage? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let deviceOrientation = UIDevice.currentDevice().orientation;
        if image != nil {
            updateOrientation(deviceOrientation)
        }
        
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
        
        let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "doubleTap:") // (doppelter Tap)
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        view.addGestureRecognizer(doubleTap)
        
        
        // Navigationbar einblenden/ausblenden
        //navigationController!.navigationBar.hidden = true
        
        // Statusbar einblenden/ausblenden
        //shouldHideStatusBar = true; // (Wert von prefersStatusBarHidden() aendern)
        //self.setNeedsStatusBarAppearanceUpdate() // (Update von prefersStatusBarHidden() anfragen)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController!.navigationBar.hidden = true
    }
    
    /// Bei Doppel-Tap: Zoom ins Bild
    func doubleTap(sender: UITapGestureRecognizer) {
        
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
            // Fall wir sind herrauszoomt. Hinneingezoomen
        else {
            //currentPageScrollView.pagingEnabled = false
            
            let viewForScrolling = imageView
            let touch: CGPoint = sender.locationInView(viewForScrolling)
            let scrollViewSize: CGSize = viewForScrolling.bounds.size
            
            // Vergroesserungsfaktor bestimmen.
            let scale:CGFloat = 1.0 / 0.2
            
            // Rechteck zum drauf zu Zoomen erstellen
            let w: CGFloat = scrollViewSize.width / scale
            let h: CGFloat = scrollViewSize.height / scale
            let x: CGFloat = touch.x - (w / 2.0)
            let y: CGFloat = touch.y - (h / 2.0)
            let rectTozoom: CGRect = CGRectMake(x, y, w, h)
            
            scrollView.zoomToRect(rectTozoom, animated: true)
            
        }
    }
    
    internal func updateOrientation(deviceOrientation: UIDeviceOrientation) {
        
        let imageCopy = image!.copy() as! UIImage
        var orientation:UIImageOrientation! = nil
        
        // in diesem Teil wird durch Manipulation der Orientierung welche in jedem Bild enthalten ist eine Drehung simuliert.
        if deviceOrientation == UIDeviceOrientation.LandscapeRight {
            if imageCopy.imageOrientation == UIImageOrientation.Down {
                orientation = UIImageOrientation.Right
            } else if imageCopy.imageOrientation == UIImageOrientation.Left {
                orientation = UIImageOrientation.Down
            } else if imageCopy.imageOrientation == UIImageOrientation.Right {
                orientation = UIImageOrientation.Up
            } else if imageCopy.imageOrientation == UIImageOrientation.Up {
                orientation = UIImageOrientation.Left
            }
        } else if deviceOrientation == UIDeviceOrientation.LandscapeLeft {
            if imageCopy.imageOrientation == UIImageOrientation.Down {
                orientation = UIImageOrientation.Left
            } else if imageCopy.imageOrientation == UIImageOrientation.Left {
                orientation = UIImageOrientation.Up
            } else if imageCopy.imageOrientation == UIImageOrientation.Right {
                orientation = UIImageOrientation.Down
            } else if imageCopy.imageOrientation == UIImageOrientation.Up {
                orientation = UIImageOrientation.Right
            }
        } else {
            orientation = imageCopy.imageOrientation
        }
        
        let imageToDisplay: UIImage = UIImage(CGImage: imageCopy.CGImage!, scale: 1.0, orientation:orientation)
        
        imageView.image = imageToDisplay
    }
    
    override func shouldAutorotate() -> Bool {
        return false;
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView;
    }

}
