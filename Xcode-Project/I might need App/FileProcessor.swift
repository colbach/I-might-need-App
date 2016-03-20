//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
import UIKit

class FileProcessor {
    
    // === Debugging-Hilfen ===
    
    /**
        zugehörig zu log(String)
        Entscheidet ob log verworfen oder ausgegeben wird
    */
    private static var printLog = false
    
    /**
        zugehörig zu printLog:Bool
        logt Operationen auf Dateisystem da die Möglichkeit der Analyse wichtig ist
        (Aus debugging-Zwecken, damit ich das leicht an und ausschalten kann)
    */
    private static func log(infoString : String) {
        if printLog { // log wird ausgegeben
            print(infoString)
        } // else: log wird verworfen
    }
    
    // === Hilfs-Attribute ===
    
    /**
        Ordner von welchem bei der speicherung von daten ausgegangen werden soll
        ACHTUNG: Pfad muss mit einem "/" enden!
    */
    private static var documentsRoot : String? = {
            let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            if (paths.count > 0) {
                let dd = (paths[0]).stringByAppendingString("/")
                FileProcessor.log("[INFO] documentsRoot=\"\(dd)\"")
                return dd
            } else {
                FileProcessor.log("[FAILED] documentsRoot is unclear")
                return nil
            }
        }()
    
    /**
     Ordner von welchem bei der speicherung von temporaeren Daten ausgegangen werden soll
     ACHTUNG: Pfad muss mit einem "/" enden!
     */
    private static var cacheRoot : String? = {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        if (paths.count > 0) {
            let dd = (paths[0]).stringByAppendingString("/")
            FileProcessor.log("[INFO] cacheRoot=\"\(dd)\"")
            return dd
        } else {
            FileProcessor.log("[FAILED] cacheRoot is unclear")
            return nil
        }
    }()
    
    // === Laden ===
    
    internal static func loadUIImage(filename filename : String, folder : String) -> UIImage? {
        return loadUIImage(filename : "\(folder)/\(filename)")
    }
    
    internal static func loadUIImage(filename filename : String) -> UIImage? {
        if documentsRoot != nil {
            let image = loadUIImage(path : documentsRoot!.stringByAppendingString(filename))
            if image != nil {
                return image
            }
        } else {
            log("[FAILED] Faled to load \(filename) because documentDirectory is unclear")
        }
        return nil
    }
    
    internal static func loadUIImageFromCache(filename filename : String, folder : String) -> UIImage? {
        return loadUIImageFromCache(filename : "\(folder)/\(filename)")
    }
    
    internal static func loadUIImageFromCache(filename filename : String) -> UIImage? {
        if documentsRoot != nil {
            let image = loadUIImage(path : cacheRoot!.stringByAppendingString(filename))
            if image != nil {
                return image
            }
        } else {
            log("[FAILED] Faled to load \(filename) because cacheRoot is unclear")
        }
        return nil
    }
    
    private static func loadUIImage(path path : String) -> UIImage? {
        
        let image = UIImage(contentsOfFile: path)
    
        if image != nil {
            log("[SUCCESS] UIImage loaded from: \(path)")
        } else {
            log("[FAILED] Failed to load UIImage from: \(path)")
        }
        return image
    }
    
    // === Speichern ===
    
