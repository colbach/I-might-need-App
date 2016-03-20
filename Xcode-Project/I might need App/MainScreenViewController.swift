//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import UIKit

class MainScreenViewController: UICollectionViewController, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate {
    
    /// Collectionview in der Thumbs angezeigt werden
    @IBOutlet var thumbViewCollection: UICollectionView!
    
    let scrollToBottomButton = UIButton(type: UIButtonType.System) as UIButton
    
    internal static var jumpToIndex: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(named: "BottomButton") as UIImage?
        
        let scrollToBottomButton = UIButton(type: UIButtonType.System) as UIButton
        scrollToBottomButton.frame = CGRectMake(CGFloat(UIScreen.mainScreen().bounds.width/CGFloat(2))-105, UIScreen.mainScreen().bounds.height-34, 211 , 34)
        scrollToBottomButton.setBackgroundImage(image, forState: .Normal)
        scrollToBottomButton.addTarget(self, action: "scrollToBottomButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(scrollToBottomButton)
        
    }
    
    func scrollToBottomButtonPressed(sender: AnyObject) {
        scrollToBottom(true)
    }
    
    private var isFirst = true
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirst  {
            isFirst = false
            scrollToBottom(false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("didReceiveMemoryWarning()")
        print("Lösche Cell-Cache...")
        cachedThumbnails.removeAll()
    }
    
    static var navigator:UINavigationController? = nil
    
    override func viewWillAppear(animated: Bool) {
        // Titel setzen
        self.navigationItem.title = "I might need App"
        
        // Kontrolle ob nicht geschriebene Aenderungen in Model existieren
        if !PreferencesManager.isPreparedValuesEqualWrittenValues() {
            // AlertController erzeugen
            let applyChangesDialog = UIAlertController(title: nil, message: "Do you want to apply the changes?", preferredStyle: .ActionSheet)
            
            // Moegliche Actions
            let applyAction = UIAlertAction(title: "Apply", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                PreferencesManager.writePreparedValues()
                
                if MigrationManager.needsMigration {
                    self.performSegueWithIdentifier("showMigration", sender: self)
                }
            })
            
            // Abbruchaction
            let cancelAction = UIAlertAction(title: "Discard changes", style: .Cancel, handler: {(alert: UIAlertAction!) -> Void in
                PreferencesManager.resetPreparedValues()
            })
            
            // Actions in AlertController registrieren
            applyChangesDialog.addAction(applyAction)
            applyChangesDialog.addAction(cancelAction)
            
            // AlertController presentieren
            self.presentViewController(applyChangesDialog, animated: false, completion: nil)
        }
        
        ThumbViewCell.giveOrientation(UIApplication.sharedApplication().statusBarOrientation)
        self.thumbViewCollection.reloadData()
        //self.navigationController?.hidesBarsOnTap = false
        
        if MainScreenViewController.jumpToIndex != -1 {
            scrollToIndex(MainScreenViewController.jumpToIndex, animated: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        // Titel setzen
        self.navigationItem.title = "Back"
    }

    /// View soll sich nicht im Cameramodus drehen
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    func scrollToBottom(animated: Bool) {
        /*
        self.collectionView?.contentInset = UIEdgeInsetsZero;
        let item = self.collectionView(self.collectionView!, numberOfItemsInSection: 0) - 1
        let lastItemIndex = NSIndexPath(forItem: item, inSection: 0)
        self.collectionView?.scrollToItemAtIndexPath(lastItemIndex, atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: animated)
        */
        
        self.collectionView!.setContentOffset(CGPointMake(0, self.collectionView!.contentSize.height-UIScreen.mainScreen().bounds.height), animated: animated)

    }
    
    func scrollToIndex(var index: Int, animated: Bool) {
        self.collectionView?.contentInset = UIEdgeInsetsZero;
        let maxIndex = self.collectionView(self.collectionView!, numberOfItemsInSection: 0) - 1
        if index < 0 {
            index = 0
        } else if index > maxIndex {
            index = 0
            scrollToBottom(animated)
            return
        }
        let lastItemIndex = NSIndexPath(forItem: index, inSection: 0)
        self.collectionView?.scrollToItemAtIndexPath(lastItemIndex, atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: animated)
    }
    
    /**
        Wird bei Tap auf Bild aufgerufen
        @param index Dies ist der Index des Snap. Nicht der CollectionviewCell!
     */
    func showSnap(index: Int) {
        if let snap = DatabaseManager.snap(index) {
            self.displayingSnapIndex = index
            self.displayingSnap = snap
            self.performSegueWithIdentifier("showSnap", sender: nil)
        }
    }
    
    /// Snap der angezeigt werden soll
    var displayingSnap:Snap? = nil
    /// Index von Snap der angezeigt werden soll.
    var displayingSnapIndex:Int? = nil
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let photoScrollViewController:PhotoScrollViewController = segue.destinationViewController as? PhotoScrollViewController {
            photoScrollViewController.desiredStartupSnap = self.displayingSnapIndex
        } else if segue.identifier == "showCamera" {
            CameraViewController.msvc = self
        } else if let migrationScreenViewController:MigrationScreenController = segue.destinationViewController as? MigrationScreenController {
            migrationScreenViewController.returnViewController = self
        }
        
    }
    
    /// Wird aufgerufen wenn Foto gemacht werden soll
    func takePhoto() {
        //print("takePhoto()")
        let photoPicker = UIImagePickerController()
        photoPicker.delegate = self
        photoPicker.sourceType = .PhotoLibrary // -> UIImagePickerControllerSourceType.Camera
        self.presentViewController(photoPicker, animated: true, completion: nil)
    }
    
    // === UICollectionViewDataSource FUNKTIONALITÄT ===
    
    /// Anzahl Thumbs bestimmen
    internal var numberOfItems:Int = 0
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        updateIndexLMS()
        return numberOfItems + 2;
    }
    
