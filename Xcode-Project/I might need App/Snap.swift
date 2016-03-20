//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
import CoreData
import UIKit

/// Diese Klasse representiert ein Snap.
class Snap: NSManagedObject {

    // =======================
    // === COREDATA-FELDER ===
    // =======================
    
    /// Datum der Erstellung dieses Snaps
    @NSManaged var creationDate: NSDate?
    
    /**
        Dateiname der zugehörigen JPEG-Datei
        ACHTUNG: photoIdentifier sollte NIEMALS manuel geändert werden. Das dazugehörige Bild kann dann NICHT mehr gefunden werden!
    */
    @NSManaged var photoIdentifier: String?
    
    /// Datum wann das Bild das letzte mal gepusht wurde
    @NSManaged var pushDate: NSDate?
    
    /**
        Die Qualitätsstufe des gespeicherten Bildes.
        ACHTUNG: Änderung muss über applyNewQualityIndicator(String) gemacht werden!
    */
    @NSManaged var qualityIndicatorString: String?
    
    /// Pfad der Vorschau falls diese Existiert
    @NSManaged var thumbIdentifier: String?
    
    /// Aktuelle Stufe. Um Stufe von Snap zu ändern, reicht es diesen Pointer zu ändern
    @NSManaged var actualStep: Step
    
    
    // ===========================
    // === COMPUTED PROPERTIES ===
    // ===========================
    
    var thumbnail: UIImage? {
        get {
            if photoIdentifier != nil && FileProcessor.fileExistsInCache(filename: photoIdentifier!, folder: Snap.thumbnailFolder) == true { // Thumbnail existiert bereits
                return FileProcessor.loadUIImageFromCache(filename: photoIdentifier!, folder: Snap.thumbnailFolder)
            } else if photoIdentifier != nil { // Thumbnail existiert noch nicht (erster aufruf
                print("No Thumbnail found. Create new Thumbnail.")
                // --- Thumbnail erzeugen ---
                if let edge = ThumbViewCell.getEdgeInPoints(Int(actualStep.index)) {
                    let srcImage = image!
                    let scale = Float(edge) / Float(min(srcImage.size.width, srcImage.size.height))
                    let width = CGFloat(Float(srcImage.size.width) * scale)
                    let height = CGFloat(Float(srcImage.size.height) * scale)
                    let thumbnailSize: CGSize = CGSize(width: edge, height: edge)
                    UIGraphicsBeginImageContextWithOptions(thumbnailSize, true, 0.0)
                    var transX:CGFloat = 0
                    var transY:CGFloat = 0
                    if(width > edge) {
                        transX = (CGFloat(edge - CGFloat(width)) / CGFloat(2))
                    } else if(height > edge) {
                        transY = (CGFloat(edge - CGFloat(height)) / CGFloat(2))
                    }
                    srcImage.drawInRect(CGRectMake(transX, transY, width, height))
                    let thumbnail: UIImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    FileProcessor.saveUIImageAsJPEGToCache(thumbnail, quality: 0.5, filename: photoIdentifier!, folder: Snap.thumbnailFolder)
                    // ---
                    return thumbnail
                }
            }
            return nil
        }
    }
    
