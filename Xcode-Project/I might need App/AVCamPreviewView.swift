//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
import UIKit
import AVFoundation

/// View welche in Echtzeit Camera Input geladen wird (Vorschau)
class AVCamPreviewView: UIView{
    
    var session: AVCaptureSession? {
        get{
            return (self.layer as! AVCaptureVideoPreviewLayer).session;
        }
        set(session){
            (self.layer as! AVCaptureVideoPreviewLayer).session = session;
        }
    };
    
    override class func layerClass() ->AnyClass{
        return AVCaptureVideoPreviewLayer.self;
    }
    
}