    /// Cell Cache photoIdentifier:ThumbViewCell
    private var cachedThumbnails = [String: UIImage]()
    
    /// Einzelne Thumb-Views erzeugen
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if indexPath.item < numberOfItems {
            
            let cell: ThumbViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("ThumbViewCell", forIndexPath: indexPath) as! ThumbViewCell
            let snap = DatabaseManager.snaps[numberOfItems - indexPath.item - 1]
            
            if let cachedThumbnail = cachedThumbnails[snap.photoIdentifier!] {
                cell.setImage(cachedThumbnail)
            } else if let thumbnail = snap.thumbnail {
                cell.setImage(thumbnail)
                if snap.photoIdentifier != nil {
                    cachedThumbnails[snap.photoIdentifier!] = thumbnail
                }
            }
            return cell;
        } else if indexPath.item == numberOfItems {
            return collectionView.dequeueReusableCellWithReuseIdentifier("CameraCell", forIndexPath: indexPath) 
        } else if indexPath.item == numberOfItems+1 {
            return collectionView.dequeueReusableCellWithReuseIdentifier("BlankViewCell", forIndexPath: indexPath) 
        }
        assert(false, "Unexpected Item")
    }
    
    /// Aktuelle Grössenverteilung (L->Step0 M->Step1 S->Step0)
    private var lastIndexS = -1, lastIndexM = -1, lastIndexL = -1;
    
    
    /// Aktualisiert lastIndexL, lastIndexM & lastIndexS
    private func updateIndexLMS() {
        
        numberOfItems = DatabaseManager.snapCount
        
        lastIndexS = DatabaseManager.step2!.snapCount - 1
        var overflowS = 0
        while (lastIndexS+1)%ThumbViewCell.lineCountStep2 != 0 {
            lastIndexS++
            overflowS++
        }
        
        lastIndexM = DatabaseManager.step2!.snapCount + DatabaseManager.step1!.snapCount - 1
        while (lastIndexM-lastIndexS)%ThumbViewCell.lineCountStep1 != 0 {
            lastIndexM++
        }
        lastIndexL = numberOfItems - 1;
    }
    
    /// Grösse einzelner Thumbs bestimmen
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        var edge:CGFloat?
        if indexPath.item <= lastIndexS {
            edge = ThumbViewCell.getEdgeInPoints(2)
        } else if indexPath.item <= lastIndexM {
            edge = ThumbViewCell.getEdgeInPoints(1)
        } else if indexPath.item <= lastIndexL {
            edge = ThumbViewCell.getEdgeInPoints(0)
        } else if indexPath.item == numberOfItems {
            edge = ThumbViewCell.getEdgeInPoints(0)
        } else if indexPath.item == numberOfItems+1 {
            if let widthThird = ThumbViewCell.getEdgeInPoints(0) {
                return CGSize(width: 3.0*widthThird, height: 4.0);
            }
        }
        
        if(edge != nil) {
            return CGSize(width: edge!, height: edge!);
        } else {
            print("Warning: Cellsize can not be set correctly. Fallback: edge=40")
            return CGSize(width:40, height:40);
        }
        
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        //ThumbViewCell.giveOrientation(fromInterfaceOrientation)
        //updateIndexLMS()
        self.collectionView!.performBatchUpdates(nil, completion: { _ in })
    }
    
    /// Footer erzeugen
    override func collectionView(collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
            switch kind {
            case UICollectionElementKindSectionHeader:
                let infoView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "InfoViewCell", forIndexPath: indexPath) as! InfoViewCell
                infoView.label.text = "\(numberOfItems) Photos"
                return infoView
            case UICollectionElementKindSectionFooter:
                let blankView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "BlankViewCell", forIndexPath: indexPath) as! BlankViewCell
                return blankView
            default:
                assert(false, "Unexpected SupplementaryElementOfKind")
            }
    }
    
    // === UICollectionViewDelegate FUNKTIONALITÄT ===
    
    /// Wird bei Tap auf Ellement von CollectionView aufgerufen
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.item < numberOfItems {
            showSnap(numberOfItems - indexPath.item - 1)
        } /*else if indexPath.item == numberOfItems {
            takePhoto()
        }*/
    }
    
    // === UIImagePicker FUNKTIONALITÄT ===
    
    /// Wird bei erfolgreicher Bildauswahr aufgerufen
    func imagePickerController(picker: UIImagePickerController,didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    
        let image: UIImage? = (info[UIImagePickerControllerOriginalImage] as? UIImage)
    
        self.dismissViewControllerAnimated(true, completion: nil)
    
        DatabaseManager.createSnap(photo: image!) // neues Bild an DatabaseManager übergeben
        DatabaseManager.save() // speichern
        
        // CollectionView neu laden
        self.thumbViewCollection.reloadData()
        scrollToBottom(false)
    }
    
    /// More Button gedruekt (Button oben links)
    @IBAction func moreButtonPressed(sender: UIBarButtonItem) {
        // AlertController erzeugen
        let optionMenu = UIAlertController(title: nil, message: "More Options", preferredStyle: .ActionSheet)
        
        // Moegliche Actions
        let cameraRollAction = UIAlertAction(title: "Take Photo via System Dialog", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            let photoPicker = UIImagePickerController()
            photoPicker.delegate = self
            photoPicker.sourceType = .Camera
            self.presentViewController(photoPicker, animated: true, completion: nil)
        })
        let systemDialogAction = UIAlertAction(title: "Import Photo from Camera Roll", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            let photoPicker = UIImagePickerController()
            photoPicker.delegate = self
            photoPicker.sourceType = .PhotoLibrary
            self.presentViewController(photoPicker, animated: true, completion: nil)
        })
        let infoAction = UIAlertAction(title: "Database Information", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            let infoString =
            "Step 1: \(DatabaseManager.step0!.snapCount) (of \(DatabaseManager.step0!.maxSnapCount))\n"
                + "Step 2: \(DatabaseManager.step1!.snapCount) (of \(DatabaseManager.step1!.maxSnapCount))\n"
                + "Step 3: \(DatabaseManager.step2!.snapCount) (of \(DatabaseManager.step2!.maxSnapCount))\n"
            
            //DatabaseManager.printOverview()
            
            let alertController = UIAlertController(title: "Database Information", message: infoString, preferredStyle: UIAlertControllerStyle.Alert)
                
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
            
        })
        
        // Abbruchaction
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {(alert: UIAlertAction!) -> Void in })
        
        
        // Actions in AlertController registrieren
        optionMenu.addAction(cameraRollAction)
        optionMenu.addAction(systemDialogAction)
        optionMenu.addAction(infoAction)
        optionMenu.addAction(cancelAction)
        
        // AlertController presentieren
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    
    /*func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 90, 0);
    }*/

}