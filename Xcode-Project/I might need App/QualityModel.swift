//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation

/// Diese Klasse dient um Qualitätsfaktoren von Snaps zu organisieren und zu prüfen
class QualityModel {
    
    /// Struct welches technische Parameter für einen QualityIndicator enthalten kann
    struct TechnicalParameters {
        var largestEdgeLength:Int // Länge der längsten Kante
        var compressionQuality:Float // Verwendete Kompessionsstufe (0 < compressionQuality < 1)
        var estimatedFileSize:Float // in MB
    }
    
    // Dieser Struct dient um Ausmasse von Bild darzustellen
    struct Dimension {
        var width:Int
        var lenght:Int
    }
    
    /// Dictionary aller legaler QualityIndicatorStrings und den dazugehörigen technische Parametern (Werte noch nicht gepaced!)
    static let qualityIndicators: [String: TechnicalParameters]
        = [ "ultra high" : TechnicalParameters( largestEdgeLength:3264,  compressionQuality:0.8,  estimatedFileSize:1.2 ), // In Benutzung
            "very high"  : TechnicalParameters( largestEdgeLength:2592,  compressionQuality:0.7,  estimatedFileSize:0.7  ),
            "high"       : TechnicalParameters( largestEdgeLength:1632,  compressionQuality:0.6,  estimatedFileSize:0.15  ), // In Benutzung
            "medium"     : TechnicalParameters( largestEdgeLength:1296,  compressionQuality:0.5,  estimatedFileSize:0.08  ),
            "low"        : TechnicalParameters( largestEdgeLength:816,   compressionQuality:0.4,  estimatedFileSize:0.03  ), // In Benutzung
            "very low"   : TechnicalParameters( largestEdgeLength:648,   compressionQuality:0.3,  estimatedFileSize:0.02  ) ]
    
    // === Standartwerte fuer einzelne Stufen ===
    
    static let defaultQualityIndicatorForStep0:String = {
        return "ultra high"
    }()
    
    static let defaultQualityIndicatorForStep1:String = {
        return "high"
    }()
    
    static let defaultQualityIndicatorForStep2:String = {
        return "low"
    }()
    
    static let defaultQualityIndicators:[String] = {
        return [defaultQualityIndicatorForStep0, defaultQualityIndicatorForStep1, defaultQualityIndicatorForStep2]
    }()
    
    // ===
    
    static func getEstimatedNumberOfSnapsFittingInStep(qualityIndicator:String, maximumMB:Int) -> Int? {
        if let parameters = getTechnicalParametersForQualityIndicator(qualityIndicator) {
            return Int(Float(maximumMB) / parameters.estimatedFileSize)
        } else {
            print("qualityIndicator is not a legal QualityIndicator-String")
            print("return nil")
            return nil
        }
    }
    
    /// Prüft ob es sich bei indicator um einen legalen QualityIndicatorString handelt
    static func isLegalQualityIndicatorString(indicator:String) -> Bool {
        return QualityModel.qualityIndicators[indicator] != nil
    }
    
    
    /**
        Gibt struct mit technischen Parametern zurück
        Falls indicator kein legaler String ist wird nil zurück gegeben
    */
    static func getTechnicalParametersForQualityIndicator(indicator:String) -> TechnicalParameters? {
        return QualityModel.qualityIndicators[indicator]
    }
    
    /// Gibt verlangte Ausmasse für vorgegebene Ausmasse zurück
    static func getDemandedDimensionForQualityIndicator(indicator indicator:String, width:Int, lenght:Int) -> Dimension? {
        if let tp:TechnicalParameters? = getTechnicalParametersForQualityIndicator(indicator) { // Abfage von technische Parametern
            let le = max(width, lenght) // Ermitteln der maximalen Kante
            if tp!.largestEdgeLength >= le { // Wenn maximale Kante kleiner als geforderte Kante ist
                return Dimension(width:width, lenght:lenght) // Ausgabe der Eingabe-Dimension
                                                             // (Bilder werden nie auf eine höhere Dimension aufgeblasen)
            } else { // maximale Kante ist nicht kleiner als geforderte Kante
                let factor:Float = Float(tp!.largestEdgeLength) / Float(le) // Erechnen eines Verkleinerungsfaktors.
                                                                            //(0 < factor < 1)
                return Dimension(width:Int(Float(width) * factor), lenght:Int(Float(lenght) * factor)) // Ausgabe errechnete Dimension
            }
        } else { // indicator ist kein legaler QualityIndicatorString
            return nil // Misserfolg
        }
    }
    
    /**
        Vergleicht zwei IndicatorStrings anhand ihrer Qualitätsmerkmale
        @return: -1  Wenn IndicatorString1 einen höheren Standart wie IndicatorString2 definiert
                  0  Wenn IndicatorString1 und IndicatorString2 gleich hoch definiert sind
                  1  Wenn IndicatorString2 einen höheren Standart wie IndicatorString1 definiert
                 nil Wenn einer der beiden IndicatorStrings kein legaler QualityIndicatorString ist
    */
    static func compare(IndicatorString1:String, to IndicatorString2:String) -> Int? {
        let tp1:TechnicalParameters? = getTechnicalParametersForQualityIndicator(IndicatorString1)
        let tp2:TechnicalParameters? = getTechnicalParametersForQualityIndicator(IndicatorString2)
        if tp1 == nil || tp2 == nil {
            return nil
        } else {
            if tp1!.estimatedFileSize == tp2!.estimatedFileSize {
                return 0
            } else if tp1!.estimatedFileSize > tp2!.estimatedFileSize {
                return -1
            } else {
                return 1
            }
        }
    }
}