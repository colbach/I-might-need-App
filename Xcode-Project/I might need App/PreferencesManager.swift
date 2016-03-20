//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
/*
=== Keys für NSUserDefaults ===
ACHTUNG: AUS KOMPATIBILITAET NIE AENDERN!
*/
private let KEY_STEP0_PLANNED_SIZE_IN_MB:String = "step0PlannedSizeInMB" // (Int)
private let KEY_STEP1_PLANNED_SIZE_IN_MB:String = "step1PlannedSizeInMB" // (Int)
private let KEY_STEP2_PLANNED_SIZE_IN_MB:String = "step2PlannedSizeInMB" // (Int)
private let KEY_STEP2_NEVER_LEAVE_STEP:String = "step2NeverLeaveStep" // (Bool)

private let DOENT_ASK_ON_DELETION_KEY = "doentAskOnDeletionKey" // Bool
private let DISABLE_ROTATION_KEY = "disableRotationKey" // Bool

class PreferencesManager {
    
    private static var _doentAskOnDeletion:Bool? = nil
    internal static var doentAskOnDeletion:Bool {
        get {
            let defaults = NSUserDefaults.standardUserDefaults()
            if let doentAskOnDeletion = _doentAskOnDeletion {
                return doentAskOnDeletion
            } else if defaults.objectForKey(DOENT_ASK_ON_DELETION_KEY) == nil {
                return false
            } else {
                _doentAskOnDeletion = defaults.boolForKey(DOENT_ASK_ON_DELETION_KEY)
                return _doentAskOnDeletion!
            }
        }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(newValue, forKey: DOENT_ASK_ON_DELETION_KEY)
            _doentAskOnDeletion = newValue
        }
    }
    
    private static var _disableRotation:Bool? = nil
    internal static var disableRotation:Bool {
        get {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let disableRotation = _disableRotation {
        return disableRotation
    } else if defaults.objectForKey(DISABLE_ROTATION_KEY) == nil {
        return false
    } else {
        _disableRotation = defaults.boolForKey(DISABLE_ROTATION_KEY)
        return _disableRotation!
        }
        }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(newValue, forKey: DISABLE_ROTATION_KEY)
            _disableRotation = newValue
        }
    }
    
    internal static let generalStepMaximumSizeInMBForInterface:Int = 250
    
    internal static var appreciation:String {
        get {
            
            let count0 = "\(Int32(QualityModel.getEstimatedNumberOfSnapsFittingInStep(QualityModel.defaultQualityIndicatorForStep0, maximumMB: preparedStep0PlannedSizeInMB)!))"
            
            let count1 = "\(Int32(QualityModel.getEstimatedNumberOfSnapsFittingInStep(QualityModel.defaultQualityIndicatorForStep1, maximumMB: preparedStep1PlannedSizeInMB)!))"
            
            var count2 = ""
            if preparedStep2NeverLeaveStep {
                count2 = "unlimited"
            } else {
                count2 = "\(Int32(QualityModel.getEstimatedNumberOfSnapsFittingInStep(QualityModel.defaultQualityIndicatorForStep2, maximumMB: preparedStep2PlannedSizeInMB)!))"
            }
            
            return "This App will hold \(count0) in high-quality, \(count1) in mediocre-quality and \(count2) in low-quality."
        }
    }
    
    private(set) static var writtenStep0PlannedSizeInMB:Int = {
            let defaults = NSUserDefaults.standardUserDefaults()
            if defaults.objectForKey(KEY_STEP0_PLANNED_SIZE_IN_MB) == nil {
                let defaultValue = 300
                defaults.setInteger(defaultValue, forKey: KEY_STEP0_PLANNED_SIZE_IN_MB)
                return defaultValue
            } else {
                return defaults.integerForKey(KEY_STEP0_PLANNED_SIZE_IN_MB)
            }
        }()
    private(set) static var writtenStep1PlannedSizeInMB:Int = {
            let defaults = NSUserDefaults.standardUserDefaults()
            if defaults.objectForKey(KEY_STEP1_PLANNED_SIZE_IN_MB) == nil {
                let defaultValue = 200
                defaults.setInteger(defaultValue, forKey: KEY_STEP1_PLANNED_SIZE_IN_MB)
                return defaultValue
            } else {
                return defaults.integerForKey(KEY_STEP1_PLANNED_SIZE_IN_MB)
            }
        }()
    private(set) static var writtenStep2PlannedSizeInMB:Int = {
            let defaults = NSUserDefaults.standardUserDefaults()
            if defaults.objectForKey(KEY_STEP2_PLANNED_SIZE_IN_MB) == nil {
                let defaultValue = 100
                defaults.setInteger(defaultValue, forKey: KEY_STEP2_PLANNED_SIZE_IN_MB)
                return defaultValue
            } else {
                return defaults.integerForKey(KEY_STEP2_PLANNED_SIZE_IN_MB)
            }
        }()
    private(set) static var writtenStep2NeverLeaveStep:Bool = {
            let defaults = NSUserDefaults.standardUserDefaults()
            return defaults.boolForKey(KEY_STEP2_NEVER_LEAVE_STEP)
        }()
    
    internal static var preparedStep0PlannedSizeInMB:Int = {
            return writtenStep0PlannedSizeInMB
        }()
    internal static var preparedStep1PlannedSizeInMB:Int = {
            return writtenStep1PlannedSizeInMB
        }()
    internal static var preparedStep2PlannedSizeInMB:Int = {
            return writtenStep2PlannedSizeInMB
        }()
    internal static var preparedStep2NeverLeaveStep:Bool = {
            return writtenStep2NeverLeaveStep
        }()
    
    /// Schreibt Vorbereitete Werte. true wenn Erfolgreich, false wenn nicht (zB wenn Datenbank noch gesperrt ist)
    static func writePreparedValues() {
        if !isPreparedValuesEqualWrittenValues(){
            writeNewPreferencesToDatabase(
                newStep0PlannedSizeInMBValue: preparedStep0PlannedSizeInMB,
                newStep1PlannedSizeInMBValue: preparedStep1PlannedSizeInMB,
                newStep2PlannedSizeInMBValue: preparedStep2PlannedSizeInMB,
                newStep2NeverLeaveStepValue:  preparedStep2NeverLeaveStep)
            
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setInteger(preparedStep0PlannedSizeInMB, forKey: KEY_STEP0_PLANNED_SIZE_IN_MB)
            defaults.setInteger(preparedStep1PlannedSizeInMB, forKey: KEY_STEP1_PLANNED_SIZE_IN_MB)
            defaults.setInteger(preparedStep2PlannedSizeInMB, forKey: KEY_STEP2_PLANNED_SIZE_IN_MB)
            defaults.setBool(preparedStep2NeverLeaveStep, forKey: KEY_STEP2_NEVER_LEAVE_STEP)
            defaults.synchronize()
            writtenStep0PlannedSizeInMB = preparedStep0PlannedSizeInMB
            writtenStep1PlannedSizeInMB = preparedStep1PlannedSizeInMB
            writtenStep2PlannedSizeInMB = preparedStep2PlannedSizeInMB
            writtenStep2NeverLeaveStep = preparedStep2NeverLeaveStep
        }
    }
    
    static func isPreparedValuesEqualWrittenValues() -> Bool {
        return
            writtenStep0PlannedSizeInMB == preparedStep0PlannedSizeInMB &&
            writtenStep1PlannedSizeInMB == preparedStep1PlannedSizeInMB &&
            writtenStep2PlannedSizeInMB == preparedStep2PlannedSizeInMB &&
            writtenStep2NeverLeaveStep == preparedStep2NeverLeaveStep
    }
    
    static func resetPreparedValues() {
        preparedStep0PlannedSizeInMB = writtenStep0PlannedSizeInMB
        preparedStep1PlannedSizeInMB = writtenStep1PlannedSizeInMB
        preparedStep2PlannedSizeInMB = writtenStep2PlannedSizeInMB
        preparedStep2NeverLeaveStep = writtenStep2NeverLeaveStep
    }
    
    /// Schreibt neue Einstellungen in Database
    static func writeNewPreferencesToDatabase(
                    newStep0PlannedSizeInMBValue newStep0Size:Int,
                    newStep1PlannedSizeInMBValue newStep1Size:Int,
                    newStep2PlannedSizeInMBValue newStep2Size:Int,
                    newStep2NeverLeaveStepValue newNeverLeaveStep2:Bool) {
        
        if DatabaseManager.databaseExists() {
            
            // neue Werte in DatabaseManager speichern
            DatabaseManager.step0!.maxSnapCount = Int32(QualityModel.getEstimatedNumberOfSnapsFittingInStep(QualityModel.defaultQualityIndicatorForStep0, maximumMB: newStep0Size)!)
            DatabaseManager.step1!.maxSnapCount = Int32(QualityModel.getEstimatedNumberOfSnapsFittingInStep(QualityModel.defaultQualityIndicatorForStep1, maximumMB: newStep1Size)!)
            DatabaseManager.step2!.maxSnapCount = newNeverLeaveStep2 ? INT32_MAX : Int32(QualityModel.getEstimatedNumberOfSnapsFittingInStep(QualityModel.defaultQualityIndicatorForStep2, maximumMB: newStep2Size)!)
            
            // Speichern
            DatabaseManager.save()
        }
    }
}