    /**
        UIImage welches über den photoIdentifier:String? verbunden ist.
        ACHTUNG: qualityIndicatorString muss gesetzt sein
        ACHTUNG: Um keine Inkonsistenz innerhalb der Datenbank zu erzeugen sollte actualDate vorher gesetzt sein
        ACHTUNG: Es handelt sich hierbei um eine computed properties welche eine Reihe von calls auslöst. Es findet kein caching stadt!
    */
    var image: UIImage? {
        get {
            if photoIdentifier != nil {
                if let image = FileProcessor.loadUIImage(filename: photoIdentifier!) {
                    return image
                }
            } else {
                print("photoIdentifier ist nil")
            }
            // Fallback
            let path = NSBundle.mainBundle().pathForResource("fallback-image", ofType: "gif")
            let fallbackImage = UIImage(contentsOfFile: path!)
            return fallbackImage
        }
        set {
            if(newValue == nil) { // Wenn neuer Wert nil. Dann soll Foto gelöscht werden
                if photoIdentifier != nil {
                    FileProcessor.deleteFile(filename: photoIdentifier!)
                    FileProcessor.deleteFileFromCache(filename: photoIdentifier!, folder: Snap.thumbnailFolder)
                    photoIdentifier = nil
                }
            } else {
                autoreleasepool { // (loest Bug bei welchem Memory nicht schnell genug freigegeben wurde)
                    var largestEdgeLength:Int = 2592  // Diese Werte sind nur um Fehler zu evitieren
                    var compressionQuality:Float = 0.7 //
                    if photoIdentifier == nil {
                        if creationDate == nil {
                            creationDate = NSDate()
                        }
                        photoIdentifier = Snap.getNewPhotoIdentifier(creationDate!)
                    }
                    if(qualityIndicatorString != nil) {
                        if let param = QualityModel.getTechnicalParametersForQualityIndicator(qualityIndicatorString!) {
                            largestEdgeLength = param.largestEdgeLength
                            compressionQuality = param.compressionQuality
                        } else {
                            print("WARNING: qualityIndicatorString is not a legal qualityIndicator!")
                        }
                    } else {
                        print("WARNING: qualityIndicatorString is not set!")
                    }
                    // --- Skalierung ---
                    let scale = Float(largestEdgeLength) / Float(max(newValue!.size.width, newValue!.size.height))
                    let width = Int(Float(newValue!.size.width) * scale)
                    let height = Int(Float(newValue!.size.height) * scale)
                    var scaledImage:UIImage?
                    if(width < Int(newValue!.size.width) || height < Int(newValue!.size.height)) {
                        let size = CGSize(width: width, height: height)
                        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
                        newValue!.drawInRect(CGRect(origin: CGPointZero, size: size))
                        scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                    } else {
                        print("Original Image is smaller than claimed")
                        scaledImage = newValue
                    }
                
                    if photoIdentifier == nil {
                        photoIdentifier = Snap.getNewPhotoIdentifier()
                    }
                    FileProcessor.saveUIImageAsJPEG(scaledImage!, quality: compressionQuality, filename: photoIdentifier!)
                }
            }
        }
    }
    
    /**
        Bildbreite in Pixel
        ACHTUNG: Es handelt sich hierbei um eine computed properties welche eine Reihe von calls auslöst. Es findet kein caching stadt!
     */
    var widthInPixels: Int {
        get {
            if let image = self.image {
                return Int(image.size.width * image.scale)
            } else {
                print("image ist nil!")
                return -1
            }
        }
    }
    
    /**
        Bildhoehe in Pixel
        ACHTUNG: Es handelt sich hierbei um eine computed properties welche eine Reihe von calls auslöst. Es findet kein caching stadt!
    */
    var heigthInPixels: Int {
        get {
            if let image = self.image {
                return Int(image.size.height * image.scale)
            } else {
                print("image ist nil!")
                return -1
            }
        }
    }
    
    /**
        Bildhoehe in Pixel
        ACHTUNG: Es handelt sich hierbei um eine computed properties welche eine Reihe von calls auslöst. Es findet kein caching stadt!
    */
    var sizehInPixelsString: String {
        get {
            if let image = self.image {
                return "\(Int(image.size.width * image.scale)) x \(Int(image.size.height * image.scale))"
            } else {
                print("image ist nil!")
                return "indeterminable"
            }
        }
    }
    
    /**
        creationDate als formatierten String nach folgendem Schema: "yyyy-MM-dd hh:mma"
        BEISPIEL: "2015-06-13 21:44"
    */
    var creationDateString: String {
        get {
            if creationDate != nil {
                return Snap.dateFormatter.stringFromDate(creationDate!)
            } else {
                return "Date not set"
            }
        }
        set {
            creationDate = Snap.dateFormatter.dateFromString(newValue)
        }
    }
    
    // Dateigrösse in byte zuruek
    var fileSize: Int {
        get {
            if photoIdentifier != nil {
                return Int(FileProcessor.sizeForLocalFile(filename: photoIdentifier!))
            } else {
                print("photoIdentifier ist nil")
                return -1
            }
        }
    }
    
    // Dateigrösse lesbar zuruek
    var fileSizeString: String {
        get {
            let kb = Int(self.fileSize/1024)
            if kb < 1024 {
                return "\(kb) Kilobytes"
            } else {
                let mbMultiplyedWith10 = Int((Float(self.fileSize)/1024.0/1024.0)*10)
                return "\(Float(mbMultiplyedWith10)/10) Megabytes"
            }
        }
    }
    
    
    /// pushDate als formatierten String nach folgendem Schema: "yyyy-MM-dd hh:mma"
    var pushDateString: String {
        get {
            if pushDate != nil {
                return Snap.dateFormatter.stringFromDate(pushDate!)
            } else {
                return "Date not set"
            }
        }
        set {
            pushDate = Snap.dateFormatter.dateFromString(newValue)
        }
    }
    
