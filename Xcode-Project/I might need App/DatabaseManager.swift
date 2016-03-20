//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
import CoreData
import UIKit

/// Managt persistentes Datenmodel
class DatabaseManager {
    
    /// Errorhandeling
    enum DatabaseError: ErrorType {
        case DatabaseNotInitialized
    }
    
    /// Standart Einstellungen
    static let defaultSnapCounts = [Int32(10), Int32(10), Int32(10)]
    
    /// Gibt an ob Datenbank schon existiert
    internal static func databaseExists() -> Bool {
        if let steps = self.steps {
            return steps.count != 0
        } else {
            return false
        }
    }
    
    /**
        Verbindet DatabaseManager mit CoreData-Datenbank.
        Initialisierung findet automatisch bei erstem aufruf statt.
    */
    private(set) static var managedObjectContext : NSManagedObjectContext! = {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.managedObjectContext
    }()
    
    /**
        Thread muss vor benutzung des managedObjectContext einchecken (dafuer muss Vorgaenger ausgecheckt haben)
     */
    internal static func checkin() -> Bool {
        
        if managedObjectContext == nil {
            //let coreData = CoreData(sqliteDocumentName: "I_might_need_App.db", schemaName:"I_might_need_App")
            //DatabaseManager.managedObjectContext = coreData.createManagedObjectContext()
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            managedObjectContext = appDelegate.managedObjectContext
            
            return true
        } else {
            print("managedObjectContext is busy")
            return false
        }
    }
    
    internal static func checkinForPrivateQueue() -> Bool {
        
        if managedObjectContext == nil {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            let privateContext = NSManagedObjectContext(
                concurrencyType: .PrivateQueueConcurrencyType)
            privateContext.persistentStoreCoordinator =
                appDelegate.persistentStoreCoordinator
            
            managedObjectContext = privateContext
            
            return true
        } else {
            print("managedObjectContext is busy")
            return false
        }
    }
    
    /**
        Nach benutzung von managedObjectContext auschecken.
        ACHTUNG: Vorher save() aufrufen!
     */
    internal static func checkout() {
        _steps = nil
        managedObjectContext = nil
    }
    
    
    /**
        Speichert Aenderungen in CoreData.
        ACHTUNG: Muss nach jeder Änderung aufgerufen werden damit diese persistent werden.
    */
    internal static func save() {
        var error : NSError?
        do {
            try managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
            NSLog("Error saving: %@", error!)
        }
    }
    
    /// Speichervariable von steps
    private static var _steps:[Step]? = nil
    
    /// Representtiert alle aktuell in CoreData vorhandenen Stufen.
    internal static var steps:[Step]? {
        get {
            if _steps == nil {
                let fetchedSteps = DatabaseManager.fetchSteps()
                if fetchedSteps != nil && fetchedSteps!.count == 3 {
                    _steps = fetchedSteps
                }
            }
            return _steps
        }
        set(newValue) {
            if newValue != nil && newValue!.count == 3 {
                _steps = newValue
            } else {
                _steps = nil
            }
        }
    }
    
    /// Macht ein Fetch aller Stufen in CoreData.
    private static func fetchSteps() -> [Step]? {
        let request = NSFetchRequest(entityName: "Step")
        request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        return (try? managedObjectContext.executeFetchRequest(request)) as? [Step]
    }
    
    /// Gibt Stufe
    internal static var step0 : Step? {
        get {
            if steps == nil || steps!.count < 1 {
                print("steps is nil!")
                return nil
            } else {
                return steps![0]
            }
        }
    }
    
    internal static var step1 : Step? {
        get {
            if steps == nil || steps!.count < 2 {
                print("steps is nil!")
                return nil
            } else {
                return steps![1]
            }
        }
    }
    
    internal static var step2 : Step? {
        get {
            if steps == nil || steps!.count < 3 {
                print("steps is nil!")
                return nil
            } else {
                return steps![2]
            }
        }
    }
    
    /// zählt alle Snaps innerhalb der Datenbank
    internal static var snapCount : Int {
        var count = 0
        if steps != nil {
            for step in steps! {
                count += step.containingSnaps.count
            }
        }
        return count
    }
    
/*  // Deaktiviert da nur fuer debuging
    
    /// Gesammte Datenbank wird gelöscht
    private static func clearDatabase() {
        let steps = fetchSteps()
        if steps == nil {
            for step in steps! {
                DatabaseManager.managedObjectContext.deleteObject(step)
            }
        }
    }
    
    /// Setzt die gesammte Datenbank auf ausgangszustand zurück
    internal static func resetDatabase() {
        clearDatabase();
        initDatabase()
    }
*/
    
