//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import Foundation
import UIKit

class StartPage3ViewController: UIViewController {
    
    internal var previousViewController:UIViewController?
    
    @IBOutlet weak var neverLeaveStep3Switch: UISwitch!
    
    @IBOutlet weak var step1Slider: UISlider!
    @IBOutlet weak var step1SizeLabel: UILabel!
    
    @IBOutlet weak var step2Slider: UISlider!
    @IBOutlet weak var step2SizeLabel: UILabel!
    
    @IBOutlet weak var step3Slider: UISlider!
    @IBOutlet weak var step3SizeLabel: UILabel!
    
    /// Hide Statusbar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func back(sender: UIButton) {
        if let previousViewController = self.previousViewController {
            self.navigationController!.popToViewController(previousViewController, animated: true)
        } else {
            print("previousViewController not set!")
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Navigationbar zeigen
        //self.navigationController!.setNavigationBarHidden(false, animated: false)
    }
    
    /// Lets start Nutton gedruekt
    @IBAction func letsStart(sender: UIButton) {
        DatabaseManager.initDatabase()
        PreferencesManager.writePreparedValues()
        self.performSegueWithIdentifier("letsStart", sender: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        // Bestehende Einstellungen setzen
        updateStep1SizeLabel()
        updateStep1Slider()
        updateStep2SizeLabel()
        updateStep2Slider()
        updateNeverLeaveStep3Switch()
        updateStep3SizeLabel()
        updateStep3Slider()
    }
    
    // === Step 1 ===
    
    private func updateStep1SizeLabel() {
        step1SizeLabel.text = "~ \(PreferencesManager.preparedStep0PlannedSizeInMB) MB"
    }
    
    private func updateStep1Slider() {
        step1Slider.value = Float(PreferencesManager.preparedStep0PlannedSizeInMB) / Float(PreferencesManager.generalStepMaximumSizeInMBForInterface) * step1Slider.maximumValue
    }
    
    @IBAction func step1SliderChanged(sender: UISlider) {
        PreferencesManager.preparedStep0PlannedSizeInMB = Int(round((sender.value / sender.maximumValue) * Float(PreferencesManager.generalStepMaximumSizeInMBForInterface)))
        step1SizeLabel.text = "~ \(PreferencesManager.preparedStep0PlannedSizeInMB) MB"
    }
    
    // === Step 2 ===
    
    private func updateStep2SizeLabel() {
        step2SizeLabel.text = "~ \(PreferencesManager.preparedStep1PlannedSizeInMB) MB"
    }
    
    private func updateStep2Slider() {
        step2Slider.value = Float(PreferencesManager.preparedStep1PlannedSizeInMB) / Float(PreferencesManager.generalStepMaximumSizeInMBForInterface) * step2Slider.maximumValue
        
    }
    
    @IBAction func step2SliderChanged(sender: UISlider) {
        PreferencesManager.preparedStep1PlannedSizeInMB = Int(round((sender.value / sender.maximumValue) * Float(PreferencesManager.generalStepMaximumSizeInMBForInterface)))
        step2SizeLabel.text = "~ \(PreferencesManager.preparedStep1PlannedSizeInMB) MB"
    }
    
    // === Step 3 ===
    
    @IBAction func neverLeaveStep3SwitchChanged(sender: UISwitch) {
        PreferencesManager.preparedStep2NeverLeaveStep = sender.on
        updateStep3SizeLabel()
        updateStep3Slider()
    }
    
    private func updateNeverLeaveStep3Switch() {
        neverLeaveStep3Switch.on = PreferencesManager.preparedStep2NeverLeaveStep
    }
    
    private func updateStep3SizeLabel() {
        if PreferencesManager.preparedStep2NeverLeaveStep {
            step3SizeLabel.text = "∞"
        } else {
            step3SizeLabel.text = "~ \(PreferencesManager.preparedStep2PlannedSizeInMB) MB"
        }
    }
    
    private func updateStep3Slider() {
        step3Slider.enabled = !PreferencesManager.preparedStep2NeverLeaveStep
        step3Slider.value = Float(PreferencesManager.preparedStep2PlannedSizeInMB) / Float(PreferencesManager.generalStepMaximumSizeInMBForInterface) * step3Slider.maximumValue
    }
    
    @IBAction func step3SliderChanged(sender: UISlider) {
        PreferencesManager.preparedStep2PlannedSizeInMB = Int(round((sender.value / sender.maximumValue) * Float(PreferencesManager.generalStepMaximumSizeInMBForInterface)))
        step3SizeLabel.text = "~ \(PreferencesManager.preparedStep2PlannedSizeInMB) MB"
    }
    
}
    