    /// Ermittelt zugehörige Stufe
    var stepIndex : Int16 {
        return actualStep.index
    }
    
    /// Ermittelt ob bereits eine Vorschau für dieses Snap existiert oder ob dieses noch erzeugt werden muss
    var thumbLinked : Bool {
        return thumbIdentifier != nil
    }
    
    /**
        Gibt eine Übersicht des Snaps zurück
        Ausgabe soll wie folgt aussehen: "Snap: photoIdentifier="/marco/polo.jpg" quality="XHD" thumbLinked=true"
    */
    var overview : String {
        var photoIdentifierString:String
        if (photoIdentifier != nil) {
            photoIdentifierString = "photoIdentifier=\"\(photoIdentifier!)\""
        } else {
            photoIdentifierString = "photoIdentifier=nil"
        }
        var qualityString:String
        if (qualityIndicatorString != nil) {
            qualityString = "qualityIndicator=\"\(qualityIndicatorString!)\""
        } else {
            qualityString = "qualityIndicator=nil"
        }
        return "Snap: \(photoIdentifierString) \(qualityString) stepIndex=\(stepIndex) thumbLinked=\(thumbLinked) creationDateString=\"\(creationDateString)\""
    }
    
    
    // ================
    // === METHODEN ===
    // ================
    
    /// ACHTUNG: Diese Methode MUSS beim löschen aufgerufen werden!
    func destroy() {
        if let identifier = self.photoIdentifier {
            self.photoIdentifier = nil
            FileProcessor.deleteFile(filename: identifier)
            FileProcessor.deleteFileFromCache(filename: identifier, folder: Snap.thumbnailFolder)
        }
    }
    
    
    /**
        Diese Methode dient zur Aktualisierung von quality.
        @return true    wenn QualityIndicator gesetzt wird.
                false   wenn QualityIndicator höher als bestehender QualityIndicator ist.
                nil     wenn es sich nicht um einen erlaubten QualityIndicator handelt.
    */
    func applyNewQualityIndicator(newQualityIndicatorString : String) -> Bool? {
        if !QualityModel.isLegalQualityIndicatorString(newQualityIndicatorString) {
            return nil
        } else if qualityIndicatorString == nil {
            qualityIndicatorString = newQualityIndicatorString
            return true
        } else if QualityModel.compare(newQualityIndicatorString, to: qualityIndicatorString!) > 0{
            qualityIndicatorString = newQualityIndicatorString
            updateImageData()
            return true
        }
        return false
    }
    
    /// aktualisiert JPG-Datei von Photo
    private func updateImageData() {
        let img = image
        image = img
    }
    
    /// Gibt Übersicht des Snaps aus
    func printOverview() {
        print(overview)
    }
    
    
    /// Erzeugt einen legalen Dateinamen für ein Photo
    private static func getNewPhotoIdentifier() -> String {
        return getNewPhotoIdentifier(NSDate())
    }
    
    // (
    private static var countInSecond = 1 // Reines Hilfsatribut für newPhotoIdentifier() KEINE ANDERE VERWENDUNG!
    private static var dateForSecond = "" // Reines Hilfsattribut für newPhotoIdentifier() KEINE ANDERE VERWENDUNG!
    // )
    /// Erzeugt einen legalen Dateinamen für ein Photo
    internal static func getNewPhotoIdentifier(date : NSDate) -> String {
        let date = Snap.dateFormatter.stringFromDate(date)
        if Snap.dateForSecond == date {
            countInSecond += 1
        } else {
            dateForSecond = date
            countInSecond = 1
        }
        if countInSecond == 1 {
            return "\(date).jpg"
        } else {
            return "\(date) \(countInSecond).jpg"
        }
    }
    
    // ============================================
    // === STATISCHE HILFSMETHODEN & KONSTANTEN ===
    // ============================================
    
    /// Dient zur Formatierung aller in Snap verwendeten NSDates
    internal static let dateFormatter: NSDateFormatter = {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter
        }()
    
    /**
        Ordner in welchem thumbnails gespeichert werden.
        ACHTUNG: Ordner != Pfad
    */
    private static let thumbnailFolder = "Thumbs"
    
}