    /**
        Initialisiert die Datenbank.
        ACHTUNG: Es dürfen keine Steps vorhanden sein!
    */
    internal static func initDatabase() {
        print("init Database")
        var ss = [Step]()
        for i:Int16 in 0...2 {
            let s = NSEntityDescription.insertNewObjectForEntityForName("Step",
                inManagedObjectContext: self.managedObjectContext) as! Step
            s.index = i
            let qualityIndicator = QualityModel.defaultQualityIndicators[Int(i)]
            s.desiredQualityIndicatorString = qualityIndicator
            var plannedSizeInMB = 0
            if i == 0 {
                plannedSizeInMB = PreferencesManager.writtenStep0PlannedSizeInMB
            } else if i == 1 {
                plannedSizeInMB = PreferencesManager.writtenStep1PlannedSizeInMB
            } else if i == 2 {
                plannedSizeInMB = PreferencesManager.writtenStep2PlannedSizeInMB
            }
            if let fittingSnaps = QualityModel.getEstimatedNumberOfSnapsFittingInStep(qualityIndicator, maximumMB: plannedSizeInMB) {
                s.maxSnapCount = Int32(fittingSnaps)
            } else {
                print("QualityModel.getEstimatedNumberOfSnapsFittingInStep(\(qualityIndicator), maximumMB: \(plannedSizeInMB) returned nil!")
                print("Cannot set s.maxSnapCount!")
            }
            // Sonderfall
            if i == 2 && PreferencesManager.writtenStep2NeverLeaveStep {
                s.maxSnapCount = INT32_MAX
            }
            ss.append(s)
        }
        steps = ss
    }
    
    /// Gibt eine Übersicht der Datenbank zurück
    internal static var overview : String {
        if steps != nil {
            var result = "DatabaseManager: snapCount=\(snapCount)"
            for(var i = 0; i<steps!.count; i++) {
                result += "\n[\(i)] \(steps![i].overview)"
            }
            return result
        } else {
            return "DatabaseManager is not initialized yet!"
        }
    }
    
    /// Gibt Übersicht der Datenbank aus
    internal static func printOverview() {
        print(overview)
        print("")
    }
    
    /// Gibt nummerierte Liste aller Snaps aus
    internal static func printSnapList() {
        var i = 0 // Nummer für globalen Index von Snaps
        for s in snaps { // Für alle Snaps
            var iString = String(i++) // String mit Nummer erzeugen
            while iString.characters.count < 3 {  // solange "0" vor Zahl hängen bis Länge 3 ist
                iString = "0" + iString //
            }
            print("[" + iString + "] " + s.overview) // Ausgabe Nummer & Übersicht von Snap
        }
        print("") // leere Zeile anhängen
    }
    
    internal static var partitionDescription:String {
        get {
            return "\(step0!.snapCount)/\(step0!.maxSnapCount) | \(step1!.snapCount)/\(step1!.maxSnapCount) | \(step2!.snapCount)/\(step2!.maxSnapCount)"
        }
    }
    
    internal static func printPartitionDescription() {
        print(partitionDescription);
    }
    
    /// Gibt alle Snaps zurück
    internal static var snaps : [Snap] {
        var array = [Snap]()
        if steps != nil {
            for step in steps! {
                array += Array(step.containingSnaps.reverse())
            }
        }
        return array
    }
    
    /// Gibt Snap anhand von globalem Index zurück
    internal static func snap(var globalIndex:Int) -> Snap? {
        if steps != nil {
            // Nach globalem Index suchen...
            var stepIndex = 0
            let steps = self.steps // Kopie von steps anlegen, damit steps nicht mehrfach gefetcht werden muss
            while stepIndex < steps!.count-1 && steps![stepIndex].snapCount <= globalIndex {
                globalIndex -= steps![stepIndex].snapCount
                stepIndex++
            }
            // Wenn globaler Index exisiert Element ausgeben
            if steps![stepIndex].snapCount > globalIndex {
                return steps![stepIndex].containingSnaps[steps![stepIndex].snapCount-1-globalIndex] // Erfolg
            } else {
                return nil // Misserfolg
            }
        } else {
            return nil // Datenbank ist nicht initialisiert
        }
    }
    
    /// Gibt count Snaps zurück welche sich ab globalem Index befinden
    internal static func snap(var globalIndex:Int, var count:Int) -> [Snap] {
        var result = [Snap]() // Ergebnis-Array anlegen
        if steps != nil {
            // Nach globalem Index suchen...
            var stepIndex = 0
            let steps = self.steps // Kopie von steps anlegen, damit steps nicht mehrfach gefetcht werden muss
            while stepIndex < steps!.count-1 && steps![stepIndex].snapCount <= globalIndex {
                globalIndex -= steps![stepIndex].snapCount
                stepIndex++
            }
            // Wenn globaler Index exisiert beginnen Snaps in Ergebnis-Array anzufügen...
            if steps![stepIndex].snapCount > globalIndex {
                while count > 0 {
                    if globalIndex >= steps![stepIndex].containingSnaps.count {
                        globalIndex -= steps![stepIndex].containingSnaps.count
                        stepIndex++
                        if stepIndex >= steps!.count {
                            break // Abruch wenn globalIndex+count über Datensatz hinausgehen
                        }
                    }
                    result.append(steps![stepIndex].containingSnaps[steps![stepIndex].snapCount-1-globalIndex]) // Snap an Ergebnis-Array anhängen
                    count--
                    globalIndex++
                }
            }
        }
        return result
    }
    
