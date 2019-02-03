//
//  AlarmViewController.swift
//  scoutwatch
//
//  Created by Dirk Hermanns on 03.05.16.
//  Copyright © 2016 private. All rights reserved.
//

import UIKit

class AlarmViewControllerOLD: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let noDataAlarmOptions = [15, 20, 25, 30, 35, 40, 45].map { "\($0) Minutes" }
    let lowPredictionAlarmOptions = [5, 10, 15, 20, 25, 30].map { "\($0) Minutes" }
    
    fileprivate let MAX_ALERT_ABOVE_VALUE : Float = 200
    fileprivate let MIN_ALERT_ABOVE_VALUE : Float = 80
    
    fileprivate let MAX_ALERT_BELOW_VALUE : Float = 150
    fileprivate let MIN_ALERT_BELOW_VALUE : Float = 50
    
    fileprivate let SNAP_INCREMENT = 10
    
    @IBOutlet weak var edgeDetectionSwitch: UISwitch!
    @IBOutlet weak var numberOfConsecutiveValues: UITextField!
    @IBOutlet weak var deltaAmount: UITextField!
    
    @IBOutlet weak var alertIfAboveValueLabel: UILabel!
    @IBOutlet weak var alertIfBelowValueLabel: UILabel!
    
    @IBOutlet weak var alertAboveSlider: UISlider!
    @IBOutlet weak var alertBelowSlider: UISlider!
    
    @IBOutlet weak var unitsLabel: UILabel!
    
    @IBOutlet weak var lowPredictionSwitch: UISwitch!
    @IBOutlet weak var lowPredictionMinutes: UITextField!
    
    @IBOutlet weak var noDataAlarmAfterMinutes: UITextField!
    var minutesPickerView: UIPickerView!

    @IBOutlet weak var smartSnoozeSwitch: UISwitch!
    @IBOutlet weak var notificationsSwitch: UISwitch!
    
    var editingMinutes: (textField: UITextField, options: [String])?
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let defaults = UserDefaults(suiteName: AppConstants.APP_GROUP_ID)
        
        updateUnits()
        
        edgeDetectionSwitch.isOn = AlarmRule.isEdgeDetectionAlarmEnabled.value
        lowPredictionSwitch.isOn = AlarmRule.isLowPredictionEnabled.value
        smartSnoozeSwitch.isOn = AlarmRule.isSmartSnoozeEnabled.value
        notificationsSwitch.isOn = AlarmNotificationService.singleton.enabled
        numberOfConsecutiveValues.text = "\(AlarmRule.numberOfConsecutiveValues.value)"
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(AlarmViewControllerOLD.onTouchGesture))
        self.view.addGestureRecognizer(tap)
        
        minutesPickerView = UIPickerView()
        minutesPickerView.delegate = self
        minutesPickerView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let defaults = UserDefaults(suiteName: AppConstants.APP_GROUP_ID)
        
        updateUnits()
        
        deltaAmount.text = UnitsConverter.toDisplayUnits("\(AlarmRule.deltaAmount.value)")
        
        alertIfAboveValueLabel.text = UnitsConverter.toDisplayUnits("\(AlarmRule.alertIfAboveValue.value)")
        alertAboveSlider.value = (UnitsConverter.toMgdl(alertIfAboveValueLabel.text!.floatValue) - MIN_ALERT_ABOVE_VALUE) / MAX_ALERT_ABOVE_VALUE
        alertIfBelowValueLabel.text = UnitsConverter.toDisplayUnits("\(AlarmRule.alertIfBelowValue.value)")
        alertBelowSlider.value = (UnitsConverter.toMgdl(alertIfBelowValueLabel.text!.floatValue) - MIN_ALERT_BELOW_VALUE) / MAX_ALERT_ABOVE_VALUE
        
        noDataAlarmAfterMinutes.text = "\(AlarmRule.minutesWithoutValues.value)"
        lowPredictionMinutes.text = "\(AlarmRule.minutesToPredictLow.value)"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    @IBAction func edgeDetectionSwitchChanged(_ sender: AnyObject) {
        AlarmRule.isEdgeDetectionAlarmEnabled.value = edgeDetectionSwitch.isOn
    }
    
    @IBAction func lowPredictionSwitchChanged(_ sender: AnyObject) {
        AlarmRule.isLowPredictionEnabled.value = lowPredictionSwitch.isOn
    }
    
    @IBAction func smartSnoozeSwitchChanged(_ sender: AnyObject) {
        AlarmRule.isSmartSnoozeEnabled.value = smartSnoozeSwitch.isOn
    }
    
    @IBAction func notificationsSwitchChanged(_ sender: AnyObject) {
        AlarmNotificationService.singleton.enabled = notificationsSwitch.isOn
    }
    
    @IBAction func valuesEditingChanged(_ sender: AnyObject) {
        guard let numberOfConsecutiveValues = Int(numberOfConsecutiveValues.text!)
        else {
            return
        }
        
        AlarmRule.numberOfConsecutiveValues.value = numberOfConsecutiveValues
    }
    
    @IBAction func deltaEditingChanged(_ sender: AnyObject) {
        let deltaAmountValue = UnitsConverter.toMgdl(deltaAmount.text!)        
        AlarmRule.deltaAmount.value = deltaAmountValue
    }
    
    @IBAction func lowPredictionMinutesEditingDidBegin(_ textField: UITextField) {
        textField.inputView = minutesPickerView
        editingMinutes = (textField: textField, options: lowPredictionAlarmOptions)
        preselectItemInPickerView()
    }
    
    @IBAction func lowPredictionMinutesEditingDidEnd(_ textField: UITextField) {
        let minutes = Int(textField.text!)!
        AlarmRule.minutesToPredictLow.value = minutes
    }
    
    @IBAction func noDataAlarmAfterMinutesEditingDidBegin(_ textField: UITextField) {
        textField.inputView = minutesPickerView
        editingMinutes = (textField: textField, options: noDataAlarmOptions)
        preselectItemInPickerView()
    }
    
    @IBAction func noDataAlarmAfterMinutesEditingDidEnd(_ textField: UITextField) {
        let minutes = Int(textField.text!)!
        AlarmRule.minutesWithoutValues.value = minutes
    }

    @IBAction func aboveAlertValueChanged(_ sender: AnyObject) {
        aboveSliderValueChanged(commitChanges: false)
    }
    
    @IBAction func aboveAlertTouchUp(_ sender: Any) {
        aboveSliderValueChanged(commitChanges: true)
    }
    
    @IBAction func belowAlertValueChanged(_ sender: AnyObject) {
        belowSliderValueChanged(commitChanges: false)
    }
    
    @IBAction func belowAlertTouchUp(_ sender: Any) {
        belowSliderValueChanged(commitChanges: true)
    }
    
    func getAboveAlarmValue() -> Float {
        return Float(MIN_ALERT_ABOVE_VALUE + alertAboveSlider.value * MAX_ALERT_ABOVE_VALUE).rounded()
    }
    
    func getBelowAlarmValue() -> Float {
        return Float(MIN_ALERT_BELOW_VALUE + alertBelowSlider.value * MAX_ALERT_BELOW_VALUE).rounded()
    }
    
    func adjustLowerSliderValue() {
        if getAboveAlarmValue() - getBelowAlarmValue() < 1 {
            alertBelowSlider.setValue(
                (getAboveAlarmValue() - 1 - MIN_ALERT_BELOW_VALUE) / MAX_ALERT_BELOW_VALUE, animated: true)
            belowAlertValueChanged(alertBelowSlider)
        }
    }
    
    func adjustAboveSliderValue() {
        if getBelowAlarmValue() - getAboveAlarmValue() > 0 {
            alertAboveSlider.setValue(
                (getBelowAlarmValue() + 1 - MIN_ALERT_ABOVE_VALUE) / MAX_ALERT_ABOVE_VALUE, animated: true)
            aboveAlertValueChanged(alertAboveSlider)
        }
    }

    func snapAboveSliderValue() {
        
        guard UserDefaultsRepository.units.value == .mgdl else {
            
            // don't know how to snap mol units...
            return
        }

        let alertIfAboveValue = Int(getAboveAlarmValue())
        let snapValue = alertIfAboveValue % SNAP_INCREMENT
        
        let extraIncrement = (snapValue >= (SNAP_INCREMENT/2)) ? SNAP_INCREMENT : 0
        let sliderValue = (Float(alertIfAboveValue - snapValue + extraIncrement).rounded() - MIN_ALERT_ABOVE_VALUE) / MAX_ALERT_ABOVE_VALUE
        
        alertAboveSlider.setValue(sliderValue, animated: true)
    }
    
    func snapBelowSliderValue() {
        
        guard UserDefaultsRepository.units.value == .mgdl else {

            // don't know how to snap mol units...
            return
        }
        
        let alertIfBelowValue = Int(getBelowAlarmValue())
        let snapValue = alertIfBelowValue % SNAP_INCREMENT
        
        let extraIncrement = (snapValue >= (SNAP_INCREMENT/2)) ? SNAP_INCREMENT : 0
        let sliderValue = (Float(alertIfBelowValue - snapValue + extraIncrement).rounded() - MIN_ALERT_BELOW_VALUE) / MAX_ALERT_BELOW_VALUE
        
        alertBelowSlider.setValue(sliderValue, animated: true)
    }
    
    func aboveSliderValueChanged(commitChanges: Bool) {
        snapAboveSliderValue()
        let alertIfAboveValue = getAboveAlarmValue()
        alertIfAboveValueLabel.text = UnitsConverter.toDisplayUnits(String(alertIfAboveValue))
        
        if commitChanges {
            adjustLowerSliderValue()
            AlarmRule.alertIfAboveValue.value = alertIfAboveValue
        }
    }
    
    func belowSliderValueChanged(commitChanges: Bool) {
        snapBelowSliderValue()
        let alertIfBelowValue = getBelowAlarmValue()
        alertIfBelowValueLabel.text = UnitsConverter.toDisplayUnits(String(alertIfBelowValue))
        
        if commitChanges {
            adjustAboveSliderValue()            
            AlarmRule.alertIfBelowValue.value = alertIfBelowValue
        }
    }
    
    func updateUnits() {
        let units = UserDefaultsRepository.units.value
        if units == Units.mmol {
            unitsLabel.text = "mmol"
        } else {
            unitsLabel.text = "mg/dL"
        }
    }
    
    // Remove keyboard and PickerView by touching outside
    @objc func onTouchGesture(){
        self.view.endEditing(true)
    }
    
    // Methods for the noDataAlarmPickerView
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return editingMinutes!.options[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return editingMinutes?.options.count ?? 0
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedMinutes = toButtonText(editingMinutes!.options[row])
        editingMinutes!.textField.text = selectedMinutes
        
        self.view.endEditing(true)
        editingMinutes = nil
    }
    
    // Selects the right item that is shown in the noDataAlarmButton in the PickerView
    fileprivate func preselectItemInPickerView() {
        
        guard let editingMinutes = self.editingMinutes else {
            return
        }
        
        let rowOfSelectedItem : Int = editingMinutes.options.index(of: editingMinutes.textField.text! + " Minutes")!
        minutesPickerView.selectRow(rowOfSelectedItem, inComponent: 0, animated: false)
    }
    
    fileprivate func toButtonText(_ pickerText : String) -> String {
        return pickerText.replacingOccurrences(of: " Minutes", with: "")
    }
}
