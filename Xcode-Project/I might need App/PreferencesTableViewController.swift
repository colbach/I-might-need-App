//
//  Medienprojekt - I might need App
//
//  Copyright © 2016 Christian Colbach. Alle Rechte vorbehalten
//

import UIKit

class PreferencesTableViewController: UITableViewController {
    
    // ACHTUNG: In dieser Klasse wird oft von Step 1-3 gesprochen, gemeint ist aber Step0-2
    
    @IBOutlet weak var appreciation: UITextView!
    
    @IBOutlet weak var dontAskOnDeletion: UISwitch!
    @IBAction func dontAskOnDeletionSwitched(sender: UISwitch) {
        PreferencesManager.doentAskOnDeletion = sender.on
    }
    
    @IBOutlet weak var disableRotation: UISwitch!
    @IBAction func disableRotationSwitched(sender: UISwitch) {
        PreferencesManager.disableRotation = sender.on
    }
    
    @IBOutlet weak var neverLeaveStep3Switch: UISwitch!
    
    @IBOutlet weak var step1Slider: UISlider!
    @IBOutlet weak var step1SizeLabel: UILabel!
    
    @IBOutlet weak var step2Slider: UISlider!
    @IBOutlet weak var step2SizeLabel: UILabel!
    
    @IBOutlet weak var step3Slider: UISlider!
    @IBOutlet weak var step3SizeLabel: UILabel!
    
    weak var applyButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Toogles setzen
        dontAskOnDeletion.on = PreferencesManager.doentAskOnDeletion;
        disableRotation.on = PreferencesManager.disableRotation;
        
        // Apply Button erstellen
        let button = UIBarButtonItem(title: "", style: .Plain, target: self, action: "applyChanges")
        navigationItem.rightBarButtonItem = button
        applyButton = button // (weil applyButton weak ist)
        
        // Einstellungen am NavigationController vornehmen
        if let navigationController:UINavigationController = self.navigationController {
            
            // Swipeback Geste deaktivieren
            if navigationController.respondsToSelector("interactivePopGestureRecognizer") {
                navigationController.interactivePopGestureRecognizer!.enabled = false
            } else {
                print("navigationController doen't respond to Selector interactivePopGestureRecognizer")
            }
            
        } else {
            print("self.navigationController is nil!")
        }
        
        // Markieren der Zelle vermeiden abschalten
        tableView.allowsSelection = false
        
        // Applybutton updaden
        updateApplyButtonVisibility()
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
        updateAppreciationLabel()
    }
    
    /// Aenderungen in Model uebergeben
    internal func applyChanges() {
        PreferencesManager.writePreparedValues()
        setApplyButtonAppearance(APPLYBUTTONAPPEARANCE_APPLIED)
        if MigrationManager.needsMigration {
            self.performSegueWithIdentifier("showMigration", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let migrationScreenViewController:MigrationScreenController = segue.destinationViewController as? MigrationScreenController {
            migrationScreenViewController.returnViewController = self
        }
    }
    
    internal func updateApplyButtonVisibility() {
        if PreferencesManager.isPreparedValuesEqualWrittenValues() {
            setApplyButtonAppearance(APPLYBUTTONAPPEARANCE_HIDDEN)
        } else {
            setApplyButtonAppearance(APPLYBUTTONAPPEARANCE_APPLY)
        }
    }
    
    private let APPLYBUTTONAPPEARANCE_APPLY:Int = 0;
    private let APPLYBUTTONAPPEARANCE_APPLIED:Int = 1;
    private let APPLYBUTTONAPPEARANCE_HIDDEN:Int = 2;
    
    private func setApplyButtonAppearance(apperance: Int) {
        // pushedButton italic machen da dies in Storyboard nicht möglich ist && verstecken
        if apperance == self.APPLYBUTTONAPPEARANCE_APPLY {
            applyButton.title = ""
            applyButton.setTitleTextAttributes([
                NSFontAttributeName : UIFont.systemFontOfSize(18.0)
                ]
                , forState: .Normal)
            applyButton.tintColor = nil
            applyButton.enabled = true
            applyButton.title = "Apply "
        }
            // pushedButton italic machen da dies in Storyboard nicht möglich ist && verstecken
        else if apperance == self.APPLYBUTTONAPPEARANCE_APPLIED {
            applyButton.title = ""
            applyButton.setTitleTextAttributes([
                NSFontAttributeName : UIFont.italicSystemFontOfSize(16.0)
                ]
                , forState: .Normal)
            applyButton.tintColor = nil
            applyButton.enabled = false
            applyButton.title = "Applied "
        }
            // pushedButton italic machen da dies in Storyboard nicht möglich ist && verstecken
        else if apperance == self.APPLYBUTTONAPPEARANCE_HIDDEN {
            print(applyButton == nil)
            applyButton.setTitleTextAttributes([
                NSFontAttributeName : UIFont.systemFontOfSize(16.0)
                ]
                , forState: .Normal)
            applyButton.tintColor = UIColor.clearColor()
            applyButton.enabled = false
            applyButton.title = ""
        }
        
        
        
    }
    
    // === Vorhersage ===
    private func updateAppreciationLabel() {
        appreciation.text = "(" + PreferencesManager.appreciation + ")"
        //appreciation.font = UIFont.italicSystemFontOfSize(16.0)
        appreciation.font = UIFont.systemFontOfSize(15.0)
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
        updateAppreciationLabel()
        updateApplyButtonVisibility()
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
        updateAppreciationLabel()
        updateApplyButtonVisibility()
    }
    
    // === Step 3 ===

    @IBAction func neverLeaveStep3SwitchChanged(sender: UISwitch) {
        PreferencesManager.preparedStep2NeverLeaveStep = sender.on
        updateStep3SizeLabel()
        updateStep3Slider()
        updateAppreciationLabel()
        updateApplyButtonVisibility()
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
        updateAppreciationLabel()
        updateApplyButtonVisibility()
    }

    // === Andere Einstellungen ===
    
    // === About ===
    
    @IBAction func contactMe(sender: UIButton) {
        let email = "i-might-need-app@colba.ch"
        let url = NSURL(string: "mailto:\(email)")
        UIApplication.sharedApplication().openURL(url!)
    }
    

}