    internal static func saveUIImageAsJPEGToCache(image : UIImage, quality : Float, filename : String, folder : String) -> Bool {
        if documentsRoot != nil {
            let folderPath = cacheRoot!.stringByAppendingString("\(folder)/")
            var error:NSError?
            if (!NSFileManager.defaultManager().fileExistsAtPath(folderPath)) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: false, attributes: nil)
                } catch let error1 as NSError {
                    error = error1
                }
            }
            if error != nil {
                print(error)
                log("[FAILED] Faled to create folder \(folderPath)")
                return false
            } else {
                return saveUIImageAsJPEG(image, quality: quality, path : folderPath.stringByAppendingString(filename))
            }
        } else {
            log("[FAILED] Faled to save \(filename) because cacheRoot is unclear")
            return false
        }
    }
    
    internal static func saveUIImageAsJPEGToCache(image : UIImage, quality : Float, filename : String) -> Bool {
        if documentsRoot != nil {
            return saveUIImageAsJPEG(image, quality: quality, path : cacheRoot!.stringByAppendingString(filename))
        } else {
            log("[FAILED] Faled to save \(filename) because cacheRoot is unclear")
            return false
        }
    }
    
    internal static func saveUIImageAsJPEG(image : UIImage, quality : Float, filename : String, folder : String) -> Bool {
        if documentsRoot != nil {
            let folderPath = documentsRoot!.stringByAppendingString("\(folder)/")
            var error:NSError?
            if (!NSFileManager.defaultManager().fileExistsAtPath(folderPath)) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: false, attributes: nil)
                } catch let error1 as NSError {
                    error = error1
                }
            }
            if error != nil {
                print(error)
                log("[FAILED] Faled to create folder \(folderPath)")
                return false
            } else {
                return saveUIImageAsJPEG(image, quality: quality, path : folderPath.stringByAppendingString(filename))
            }
        } else {
            log("[FAILED] Faled to save \(filename) because documentsRoot is unclear")
            return false
        }
    }

    internal static func saveUIImageAsJPEG(image : UIImage, quality : Float, filename : String) -> Bool {
        if documentsRoot != nil {
            return saveUIImageAsJPEG(image, quality: quality, path : documentsRoot!.stringByAppendingString(filename))
        } else {
            log("[FAILED] Faled to save \(filename) because documentsRoot is unclear")
            return false
        }
    }
    
    private static func saveUIImageAsJPEG(image : UIImage,
        quality : Float, path : String) -> Bool {
        let imageData:NSData = UIImageJPEGRepresentation(image, CGFloat(quality))!
        let result = imageData.writeToFile(path, atomically:true)
        if result {
            log("[SUCCESS] UIImage saved to: \(path)")
        } else {
            log("[FAILED] Faled to save UIImage to: \(path)")
        }
        return result
        
    }
    
    // === Existenz ===
    
    internal static func fileExistsInCache(filename filename : String, folder : String) -> Bool? {
        return fileExistsInCache(filename : "\(folder)/\(filename)")
    }
    
    internal static func fileExistsInCache(filename filename : String) -> Bool? {
        if documentsRoot != nil {
            return fileExists(path: cacheRoot!.stringByAppendingString(filename))
        } else {
            return nil
        }
        
    }
    
    internal static func fileExists(filename filename : String, folder : String) -> Bool? {
        return fileExists(filename : "\(folder)/\(filename)")
    }
    
    internal static func fileExists(filename filename : String) -> Bool? {
        if documentsRoot != nil {
            return fileExists(path: documentsRoot!.stringByAppendingString(filename))
        } else {
            return nil
        }
        
    }
    
    private static func fileExists(path path : String) -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(path)
    }
    
    // === Löschen ===
    
    internal static func deleteFileFromCache(filename filename : String, folder : String) -> Bool {
        return deleteFileFromCache(filename : "\(folder)/\(filename)")
    }
    
    internal static func deleteFileFromCache(filename filename : String) -> Bool {
        if documentsRoot != nil {
            return deleteFile(path: cacheRoot!.stringByAppendingString(filename))
        } else {
            log("[FAILED] Faled to delete \(filename) because cacheRoot is unclear")
            return false
        }
    }
    
    internal static func deleteFile(filename filename : String, folder : String) -> Bool {
        return deleteFile(filename : "\(folder)/\(filename)")
    }
    
    internal static func deleteFile(filename filename : String) -> Bool {
        if documentsRoot != nil {
            return deleteFile(path: documentsRoot!.stringByAppendingString(filename))
        } else {
            log("[FAILED] Faled to delete \(filename) because documentsRoot is unclear")
            return false
        }
    }
    
    private static func deleteFile(path path : String) -> Bool {
        var error:NSError?
        let result: Bool
        do {
            try NSFileManager.defaultManager().removeItemAtPath(path)
            result = true
        } catch let error1 as NSError {
            error = error1
            result = false
        }
        if result {
            log("[SUCCESS] UIImage deleted from: \(path)")
        } else {
            log("[SUCCESS] Faled to delete UIImage from: \(path)")
        }
        if error != nil {
            print(error)
        }
        return result;
    }
    
    // === Andere Methoden ===
    
    internal static func sizeForLocalFile(filename filename : String, folder : String) -> UInt64 {
        return sizeForLocalFile(filename : "\(folder)/\(filename)")
    }
    
    internal static func sizeForLocalFile(filename filename : String) -> UInt64 {
        if documentsRoot != nil {
            return sizeForLocalFile(path : documentsRoot!.stringByAppendingString(filename))
        } else {
            log("[FAILED] Faled to to get filesize \(filename) because documentDirectory is unclear")
        }
        return 0
    }
    
    internal static func sizeForLocalFile(path path:String) -> UInt64 {
        do {
            let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
            if let fileSize = fileAttributes[NSFileSize]  {
                return (fileSize as! NSNumber).unsignedLongLongValue
            } else {
                log("[FAILED] Failed to get a size attribute from path: \(path)")
            }
        } catch {
            log("[FAILED] Failed to get file attributes for local path: \(path)")
            print(error)
        }
        return 0
    }
}