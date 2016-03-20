//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
import CoreData
import UIKit

/// Diese Klasse representiert ein Step in welcher Snaps gesammelt sind.
class Step: NSManagedObject {
    
    // =======================
    // === COREDATA-FELDER ===
    // =======================
    
    /// Stufe. 0 ist aktuell und 2 ist unaktuell
    @NSManaged var index: Int16
    
    /// Maximale Anzahl von Snaps die mit dieser Stufe verbunden sind. Int32.max bedeutet keine Begrenzung
    @NSManaged var maxSnapCount: Int32
    
    /**
        Erwartete Qualität auf dieser Stufe. Notation: "very high"
        desiredQualityIndicatorString muss  Legaler Notationsstring
    */
    @NSManaged var desiredQualityIndicatorString: String?
    
    /**
        Array welches verbundene Snaps enthält.
        ACHTUNG: Reihenfolge ist wichtig, da Elemente keinen eigenen Index enthalten.
                DIESE LISTE IST AUFSTEIGEND SORTIERT!!!
                DAS LETZTE ELEMEND ENTSPRICHT DEM ELEMENT MIT DEM KLEINSTEN GLOBALEN INDEX
                Der Grund für diese Sortierung liegt in der einfacheren Verwaltung innerhalb von CoreData
    */
    @NSManaged var containingSnaps: [Snap]
    
    
    // ===========================
    // === COMPUTED PROPERTIES ===
    // ===========================
    
    // Gibt Anzahl verbundener Snaps zurück
    var snapCount : Int {
        return containingSnaps.count
    }
    
    // Gibt eine Übersicht der Stufe zurück
    var overview : String {
        var desiredQualityString:String
        if (desiredQualityIndicatorString != nil) {
            desiredQualityString = "desiredQualityIndicator=\"\(desiredQualityIndicatorString!)\""
        } else {
            desiredQualityString = "desiredQuality=nil"
        }
        var output = "Step: index=\(index) \(desiredQualityString) snapCount=\(snapCount) maxSnapCount=\(maxSnapCount)"
        for var i=containingSnaps.count-1; i>=0; i-- {
            output += "\n\t[\(i)] \(containingSnaps[i].overview)"
        }
        return output
    }
    
    
    // ================
    // === METHODEN ===
    // ================
    
    /// Funktion erzeugt neuen Snap und fügt ihn in jeweiligen Step
    internal func createSnap(photo photo: UIImage) -> Snap {
        let snap = NSEntityDescription.insertNewObjectForEntityForName("Snap", inManagedObjectContext: self.managedObjectContext!) as! Snap
        let actualDate = NSDate()
        snap.creationDate = actualDate
        snap.qualityIndicatorString = desiredQualityIndicatorString
        snap.image = photo
        snap.pushDate = actualDate
        snap.actualStep = self
        return snap
    }
    
    /// Funktion erzeugt neuen Snap und fügt ihn in jeweiligen Step
    internal func createSnap(photoIdentifier photoIdentifier: String) -> Snap {
        let snap = NSEntityDescription.insertNewObjectForEntityForName("Snap", inManagedObjectContext: self.managedObjectContext!) as! Snap
        snap.photoIdentifier = photoIdentifier
        let actualDate = NSDate()
        snap.creationDate = actualDate
        snap.qualityIndicatorString = desiredQualityIndicatorString
        snap.pushDate = actualDate
        snap.actualStep = self
        return snap
    }
    
    // Gibt Übersicht der Stufe aus
    func printOverview() {
        print(overview)
    }
}
