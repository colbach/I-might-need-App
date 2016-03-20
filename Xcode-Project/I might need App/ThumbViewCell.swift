//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import UIKit

class ThumbViewCell: UICollectionViewCell {
    
    internal static func giveOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        if fromInterfaceOrientation.isLandscape {
            lineCountStep0 = 4;
            lineCountStep1 = 6;
            lineCountStep2 = 8;
        } else {
            lineCountStep0 = 3;
            lineCountStep1 = 4;
            lineCountStep2 = 5;
        }
    }
    
    /// Anzahl Snaps pro Reihe
    internal static var lineCountStep0 = 3, lineCountStep1 = 4, lineCountStep2 = 5

    
    internal static var getEdgeInPointsForStep0:CGFloat {
        get {
            //return CGFloat((Float(Int(UIScreen.mainScreen().applicationFrame.width)) / Float(lineCountStep0)) - (2.0/3.0)) - 0.5 //veraltet
            return CGFloat((Float(Int(UIScreen.mainScreen().bounds.width)) / Float(lineCountStep0)) - (2.0/3.0)) - 0.5
        }
    }
    
    internal static var getEdgeInPointsForStep1:CGFloat {
        get {
            return CGFloat((Float(Int(UIScreen.mainScreen().bounds.width)) / Float(lineCountStep1)) - (3.0/4.0))
        }
    }
    
    internal static var getEdgeInPointsForStep2:CGFloat {
        get {
            return CGFloat((Float(Int(UIScreen.mainScreen().bounds.width)) / Float(lineCountStep2)) - (4.0/5.0))
        }
    }
    
    internal static func getEdgeInPoints(thumbStep:Int) -> CGFloat? {
        //print("getEdgeInPoints(thumbStep:Int)\(rand())")
        if thumbStep == 0 {
            return getEdgeInPointsForStep0
        } else if thumbStep == 1 {
            return getEdgeInPointsForStep1
        } else if thumbStep == 2 {
            return getEdgeInPointsForStep2
        }
        print("Warning: Illegal argument. 0 <= thumbStep <= 2")
        return nil
    }
    
    @IBOutlet var imageView : UIImageView!
    
    func setImage(image: UIImage){
        
        self.imageView.image = image
    }
    
    /* override var bounds: CGRect {
        didSet {
            contentView.frame = bounds
        }
    } */
}