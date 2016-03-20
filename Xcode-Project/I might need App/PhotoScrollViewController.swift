//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import UIKit
import Photos
import AssetsLibrary

/**
    Diese Klasse dient zum ansehen der Fotos.
    ACHTUNG: VOR DEM START MUSS desiredStartupSnap GESETZT WERDEN
 */
class PhotoScrollViewController: UIViewController, UIScrollViewDelegate {
    
    /**
        Der vor dem Start gewunschte.
        ACHTUNG: MUSS VOR DEM START MUSS desiredStartupSnap GESETZT WERDEN DAMIT EIN SNAP ANGEZEIGT WERDEN KANN
     */
    internal var desiredStartupSnap:Int? = nil
    
    /// Toolbar welche unten am Screen anzezeigt wird. (Im Storyboards erzeugt)
    @IBOutlet weak var bottomBar: UIToolbar!
    
    /// Button auf dem Push steht
    @IBOutlet weak var pushButton: UIBarButtonItem!
    
    private var mainScrollView: UIScrollView!
    
    private var pageScrollViews:[UIScrollView?] = [UIScrollView]()
    
    private var currentPageView: UIView!
    
    /// Anzahl von Seiten durch welche gesrollt wird
    private var numberOfPages:Int = -1
    
    /// Aktuelle Seitennummer
    private var _currentPageNumber:Int = -1
    private var currentPageNumber:Int {
        get {
            return _currentPageNumber
        }
        set(newValue) {
            _currentPageNumber = newValue
            MainScreenViewController.jumpToIndex = newValue+6
        }
    }
    
    /// Groesse von gesammtem ScrollView-Content. Wird durch configScrollView() gesetzt
    private var mainScrollViewContentSize: CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //deviceOrientation = UIDevice.currentDevice().orientation
        
        AppDelegate.photoScrollViewController = self
        
