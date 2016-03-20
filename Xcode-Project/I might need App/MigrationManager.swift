//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation

class MigrationManager {
    
    internal enum MigrationState {
        case KeepProcessing
        case NotPrepared
        case Migrated
        case FatalError
    }
    
    internal enum PreparationState {
        case NoNeedForMigration
        case Prepared
        case FatalError
    }
    
    internal enum Operation {
        case DeleteLastSnap
        case ApplyQualityIndicatorStringForLastSnapInStep(Int,String)
        //case SetMaximumSnapCountForStep(Int,Int32) DIESEN FALL SOLLTE ES NICHT MEHR GEBEN. WIRD SOFORT ZUGEWIESSEN
        case MoveSnap(Int,Int)
        case SaveDatabase
    }
    
    private static var migrated:Bool = false
    private static var operations:[Operation]! = nil
    private static var index:Int = 0
    
    internal static var needsMigration:Bool {
        get {
            if DatabaseManager.databaseExists() {
                return Int32(DatabaseManager.step0!.snapCount) > DatabaseManager.step0!.maxSnapCount
                    || Int32(DatabaseManager.step1!.snapCount) > DatabaseManager.step1!.maxSnapCount
                    || Int32(DatabaseManager.step2!.snapCount) > DatabaseManager.step2!.maxSnapCount
            } else {
                return false
            }
        }
    }
    
    internal static func prepareForMigration() -> PreparationState {
        index = 0
        if DatabaseManager.databaseExists() {
            
            // neue Werte
            let newStep0MaxSnapCount = Int32(DatabaseManager.step0!.maxSnapCount)
            let newStep1MaxSnapCount = Int32(DatabaseManager.step1!.maxSnapCount)
            let newStep2MaxSnapCount = Int32(DatabaseManager.step2!.maxSnapCount)
            
            // alte Werte
            let oldStep0SnapCount = Int32(DatabaseManager.step0!.snapCount)
            let oldStep1SnapCount = Int32(DatabaseManager.step1!.snapCount)
            let oldStep2SnapCount = Int32(DatabaseManager.step2!.snapCount)
            
            // Differenz
            let fromStep0ToStep1 = max(oldStep0SnapCount - newStep0MaxSnapCount, 0)
            let fromStep1ToStep2 = max((oldStep1SnapCount+fromStep0ToStep1) - newStep1MaxSnapCount, 0)
            let deleteFromStep3 = max((oldStep2SnapCount+fromStep1ToStep2) - newStep2MaxSnapCount, 0)
            
            //print("fromStep0ToStep1=\(fromStep0ToStep1)")
            //print("fromStep1ToStep2=\(fromStep1ToStep2)")
            //print("deleteFromStep3=\(deleteFromStep3)")
            
            // --- Noetige Operationen erzeugen ---
            // Array anlegen
            var operations:[Operation] = [Operation]()
            
            // Snaps von step0 auf step1 bewegen
            if fromStep0ToStep1 >= 1 {
                for _ in 1...fromStep0ToStep1 {
                    operations.append(.ApplyQualityIndicatorStringForLastSnapInStep(0, DatabaseManager.step1!.desiredQualityIndicatorString!))
                    operations.append(.MoveSnap(0, 1))
                }
            }
            
            // Snaps von step1 auf step2 bewegen
            //let scheduledStep0SnapCount = oldStep0SnapCount-fromStep0ToStep1
            //var scheduledStep1SnapCount = oldStep1SnapCount+fromStep0ToStep1
            if fromStep1ToStep2 >= 1 {
                for _ in 1...fromStep1ToStep2 {
                    operations.append(.ApplyQualityIndicatorStringForLastSnapInStep(1, DatabaseManager.step2!.desiredQualityIndicatorString!))
                    operations.append(.MoveSnap(1, 2))
                }
            }
            
            // Snaps aus step2 loechen
            //scheduledStep1SnapCount = scheduledStep1SnapCount-fromStep1ToStep2
            //let scheduledStep2SnapCount = scheduledStep1SnapCount+fromStep1ToStep2
            if deleteFromStep3 >= 1 {
                for _ in 1...deleteFromStep3 {
                    operations.append(.DeleteLastSnap)
                }
            }
            
            // Datenbank speichern
            operations.append(.SaveDatabase)
            
            MigrationManager.operations = operations
            return .Prepared
        }
        print("Database not found!")
        return .FatalError
    }
    
    internal static func process() -> MigrationState {
        if operations == nil {
            return .NotPrepared
        } else if index < operations.count {
            let operation = operations[index++]
            
            //dispatch_async(dispatch_get_main_queue()) {
                
            switch operation {
                
                case .DeleteLastSnap:
                    DatabaseManager.deleteLastSnap()
                
                case .ApplyQualityIndicatorStringForLastSnapInStep(let stepIndex, let qualityIndicatorString):
                    let step = DatabaseManager.steps![stepIndex]
                    if step.containingSnaps.count > 0 {
                        let snap = step.containingSnaps[0]
                        let result = snap.applyNewQualityIndicator(qualityIndicatorString)
                        if result == nil {
                            print("\(qualityIndicatorString) is not a legal QualityIndicatorString!")
                        }
                    } else {
                        print("steps![\(stepIndex)].containingSnaps.count == 0")
                    }
                
                case .MoveSnap(let srcStepIndex, let destStepIndex):
                    let stepA = DatabaseManager.steps![srcStepIndex]
                    let stepB = DatabaseManager.steps![destStepIndex]
                    if stepA.containingSnaps.count > 0 {
                        stepA.containingSnaps[0].actualStep = stepB
                    }
                
                case .SaveDatabase:
                    DatabaseManager.save()
                
            }
            DatabaseManager.save()
            
            //}
            
            return .KeepProcessing
        } else {
            operations = nil
            return .Migrated
        }
        
    }
    
    /// Fortschritt [0,1]
    internal static var progress:Float {
        get {
            if let operations = MigrationManager.operations {
                if operations.count == 0 {
                    return 1
                } else {
                    return Float(index) / Float(operations.count)
                }
            } else {
                return 0
            }
        }
    }
    
    internal static var progressDescription:String {
        if operations == nil {
            return "Preparing"
        } else if progress == 1 {
            return "Migrated"
        } else {
            return "\(Int(progress*100.0))%"
        }
    }
    
}
