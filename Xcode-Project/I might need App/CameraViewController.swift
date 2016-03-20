//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import UIKit
import AVFoundation
import AssetsLibrary

// Context-Referenzen für Observer (im Grunde nur Pointer)
var SessionRunningAndDeviceAuthorizedContext = "SessionRunningAndDeviceAuthorizedContext"
var CapturingStillImageContext = "CapturingStillImageContext"
var RecordingContext = "RecordingContext"

class CameraViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    /**
       Referenz auf MainScreen
       WICHTIG: Muss vor display der View gesetzt werden
       ACHTUNG: WENN NICHT GESETZT KANN THUMB COLLECTION VIEW NICHT ARBEITEN
     */
    static var msvc:MainScreenViewController? = nil;
    
    // MARK: property
    
    var sessionQueue: dispatch_queue_t!
    var session: AVCaptureSession?
    var videoDeviceInput: AVCaptureDeviceInput?
    var movieFileOutput: AVCaptureMovieFileOutput?
    var stillImageOutput: AVCaptureStillImageOutput?
    
    /** Indikator ob Camera-Berrechtigung gesetzt ist.
        Wird durch checkDeviceAuthorizationStatus() aktualisiert */
    var deviceAuthorized: Bool  = false
    
    var backgroundRecordId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var sessionRunningAndDeviceAuthorized: Bool {
        get {
            return (self.session?.running != nil && self.deviceAuthorized )
        }
    }
    
    var runtimeErrorHandlingObserver: AnyObject?
    
    /// Referenz auf Echtzeitvorschau in View
    @IBOutlet weak var previewView: AVCamPreviewView!
    
    /// Referenz auf Take Button in View
    @IBOutlet weak var takeButton: UIButton!
    
    /// Referenz auf Switch Camera Button in View
    @IBOutlet weak var switchCameraButton: UIButton!
    
    /// Referenz auf Flash Button in View
    @IBOutlet weak var flashButton: UIButton!
    
    /// damit viewDidLoad() weiss ob es das erste Laden ist
    private var isFirst = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let session: AVCaptureSession = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto;
        
        self.session = session
        
        
        self.previewView.session = session
        
        self.checkDeviceAuthorizationStatus()
        
        
        //(self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravityResizeAspectFill;
        (self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravityResizeAspect
        
        
        let sessionQueue: dispatch_queue_t = dispatch_queue_create("session queue",DISPATCH_QUEUE_SERIAL)
        
        self.sessionQueue = sessionQueue
        dispatch_async(sessionQueue, {
            self.backgroundRecordId = UIBackgroundTaskInvalid
            
            let videoDevice: AVCaptureDevice! = CameraViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: AVCaptureDevicePosition.Back)
            var error: NSError? = nil
            

            
            var videoDeviceInput: AVCaptureDeviceInput?
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            } catch let error1 as NSError {
                error = error1
                videoDeviceInput = nil
            } catch {
                fatalError()
            }
            
            if (error != nil) {
                print(error)
                let alert = UIAlertController(title: "Error", message: error!.localizedDescription
                    , preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }

            if session.canAddInput(videoDeviceInput){
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                dispatch_async(dispatch_get_main_queue(), {
                    // Why are we dispatching this to the main queue?
                    // Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
                    // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.

                    let orientation: AVCaptureVideoOrientation =  AVCaptureVideoOrientation(rawValue: self.interfaceOrientation.rawValue)!
                    
                    (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = orientation
                    
                })
                
            }
            
            /*
            let audioDevice: AVCaptureDevice = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio).first as! AVCaptureDevice
            
            var audioDeviceInput: AVCaptureDeviceInput?
            
            do {
                audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            } catch let error2 as NSError {
                error = error2
                audioDeviceInput = nil
            } catch {
                fatalError()
            }

            
            if error != nil{
                print(error)
                let alert = UIAlertController(title: "Error", message: error!.localizedDescription
                    , preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            if session.canAddInput(audioDeviceInput){
                session.addInput(audioDeviceInput)
            }
            */
            
            
            
            let movieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieFileOutput){
                session.addOutput(movieFileOutput)

                let connection: AVCaptureConnection? = movieFileOutput.connectionWithMediaType(AVMediaTypeVideo)
                let stab = connection?.supportsVideoStabilization
                if (stab != nil) {
                    //connection!.enablesVideoStabilizationWhenAvailable = true //veraltet
                    connection!.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.Standard
                }
                
                self.movieFileOutput = movieFileOutput
            }

            let stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
            if session.canAddOutput(stillImageOutput){
                stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                session.addOutput(stillImageOutput)
                
                self.stillImageOutput = stillImageOutput
            }
            
            if self.isFirst  {
                self.isFirst = false
                self.scrollToEnd()
            }
        })
        
    }

    
    override func viewWillAppear(animated: Bool) {
        dispatch_async(dispatch_get_main_queue(), {
                self.navigationController!.setNavigationBarHidden(true, animated: false)
                self.thumbCollectionView.reloadData()
            })
        
        dispatch_async(self.sessionQueue, {
            
            self.addObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", options: [.Old , .New] , context: &SessionRunningAndDeviceAuthorizedContext)
            self.addObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", options:[.Old , .New], context: &CapturingStillImageContext)
            self.addObserver(self, forKeyPath: "movieFileOutput.recording", options: [.Old , .New], context: &RecordingContext)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDeviceInput?.device)
            
            
            weak var weakSelf = self
            
            self.runtimeErrorHandlingObserver = NSNotificationCenter.defaultCenter().addObserverForName(AVCaptureSessionRuntimeErrorNotification, object: self.session, queue: nil, usingBlock: {
                (note: NSNotification?) in
                let strongSelf: CameraViewController = weakSelf!
                dispatch_async(strongSelf.sessionQueue, {
//                    strongSelf.session?.startRunning()
                    if let sess = strongSelf.session{
                        sess.startRunning()
                    }
//                    strongSelf.recordButton.title  = NSLocalizedString("Record", "Recording button record title")
                })
                
            })
            
            self.session?.startRunning()
            
            // Flash-Button aktualisieren
            self.updateFlashButton()
            
        })
        
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        self.navigationController!.setNavigationBarHidden(false, animated: animated)

        dispatch_async(self.sessionQueue, {
            
            if let sess = self.session{
                sess.stopRunning()
                
                NSNotificationCenter.defaultCenter().removeObserver(self, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDeviceInput?.device)
                NSNotificationCenter.defaultCenter().removeObserver(self.runtimeErrorHandlingObserver!)
                
                self.removeObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", context: &SessionRunningAndDeviceAuthorizedContext)
                
                self.removeObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", context: &CapturingStillImageContext)
                self.removeObserver(self, forKeyPath: "movieFileOutput.recording", context: &RecordingContext)
                
                
            }

            
            
        })
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    /*override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = AVCaptureVideoOrientation(rawValue: toInterfaceOrientation.rawValue)!
        
//        if let layer = self.previewView.layer as? AVCaptureVideoPreviewLayer{
//            layer.connection.videoOrientation = self.convertOrientation(toInterfaceOrientation)
//        }
        
    }*/
    
    override func shouldAutorotate() -> Bool {
        //UIDevice.currentDevice().orientation
        return false
    }
    