    /**
        Pusht Snap mit globalem Index an erste Stelle & schiebt verdrängte Snap nach hinten
        Wenn Rückgabe nil bedeutet das dass Snap nicht gefunden wurde oder dass Datenbank nicht richtig initialisiert wurde
    */
    internal static func pushSnap(var globalIndex:Int) -> Snap? {
        if steps != nil {
            // Nach globalem Index suchen...
            var stepIndex = 0
            let steps = self.steps // Kopie von steps anlegen, damit steps nicht mehrfach gefetcht werden muss
            while stepIndex < steps!.count-1 && steps![stepIndex].snapCount <= globalIndex {
                globalIndex -= steps![stepIndex].snapCount
                stepIndex++
            }
            if steps![stepIndex].snapCount > globalIndex && steps!.count >= 1 {
                
                
                // gefundenen Snap auf erste Stelle pushen...
                let snap = steps![stepIndex].containingSnaps[steps![stepIndex].snapCount-1-globalIndex]
                if stepIndex == 0 {
                    snap.actualStep = steps![2] // (sorgt dafür dass Snaps die sich bereits auf erster Stufe befinden auch neu angeordnet werden)
                }
                snap.actualStep = steps![0] // verschiebe auf erste Stufe
                snap.pushDate = NSDate() // aktualisiere pushDate
            
                // höherre Stufen auf Überfüllung prüfen...
                if Int(steps![0].maxSnapCount) < steps![0].snapCount {
                    if steps![1].desiredQualityIndicatorString != nil {
                        steps![0].containingSnaps[0].applyNewQualityIndicator(steps![1].desiredQualityIndicatorString!)
                    }
                    steps![0].containingSnaps[0].actualStep = steps![1]
                }
                if Int(steps![1].maxSnapCount) < steps![1].snapCount {
                    if steps![2].desiredQualityIndicatorString != nil {
                        steps![1].containingSnaps[0].applyNewQualityIndicator(steps![2].desiredQualityIndicatorString!)
                    }
                    steps![1].containingSnaps[0].actualStep = steps![2]
                }
                if Int(steps![2].maxSnapCount) < steps![2].snapCount {
                    let snap = steps![2].containingSnaps[0]
                    snap.destroy()
                    managedObjectContext.deleteObject(snap)
                }
                return snap // Alles hat geklappt
            }
        }
        return nil // Misserfolg
    }
    
    
    /// Funktion erzeugt neuen Snap und fügt ihn auf ersten Step
    internal static func createSnap(photo photo: UIImage) -> Snap {
        // Snap erzeugen in step0
        let s = step0!.createSnap(photo: photo)
        // höherre Stufen auf Überfüllung prüfen...
        if Int(steps![0].maxSnapCount) < steps![0].snapCount {
            if steps![1].desiredQualityIndicatorString != nil {
                steps![0].containingSnaps[0].applyNewQualityIndicator(steps![1].desiredQualityIndicatorString!)
            }
            steps![0].containingSnaps[0].actualStep = steps![1]
        }
        if Int(steps![1].maxSnapCount) < steps![1].snapCount {
            if steps![2].desiredQualityIndicatorString != nil {
                steps![1].containingSnaps[0].applyNewQualityIndicator(steps![2].desiredQualityIndicatorString!)
            }
            steps![1].containingSnaps[0].actualStep = steps![2]
        }
        if Int(steps![2].maxSnapCount) < steps![2].snapCount {
            let snap = steps![2].containingSnaps[0]
            snap.destroy()
            managedObjectContext.deleteObject(snap)
        }
        // Rückgabe
        return s
    }
    
    /// Löscht Snap an bestimmtem globalem Index
    internal static func deleteSnap(var globalIndex:Int) -> Bool? {
        if steps != nil {
            // Nach globalem Index suchen...
            var stepIndex = 0
            let steps = self.steps // Kopie von steps anlegen, damit steps nicht mehrfach gefetcht werden muss
            while stepIndex < steps!.count-1 && steps![stepIndex].snapCount <= globalIndex {
                globalIndex -= steps![stepIndex].snapCount
                stepIndex++
            }
            // Wenn globaler Index exisiert Element ausgeben
            if steps![stepIndex].snapCount > globalIndex {
                let snap = steps![stepIndex].containingSnaps[steps![stepIndex].snapCount-1-globalIndex]
                snap.destroy()
                managedObjectContext.deleteObject(snap) //löschen
                return true // Erflog
            } else {
                return false // Misserfolg
            }
        } else {
            return nil // Datenbank ist nicht initialisiert
        }
    }
    
    /// Loecht letzten Snap in letzter Stufe
    internal static func deleteLastSnap() -> Bool? {
        if steps != nil {
            if step2!.snapCount >= 1 {
                let snap = step2!.containingSnaps[0]
                snap.destroy()
                managedObjectContext.deleteObject(snap) //löschen
                return true // Erflog
            } else {
                return false // Misserfolg
            }
        } else {
            return nil // Datenbank ist nicht initialisiert
        }
    }
    
}