        initViewElements()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("didReceiveMemoryWarning()")
    }
    
    var landscapeViewController:LandscapeViewController? = nil
    
    func rotated()
    {
        //print("device rotated")
        
        if !PreferencesManager.disableRotation {
        
            let deviceOrientation = UIDevice.currentDevice().orientation;
            
            if landscapeViewController == nil {
                if deviceOrientation == UIDeviceOrientation.LandscapeRight || deviceOrientation == UIDeviceOrientation.LandscapeLeft {
                    //self.performSegueWithIdentifier("showLandscape", sender: selfPointer);
                    self.performSegueWithIdentifier("test", sender: self);
                }
            } else {
                //landscapeViewController!.updateOrientation(deviceOrientation);
                if deviceOrientation == UIDeviceOrientation.LandscapeRight || deviceOrientation == UIDeviceOrientation.LandscapeLeft {
                    
                    landscapeViewController!.updateOrientation(deviceOrientation);
                    
                } else if deviceOrientation == UIDeviceOrientation.Portrait {
                    //self.landscapeViewController!.navigationController!.popViewControllerAnimated(false)
                    
                    self.landscapeViewController!.navigationController!.popViewControllerAnimated(false)
                }
            }

        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let lvc:LandscapeViewController = segue.destinationViewController as? LandscapeViewController {
            
            self.landscapeViewController = lvc
            
            // Aktuelles Bild laden
            let currentSnap = fetchSnapForPage(currentPageNumber)
            let image:UIImage = (currentSnap!.image)!
            
            // Bild in Ziel setzten
            lvc.image = image;
            
        } else {
        }
    }
    
    private func initViewElements() {
        mainScrollView = UIScrollView(frame: self.view.bounds)
        mainScrollView.pagingEnabled = true
        mainScrollView.showsHorizontalScrollIndicator = false
        mainScrollView.showsVerticalScrollIndicator = false
        
        // Seitenanzahl laden
        self.numberOfPages = fetchPhotoCount()
        //self.currentPageNumber = 0
        
        // Pushbutton setzen
        if desiredStartupSnap == 0 {
            setPushButtonAppearance(self.PUSHBUTTONAPPEARANCE_HIDDEN)
        } else {
            setPushButtonAppearance(self.PUSHBUTTONAPPEARANCE_PUSH)
        }
        
        pageScrollViews = [UIScrollView?](count: numberOfPages, repeatedValue: nil)
        
        
        let innerScrollFrame = mainScrollView.bounds
        
        mainScrollView.contentSize
            = CGSizeMake(innerScrollFrame.origin.x + innerScrollFrame.size.width, mainScrollView.bounds.size.height)
        
        mainScrollView.backgroundColor = UIColor.blackColor()
        
        mainScrollView.delegate = self
        
        self.view.addSubview(mainScrollView)
        
        configScrollView()
        
        // Einstellungen am NavigationController vornehmen
        if let navigationController:UINavigationController = self.navigationController {
            
            // Verbergen der navigationBar beim Start
            navigationController.navigationBar.hidden = true
            
            // Swipeback Geste deaktivieren
            if navigationController.respondsToSelector("interactivePopGestureRecognizer") {
                navigationController.interactivePopGestureRecognizer!.enabled = false
            } else {
                print("navigationController doen't respond to Selector interactivePopGestureRecognizer")
            }
            
        } else {
            print("self.navigationController is nil!")
        }
        
        // Random Bugfix. Bild springt wenn Statusbar & Navigationbar eingeblendet werden [BUG001] (siehe: Issues.txt)
        self.automaticallyAdjustsScrollViewInsets = false
        
        // UITapGestureRecognizer erstellen
        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "singleTap:") // (einfacher Tap)
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        mainScrollView.addGestureRecognizer(singleTap)
        let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "doubleTap:") // (doppelter Tap)
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        singleTap.requireGestureRecognizerToFail(doubleTap) // (Reaktion des ersten Taps soll verzoegert werden um auf doppel Tap zu warten)
        mainScrollView.addGestureRecognizer(doubleTap)
        
        // Toolbar hinzufuegen
        bottomBar.hidden = true
        self.view.addSubview(bottomBar)
        
        // Damit UIElemente beim start sichtbar sind
        toogleUIVisibility()
        
        // Auf StartupSnap springen
        if let desiredStartupSnap = self.desiredStartupSnap {
            if desiredStartupSnap >= 0 && desiredStartupSnap < numberOfPages {
                changePage(numberOfPages - desiredStartupSnap - 1)
            } else {
                print("desiredStartupSnap outside bounds!")
            }
        } else {
            print("self.desiredStartupSnap is nil!")
        }
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        self.landscapeViewController = nil
        
        if let navigationController:UINavigationController = self.navigationController {
            navigationController.navigationBar.hidden = shouldHideNavigationBar
        }
        
        loadVisiblePages()
    }
    
    /*override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.Portrait]
    }*/
    
    /// Muss bei jeder Groessenanderung der Scrollview aufgerufen werden
    func configScrollView() {
        self.mainScrollView.contentSize = CGSizeMake(self.mainScrollView.frame.width * CGFloat(numberOfPages), self.mainScrollView.frame.height)
        mainScrollViewContentSize = mainScrollView.contentSize
    }
    
    /**
     * Laed Snap aus Model und gibt es zuruek.
     * Soll so selten wie Moeglich abgerufen werden.
     */
    func fetchSnapForPage(page: Int) -> Snap? {
        //print("fetchSnapForPage(\(page))")
        
        /*
        let path = NSBundle.mainBundle().pathForResource(ps[page], ofType: "jpg")
        let image = UIImage(contentsOfFile: path!)
        */
        
        // Snapnummer bestimmen
        let call = numberOfPages-page-1
        
        // Snap abfragen
        if let snap = DatabaseManager.snap(call) {
            return snap
        } else {
            print("DatabaseManager.snap(\(numberOfPages)-\(page)-1=\(call))) returns nil!")
        }
        print("Can't fetch Snap!")
        return nil
    }
    
    
    
    /**
     * Laed Photoanzahl aus Model und gibt es als Int zuruek.
     * Soll so selten wie Moeglich abgerufen werden.
     */
    func fetchPhotoCount() -> Int {
        /*
        print("fetchPhotoCount()")
        return ps.count
        */
        return DatabaseManager.snapCount
    }
    
    /// Snap an Anfang pushen und auf diese Seie gehen
    @IBAction func pushSnap(sender: AnyObject) {
        //print("\(__FUNCTION__)")
        if !lockOperations {
            
            lockOperations = true
            
            let snapView:UIView = pageScrollViews[self.currentPageNumber]!
            
            snapView.layer.opacity = 1.0
            
            // Animation
            snapView.layer.opacity = 1.0
            UIView.animateWithDuration(0.2, animations: {
                
                snapView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.2, 1.2);
                
                }, completion: {(finished: Bool) -> Void in
                    
                    // Push Button setzen
                    self.setPushButtonAppearance(self.PUSHBUTTONAPPEARANCE_PUSHED)
                    
                    UIView.animateWithDuration(0.2, animations: {
                        
                        snapView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
                        
                        }, completion: {(finished: Bool) -> Void in
                            
                            // Aktuellen Snap abfragen
                            let currentSnapIndex = self.numberOfPages-self.currentPageNumber-1
                            
                            // Snap pushen
                            if DatabaseManager.pushSnap(currentSnapIndex) != nil { // (Snap pushen)
                                DatabaseManager.save() // (Datenbank sofort abspeichern! sehr wichtig)
                                
                                // Auf letzte Seite wechseln
                                self.clearCache() // (geladene Seiten loeschen)
                                self.mainScrollView.reloadInputViews()
                                self.changePage(self.numberOfPages - 1)
                            } else {
                                print("DatabaseManager.pushSnap(currentSnapIndex) returned nil")
                                print("Snap could not be pushed!")
                            }
                    })
                })
            
            lockOperations = false
            
        }
        
    }
    
    var lockOperations = false
    
    func deleteSnap() {
        if !lockOperations {
            
            lockOperations = true
        
            let snapView:UIView = pageScrollViews[self.currentPageNumber]!
        
            snapView.layer.opacity = 1.0
            
            UIView.animateWithDuration(0.2, animations: {
                
                snapView.layer.opacity = 0.0
                
                //let oldFrame = snapView.frame
                //snapView.frame = CGRectMake(oldFrame.origin.x+(oldFrame.width/2)-10, oldFrame.origin.y+(oldFrame.height/2)-10, 20, 20)
                //snapView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 2, 2);
                
                snapView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
                
                }, completion: {(finished: Bool) -> Void in
                    
                    // Aktuellen Snap abfragen
                    let currentSnapIndex = self.numberOfPages-self.currentPageNumber-1
                    
                    // Snap loeschen
                    DatabaseManager.deleteSnap(currentSnapIndex) // (Snap pushen)
                    DatabaseManager.save() // (Datenbank sofort abspeichern! sehr wichtig)
                    
                    // numberOfPages updaten
                    self.numberOfPages--
                    self.pageScrollViews[self.pageScrollViews.count-1]?.removeFromSuperview()
                    self.pageScrollViews[self.pageScrollViews.count-1] = nil
                    self.pageScrollViews.removeLast()
                    self.configScrollView()
                    
                    // Auf letzte Seite wechseln
                    self.clearCache() // (geladene Seiten loeschen)
                    self.mainScrollView.reloadInputViews()
                    if self.numberOfPages == 0 {
                        self.navigationController!.popViewControllerAnimated(true)
                    } else if self.currentPageNumber < self.numberOfPages {
                        self.changePage(self.currentPageNumber)
                    } else {
                        self.changePage(self.numberOfPages-1)
                    }
                    
                    self.lockOperations = false
            })

        }
        
        
    }
    
    /// löschen eines Snaps
    @IBAction func deleteSnap(sender: AnyObject) {
        if PreferencesManager.doentAskOnDeletion {
            deleteSnap()
        } else {
            let refreshAlert = UIAlertController(title: "Delete?", message: "Picture will be lost.", preferredStyle: UIAlertControllerStyle.Alert)
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction) in
                self.deleteSnap()
            }))
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction) in }))
            presentViewController(refreshAlert, animated: true, completion: nil)
        }
    }
    
    /// Erzeugt Popup mit Warnhinweis
    func alert(view: UIViewController, title: String, message: String) {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,handler: nil))
        view.presentViewController(alertController, animated: true, completion: nil)
    }
    
    /// Mehr Optionen anzeigen
    @IBAction func moreOptions(sender: AnyObject) {
        //print("\(__FUNCTION__)")
        
        if !lockOperations {
            
            // Aktuellen Snap abfragen
            let currentSnap = fetchSnapForPage(currentPageNumber)
            
            // AlertController erzeugen
            let optionMenu = UIAlertController(title: nil, message: "Options", preferredStyle: .ActionSheet)
            
            // Moegliche Actions
            let saveTameraRollAction = UIAlertAction(title: "Save to Camera Roll", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                if(currentSnap != nil) {
                    
                    // TODO ...korrekte Abfrage von Rechten implementieren
                    //      (Siehe: ALAssetsLibrary.authorizationStatus())
                    
                    // Bild in Cameraroll speichern
                    let image:UIImage = (currentSnap!.image)!; // (Bild aus Snap abfragen)
                    let libaray:ALAssetsLibrary = ALAssetsLibrary() // (Camera Roll Object erzeugen)
                    let orientation: ALAssetOrientation = ALAssetOrientation(rawValue: image.imageOrientation.rawValue)! // (Orientierung des Fotos bestimmen)
                    libaray.writeImageToSavedPhotosAlbum(image.CGImage, orientation: orientation, completionBlock: nil) // (Bild in Camera Roll schreiben)
                    
                    // TODO ...Fehler richtig abfangen falls kein Zugriff auf Camera Roll
                } else {
                    print("can't save image to cameraroll because displayingSnap=nil !")
                    self.alert(self, title: "Oh!", message: "Can't save image :/");
                }
            })
            
            // Info
            let infoAction = UIAlertAction(title: "Info", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                if(currentSnap != nil) {
                    
                    let infoString = "Created: \(currentSnap!.creationDateString)\n"
                        + "Pushed: \(currentSnap!.pushDateString)\n"
                        + "Step: \(currentSnap!.stepIndex+1) (1 is best)\n"
                        + "Filesize: \(currentSnap!.fileSizeString)\n"
                        + "Dimensions: \(currentSnap!.sizehInPixelsString)"
                    
                    let alertController = UIAlertController(title: "Information", message:
                        infoString, preferredStyle: UIAlertControllerStyle.Alert)
                    
                    alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,handler: nil))
                    self.presentViewController(alertController, animated: true, completion: nil)
                    
                } else {
                    print("Information cann't be shown because displayingSnap=nil !")
                    self.alert(self, title: "Oh!", message: "Can't save image :/");
                }
            })
            
            // Abbruchaction
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {(alert: UIAlertAction!) -> Void in })
            
            // Actions in AlertController registrieren
            optionMenu.addAction(saveTameraRollAction)
            optionMenu.addAction(infoAction)
            optionMenu.addAction(cancelAction)
            
            // AlertController presentieren
            self.presentViewController(optionMenu, animated: true, completion: nil)
        }
    }
    
    /// Bei Einfach-Tap: Blendet bei Tap UI-Elemente ein/aus
    func singleTap(sender: UITapGestureRecognizer?) {
        toogleUIVisibility()
    }
    
    /// Wechselt sichtbarkeit von UI-Elementen
    func toogleUIVisibility() {
        if let navigationController:UINavigationController = self.navigationController {
            
            // Navigationbar einblenden/ausblenden
            shouldHideNavigationBar = !shouldHideNavigationBar
            navigationController.navigationBar.hidden = shouldHideNavigationBar
            
            // Statusbar einblenden/ausblenden
            shouldHideStatusBar = !shouldHideStatusBar; // (Wert von prefersStatusBarHidden() aendern)
            self.setNeedsStatusBarAppearanceUpdate() // (Update von prefersStatusBarHidden() anfragen)
            
            // Toolbar einblenden/ausblenden
            self.bottomBar.hidden = !self.bottomBar.hidden
            
            // Hintergrundfarbe aendern
            if mainScrollView.backgroundColor == UIColor.blackColor() {
                mainScrollView.backgroundColor = UIColor.whiteColor()
            } else if mainScrollView.backgroundColor == UIColor.whiteColor() {
                mainScrollView.backgroundColor = UIColor.blackColor()
            }
            
            // Random Bugfix. Bild springt wenn Statusbar & Navigationbar eingeblendet werden [BUG001] (siehe: Issues.txt)
            mainScrollView.contentOffset.y = 0;
            mainScrollView.contentSize.height = mainScrollView.frame.height;
            
        } else {
            print("self.navigationController is nil!")
        }
    }
    
    /// Bei Doppel-Tap: Zoom ins Bild
    func doubleTap(sender: UITapGestureRecognizer) {
        
        if let currentPageScrollView = pageScrollViews[self.currentPageNumber] {
            // Fall wir sind bereits hinneingezoomt. Herrauszoomen
            if currentPageScrollView.zoomScale > currentPageScrollView.minimumZoomScale {
                
                currentPageScrollView.setZoomScale(currentPageScrollView.minimumZoomScale, animated: true)
            }
            // Fall wir sind herrauszoomt. Hinneingezoomen
            else {
                //currentPageScrollView.pagingEnabled = false
                
                let viewForScrolling = self.viewForZoomingInScrollView(currentPageScrollView)!
                let touch: CGPoint = sender.locationInView(viewForScrolling)
                let scrollViewSize: CGSize = viewForScrolling.bounds.size
                
                //print(scrollViewSize)
                
                
                // Vergroesserungsfaktor bestimmen.
                // Weil minimumZoomScale ein wert <1 ist, wird er durch 1/minimumZoomScale bestimmt
                let scale = 1.0 / currentPageScrollView.minimumZoomScale
                
                // Rechteck zum drauf zu Zoomen erstellen
                let w: CGFloat = scrollViewSize.width / /*currentPageScrollView.maximumZoomScale*/scale
                let h: CGFloat = scrollViewSize.height / /*currentPageScrollView.maximumZoomScale*/scale
                let x: CGFloat = touch.x - (w / 2.0)
                let y: CGFloat = touch.y - (h / 2.0)
                let rectTozoom: CGRect = CGRectMake(x, y, w, h)
                
                currentPageScrollView.zoomToRect(rectTozoom, animated: true)

            }
        } else {
            print("pageScrollViews[self.currentPageNumber] is nil!")
            print("Can't zoom to point!")
        }
    }
    
    /**
     * Speichert Zustand fuer prefersStatusBarHidden().
     * Bei Aenderung sollte self.setNeedsStatusBarAppearanceUpdate() aufgerufen werden damit diese aktiviert wird
     */
    private var shouldHideStatusBar:Bool = true
    private var shouldHideNavigationBar:Bool = true
    
    /// Gibt an ob Statusbar versteckt sein soll
    override func prefersStatusBarHidden() -> Bool {
        return shouldHideStatusBar
    }
    
    private let PUSHBUTTONAPPEARANCE_PUSH:Int = 0;
    private let PUSHBUTTONAPPEARANCE_PUSHED:Int = 1;
    private let PUSHBUTTONAPPEARANCE_HIDDEN:Int = 2;
    
    private func setPushButtonAppearance(apperance: Int) {
        // pushedButton italic machen da dies in Storyboard nicht möglich ist && verstecken
        if apperance == self.PUSHBUTTONAPPEARANCE_PUSH {
            pushButton.setTitleTextAttributes([
                NSFontAttributeName : UIFont.systemFontOfSize(18.0)
                ]
                , forState: .Normal)
            pushButton.tintColor = nil
            pushButton.enabled = true
            pushButton.title = "Push"
        }
        // pushedButton italic machen da dies in Storyboard nicht möglich ist && verstecken
        else if apperance == self.PUSHBUTTONAPPEARANCE_PUSHED {
            pushButton.setTitleTextAttributes([
                NSFontAttributeName : UIFont.italicSystemFontOfSize(16.0)
                ]
                , forState: .Normal)
            pushButton.tintColor = nil
            pushButton.enabled = false
            pushButton.title = "Pushed!"
        }
        // pushedButton italic machen da dies in Storyboard nicht möglich ist && verstecken
        else if apperance == self.PUSHBUTTONAPPEARANCE_HIDDEN {
            pushButton.setTitleTextAttributes([
                NSFontAttributeName : UIFont.systemFontOfSize(18.0)
                ]
                , forState: .Normal)
            pushButton.tintColor = UIColor.clearColor()
            pushButton.enabled = false
            pushButton.title = ""
        }
        
        
        
    }
    
    
    /// Auf bestimmte Seite wechseln
    func changePage(currentPageNumber: Int) -> () {
        self.currentPageNumber = currentPageNumber
        let x = CGFloat(self.currentPageNumber) * mainScrollView.frame.size.width
        mainScrollView.setContentOffset(CGPointMake(x, 0), animated: false)
        loadVisiblePages()
        currentPageView = pageScrollViews[self.currentPageNumber]
    }
    
    func clearCache() {
        for pageScrollView in pageScrollViews {
            pageScrollView?.removeFromSuperview()
            pageScrollView?.tag = viewOutOfDateTag
        }
    }
    
    /*func rotateUIImage(src:UIImage, angleDegrees:Float) -> UIImage {
        let rotatedViewBox: UIView = UIView(frame: CGRectMake(0, 0, src.size.width, src.size.height))
        let angleRadians: Float = angleDegrees * (Float(M_PI) / 180.0)
        let t: CGAffineTransform = CGAffineTransformMakeRotation(CGFloat(angleRadians))
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        rotatedViewBox
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContextRef = UIGraphicsGetCurrentContext()!
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2)
        CGContextRotateCTM(bitmap, CGFloat(angleRadians))
        CGContextScaleCTM(bitmap, 1.0, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-src.size.width / 2, -src.size.height / 2, src.size.width, src.size.height), src.CGImage)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }*/
    
    /// Tag welcher Zoombarem UIImage zugewiesen wird. (siehe getViewAtPage(page:))
    private let viewForZoomTag = 1
    
    private let viewOutOfDateTag = 2
    
    private var deviceOrientation:UIDeviceOrientation = UIDeviceOrientation.Portrait
    
    func getViewAtPage(page: Int) -> UIView? {
        
        print("getViewAtPage(page: \(page))");
        
        if let snap = fetchSnapForPage(page) {
            if let image = snap.image {
                
                let imageCopy = image.copy() as! UIImage
                
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
                
                let imageForZooming = UIImageView(image: imageToDisplay)
                
                var innerScrollFrame = mainScrollView.bounds
                
                if page < numberOfPages {
                    innerScrollFrame.origin.x = innerScrollFrame.size.width * CGFloat(page)
                }
                
                imageForZooming.tag = viewForZoomTag
                
                let pageScrollView = UIScrollView(frame: innerScrollFrame)
            
                pageScrollView.contentSize = imageForZooming.bounds.size
            
                pageScrollView.delegate = self
            
                pageScrollView.showsVerticalScrollIndicator = false
                pageScrollView.showsHorizontalScrollIndicator = false
                
                pageScrollView.addSubview(imageForZooming)
                
                return pageScrollView
            
            } else {
                print("fetchSnap(\(page)) returns nil!")
            }
        } else {
            print("DatabaseManager.snap(\(page)) returns nil!")
        }
        print("Can't create Page!")
        return nil
    }
    
    
    func setZoomScale(scrollView: UIScrollView) {
        
        let imageView = scrollView.viewWithTag(self.viewForZoomTag)
        
        let imageViewSize = imageView!.bounds.size
        let scrollViewSize = scrollView.bounds.size
        let widthScale = scrollViewSize.width / imageViewSize.width
        let heightScale = scrollViewSize.height / imageViewSize.height
        
        scrollView.minimumZoomScale = min(widthScale, heightScale)
        scrollView.zoomScale = scrollView.minimumZoomScale
    }
    
    
    func loadVisiblePages() {
        let currentPage = self.currentPageNumber
        let previousPage =  currentPage > 0 ? currentPage - 1 : 0
        let nextPage = currentPage + 1 > self.numberOfPages ? currentPage : currentPage + 1
        
        //print("\(previousPage)-\(currentPage)-\(nextPage)")
        
        for page in 0..<previousPage {
            purgePage(page)
        }
        
        for var page = nextPage + 1; page < self.numberOfPages; page = page + 1 {
            purgePage(page)
        }
        
        for var page = previousPage; page <= nextPage; page++ {
            loadPage(page)
        }
    }
    
    func loadPage(page: Int) {
        
        if page < 0 || page >= self.numberOfPages {
            return
        }
        
        if let pageScrollView = pageScrollViews[page] {
            
            if pageScrollView.tag != viewOutOfDateTag {
                // Nichts machen weil View bereits geladen und aktuell ist
                setZoomScale(pageScrollView)
                return // (Fertig, kein neues laden)
            }
        }
        
        // View neu laden
        if let pageScrollView = getViewAtPage(page) as? UIScrollView {
            setZoomScale(pageScrollView)
            mainScrollView.addSubview(pageScrollView)
            //print(page)
            pageScrollViews[page] = pageScrollView
        } else {
            //print("getViewAtPage(page) as? UIScrollView is nil");
        }
        
        
    }
    
    /// Entfernt Seite
    func purgePage(page: Int) {
        // Seite existiert sowieso nicht
        if page < 0 || page >= self.numberOfPages/*pageScrollViews.count*/ {
            return
        }
        // Seite sollte existieren
        else {
            // Seite existiert wirklich
            if let pageView = pageScrollViews[page] {
                // View aus UI entfernen
                pageView.removeFromSuperview()
                // Pointer entfernen (damit Speicher frei gegeben werden kann)
                pageScrollViews[page] = nil
            }
            // Seite existiert nicht
            else {
                //print("Page can't be purged!")
            }
        }
    }
    
    
    func centerScrollViewContents(scrollView: UIScrollView) {
        
        // print("\(__FUNCTION__)")
        
        let imageView = scrollView.viewWithTag(self.viewForZoomTag)
        let imageViewSize = imageView!.frame.size
        let scrollViewSize = scrollView.bounds.size
        
        let verticalPadding = imageViewSize.height < scrollViewSize.height ?
            (scrollViewSize.height - imageViewSize.height) / 2 : 0
        
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ?
            (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding)
    }
    
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerScrollViewContents(scrollView)
    }
    
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return scrollView.viewWithTag(viewForZoomTag)
    }
    
    
    /// (UIScrollViewDelegate)
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        //centerScrollViewContents(scrollView)
        
        let targetOffset = targetContentOffset.memory.x
        let zoomRatio = scrollView.contentSize.height / mainScrollViewContentSize.height
        
        //print(" ratio=\(zoomRatio)")
        
        if zoomRatio == 1 {
            
            let mainScrollViewWidthPerPage = mainScrollViewContentSize.width / CGFloat(self.numberOfPages)
            let pageNumber = targetOffset / (mainScrollViewWidthPerPage * zoomRatio)
            self.currentPageNumber = Int(pageNumber)
            
            // Pushbutton setzen
            if currentPageNumber == numberOfPages-1 {
                setPushButtonAppearance(self.PUSHBUTTONAPPEARANCE_HIDDEN)
            } else {
                setPushButtonAppearance(self.PUSHBUTTONAPPEARANCE_PUSH)
            }
            
            loadVisiblePages()
            
        }
    }
    
    /*override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        // Quick and dirty...
        initViewElements()
        loadVisiblePages()
    }*/
}