//    observeValueForKeyPath:ofObject:change:context:
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        

        
        if context == &CapturingStillImageContext{
            let isCapturingStillImage: Bool = change![NSKeyValueChangeNewKey]!.boolValue
            if isCapturingStillImage {
                self.runStillImageCaptureAnimation()
            }
            
        }else if context  == &RecordingContext{
            let isRecording: Bool = change![NSKeyValueChangeNewKey]!.boolValue
            
            dispatch_async(dispatch_get_main_queue(), {
                
                if isRecording {
                    //self.recordButton.titleLabel!.text = "Stop"
                    //self.recordButton.enabled = true
//                    self.snapButton.enabled = false
                    self.takeButton.enabled = false
                    
                }else{
//                    self.snapButton.enabled = true

                    //self.recordButton.titleLabel!.text = "Record"
                    //self.recordButton.enabled = true
                    self.takeButton.enabled = true
                    
                }
                
                
            })
            
            
        }
        
        else{
            return super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
        
    }
    
    
    // MARK: Selector
    func subjectAreaDidChange(notification: NSNotification){
        let devicePoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
        self.focusWithMode(AVCaptureFocusMode.ContinuousAutoFocus, exposureMode: AVCaptureExposureMode.ContinuousAutoExposure, point: devicePoint, monitorSubjectAreaChange: false)
    }
    
    // MARK:  Custom Function
    
    func focusWithMode(focusMode:AVCaptureFocusMode, exposureMode:AVCaptureExposureMode, point:CGPoint, monitorSubjectAreaChange:Bool){
        
        dispatch_async(self.sessionQueue, {
            let device: AVCaptureDevice! = self.videoDeviceInput!.device
  
            do {
                try device.lockForConfiguration()
                
                if device.focusPointOfInterestSupported && device.isFocusModeSupported(focusMode){
                    device.focusMode = focusMode
                    device.focusPointOfInterest = point
                }
                if device.exposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode){
                    device.exposurePointOfInterest = point
                    device.exposureMode = exposureMode
                }
                device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
                
            }catch{
                print(error)
            }
            


            
        })
        
    }
    
    /// Beim Druck auf Flash-Buuton(/Toogle)
    @IBAction func flashButtonPressed(sender: AnyObject) {
        
        
        if let videoDeviceInput = self.videoDeviceInput {
            if let captureDevice = videoDeviceInput.device {
                // Camera sperren (um zu verhindern dass parallel durch andere Apps der Flash benutzt wird, zb Taschenlampe)
                do {
                    try captureDevice.lockForConfiguration() // (sperren)
                } catch let error as NSError {
                    print("Capture Device can't locked")
                    print(error.description)
                }
                
                // Abfrage ob Flash ueberhaupt zur Verfuegung steht (zb Selfiecam)
                if captureDevice.hasFlash && captureDevice.flashMode == AVCaptureFlashMode.Off {
                    captureDevice.flashMode = AVCaptureFlashMode.On;
                } else if captureDevice.hasFlash {
                    captureDevice.flashMode = AVCaptureFlashMode.Off;
                } else { // Fall im Grunde nicht erlaubt (Fehlervermeidung)
                    print("Flashmode was in illegal state")
                    captureDevice.flashMode = AVCaptureFlashMode.Off; // (default)
                }
                
                // TODO ...AVCaptureFlashMode.Auto implementieren
                
                // Camera entsperren
                captureDevice.unlockForConfiguration()
                
                // Flash-Button aktualisieren
                self.updateFlashButton()
                
            } else {
                print("Capture Device can not be determined!")
            }
        } else {
            print("videoDeviceInput is not set!")
        }
        
        
        
    }
    
    /// Dient dazu aussehen des FlashButtons zu aktualisieren
    func updateFlashButton() {
        // Code auf main-Thread ausführen (generell wichtig bei UI-Elementen)
        dispatch_async(dispatch_get_main_queue(), {
        if let videoDeviceInput = self.videoDeviceInput {
            if let captureDevice = videoDeviceInput.device {
                if !captureDevice.hasFlash {
                    self.flashButton.hidden = true
                } else if captureDevice.flashMode == AVCaptureFlashMode.Off {
                    self.flashButton.hidden = false
                    self.flashButton.setImage(UIImage(named: "CameraButton_Flash_Off"), forState: .Normal)
                } else {
                    self.flashButton.hidden = false
                    self.flashButton.setImage(UIImage(named: "CameraButton_Flash_On"), forState: .Normal)
                }
            } else {
                print("captureDevice can not be determined!")
            }
        } else {
            print("videoDeviceInput is not set!")
        }
        })
    }
    
    class func setFlashMode(flashMode: AVCaptureFlashMode, device: AVCaptureDevice){
        
        if device.hasFlash && device.isFlashModeSupported(flashMode) {
            var error: NSError? = nil
            do {
                try device.lockForConfiguration()
                device.flashMode = flashMode
                device.unlockForConfiguration()
                
            } catch let error1 as NSError {
                error = error1
                print(error)
            }
        }
        
    }
    
    /// Animation bei erzeugen eines Bildes machen ('Blitz'-Effekt)
    func runStillImageCaptureAnimation(){
        // Animation auf Main Thread abspielen
        dispatch_async(dispatch_get_main_queue(), {
            self.previewView.layer.opacity = 0.0 // (nicht sichtbar, also weiss wegen Hintergrund)
            // Animation auf Wert
            UIView.animateWithDuration(0.25, animations: {
                self.previewView.layer.opacity = 1.0 // (voll sichtbar)
            })
        })
    }
    
    class func deviceWithMediaType(mediaType: String, preferringPosition:AVCaptureDevicePosition)->AVCaptureDevice{
        
        var devices = AVCaptureDevice.devicesWithMediaType(mediaType);
        var captureDevice: AVCaptureDevice = devices[0] as! AVCaptureDevice;
        
        for device in devices{
            if device.position == preferringPosition{
                captureDevice = device as! AVCaptureDevice
                break
            }
        }
        
        return captureDevice
        
        
    }
    
    /// Checkt ob User App berechtigt hat auf Camera zuzugreifen
    func checkDeviceAuthorizationStatus() {
        
        // Berechtigungstyp: Camera
        let mediaType:String = AVMediaTypeVideo;
        
        
        // Berechtigung abfragen
        AVCaptureDevice.requestAccessForMediaType(mediaType,
             // Completionhandler (wird nach erhalt der Info ausgefuert)
            completionHandler: { (granted: Bool) in
            
            // Berechtigung gegeben
            if granted {
                self.deviceAuthorized = true; // (Property setzen)
            }else{
                // Alert auf main-Thread ausgeben
                dispatch_async(dispatch_get_main_queue(), {
                    // Alert anzeigen
                    let alert: UIAlertController = UIAlertController(
                                                        title: "Permissions required :/",
                                                        message: "Please enable camera permissions\nPreferences/Privacy/Camera/I might need App",
                                                        preferredStyle: UIAlertControllerStyle.Alert);
                    let action: UIAlertAction = UIAlertAction(title: "ok", style: UIAlertActionStyle.Default, handler: {
                        (action2: UIAlertAction) in
                        exit(0);
                    } );
                    alert.addAction(action);
                    self.presentViewController(alert, animated: true, completion: nil);
                })
                
                self.deviceAuthorized = false; // (Property setzen)
            }
        })
    }
   
    /// Foto schiessen und Snap speichern
    @IBAction func snapStillImage(sender: AnyObject) {
        print("snapStillImage")
        
        dispatch_async(self.sessionQueue, {
            // Update the orientation on the still image output video connection before capturing.
            
            //let videoOrientation = (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation
            let videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
            
            /*
            
            (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = AVCaptureVideoOrientation(rawValue: toInterfaceOrientation.rawValue)!
            
            //        if let layer = self.previewView.layer as? AVCaptureVideoPreviewLayer{
            //            layer.connection.videoOrientation = self.convertOrientation(toInterfaceOrientation)
            //        }
            
            }*/
            
            self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo).videoOrientation = videoOrientation
            
            self.stillImageOutput!.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo), completionHandler: {
                (imageDataSampleBuffer: CMSampleBuffer!, error: NSError!) in
                
                // Wenn es keinen Fehler gab
                if error == nil {
                    
                    // Snap einpflegen
                    let data:NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer) // (Bild abtasten)
                    let image:UIImage = UIImage(data: data)! // (Foto in UIImage packen)
                    DatabaseManager.createSnap(photo: image) // (neues Bild an DatabaseManager übergeben)
                    DatabaseManager.save() // (speichern)
                    
                    
                    // Collectionview updaten
                    dispatch_async(dispatch_get_main_queue(), {
                        self.thumbCollectionView.reloadData()
                    })
                    self.scrollToEnd()
                    
                    
                    
                    
                    //UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData), nil, nil, nil)
                    /*
                    let libaray:ALAssetsLibrary = ALAssetsLibrary()
                    let orientation: ALAssetOrientation = ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!
                    libaray.writeImageToSavedPhotosAlbum(image.CGImage, orientation: orientation, completionBlock: nil)
                    */
                    
                    
                } else {
                    print("Image could not be captured!")
                    print(error)
                }
            })
        })
        MainScreenViewController.jumpToIndex = Int.max
    }
    
    @IBAction func changeCamera(sender: AnyObject) {
        print("change camera")
        
        // Buttons deaktivieren
        self.switchCameraButton.enabled = false
        self.takeButton.enabled = false
        
        dispatch_async(self.sessionQueue, {
            
            let currentVideoDevice:AVCaptureDevice = self.videoDeviceInput!.device
            let currentPosition: AVCaptureDevicePosition = currentVideoDevice.position
            var preferredPosition: AVCaptureDevicePosition = AVCaptureDevicePosition.Unspecified
            
            switch currentPosition{
            case AVCaptureDevicePosition.Front:
                preferredPosition = AVCaptureDevicePosition.Back
            case AVCaptureDevicePosition.Back:
                preferredPosition = AVCaptureDevicePosition.Front
            case AVCaptureDevicePosition.Unspecified:
                preferredPosition = AVCaptureDevicePosition.Back
                
            }
            

            
            let device:AVCaptureDevice = CameraViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: preferredPosition)
            
            var videoDeviceInput: AVCaptureDeviceInput?
            
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: device)
            } catch _ as NSError {
                videoDeviceInput = nil
            } catch {
                fatalError()
            }
            
            self.session!.beginConfiguration()
            
            self.session!.removeInput(self.videoDeviceInput)
            
            if self.session!.canAddInput(videoDeviceInput){
       
                NSNotificationCenter.defaultCenter().removeObserver(self, name:AVCaptureDeviceSubjectAreaDidChangeNotification, object:currentVideoDevice)
                
                //CameraViewController.setFlashMode(AVCaptureFlashMode.Auto, device: device)
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: device)
                                
                self.session!.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
            }else{
                self.session!.addInput(self.videoDeviceInput)
            }
            
            self.session!.commitConfiguration()
            

            
            dispatch_async(dispatch_get_main_queue(), {
                self.switchCameraButton.enabled = true
                self.takeButton.enabled = true
                
                // Flash-Button aktualisieren
                self.updateFlashButton()
            })
            
        })

        
        
        
    }
    
    @IBAction func focusAndExposeTap(gestureRecognizer: UIGestureRecognizer) {
        
        print("focusAndExposeTap")
        let devicePoint: CGPoint = (self.previewView.layer as! AVCaptureVideoPreviewLayer).captureDevicePointOfInterestForPoint(gestureRecognizer.locationInView(gestureRecognizer.view))
        
        print(devicePoint)
        
        self.focusWithMode(AVCaptureFocusMode.AutoFocus, exposureMode: AVCaptureExposureMode.AutoExpose, point: devicePoint, monitorSubjectAreaChange: true)
        
    }
    
    // === Collectionview ===
    
    @IBOutlet weak var thumbCollectionView: UICollectionView!
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width:47, height:47);
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let msvc:MainScreenViewController = CameraViewController.msvc {
            return msvc.collectionView(collectionView, numberOfItemsInSection: section) - 2
        } else {
            print("msvc is not set!")
            return 0;
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let msvc:MainScreenViewController = CameraViewController.msvc {
            let cell = msvc.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
            if let thumbCell = cell as? ThumbViewCell {
                thumbCell.imageView.layer.cornerRadius = 3.5;
                thumbCell.imageView.layer.masksToBounds = true;
            }
            return cell
        } else {
            assert(false, "msvc is not set! Can't create a cell")
        }
    }
    
    func scrollToEnd() {
        
        dispatch_async(dispatch_get_main_queue(), {
            
            self.thumbCollectionView?.contentInset = UIEdgeInsetsZero;
            let item = self.collectionView(self.thumbCollectionView!, numberOfItemsInSection: 0) - 1
            if item > 0 {
                let lastItemIndex = NSIndexPath(forItem: item, inSection: 0)
                self.thumbCollectionView?.scrollToItemAtIndexPath(lastItemIndex, atScrollPosition: UICollectionViewScrollPosition.Right, animated: true)
            }
            
        });
    }
    
    /// Wird bei Tap auf Ellement von CollectionView aufgerufen
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
            
        print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
        if let msvc:MainScreenViewController = CameraViewController.msvc {
            if indexPath.item < msvc.numberOfItems {
                self.displayingSnapIndex = msvc.numberOfItems - indexPath.item - 1
                self.performSegueWithIdentifier("showSnapFromCamera", sender: nil)
            }
        } else {
            print("msvc is not set!")
        }
    }
    
    /// Index von Snap der angezeigt werden soll.
    var displayingSnapIndex:Int? = nil
    
    /**
     Wird bei Tap auf Bild aufgerufen
     @param index Dies ist der Index des Snap. Nicht der CollectionviewCell!
     */
    func showSnap(index: Int) {
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let photoScrollViewController:PhotoScrollViewController = segue.destinationViewController as? PhotoScrollViewController {
            photoScrollViewController.desiredStartupSnap = self.displayingSnapIndex
        }
    }
}

