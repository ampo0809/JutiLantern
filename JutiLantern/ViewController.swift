//
//  ViewController.swift
//  JutiLantern
//
//  Created by Nacho Ampuero on 15.07.20.
//  Copyright © 2020 Nacho Ampuero. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var lightIsOff: Bool = true
    var defaultAlpha: CGFloat = 0.4
    var timer = Timer()
    var secondsPassed = 0
    var totalTimer = 0
    
    @IBOutlet weak var levelFour: UIButton!
    @IBOutlet weak var levelThree: UIButton!
    @IBOutlet weak var levelTwo: UIButton!
    @IBOutlet weak var levelOne: UIButton!
    @IBOutlet weak var levelOff: UIButton!
    @IBOutlet weak var flashlightIcon: UIImageView!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var timeCountdown: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let corner: CGFloat = 30
        levelFour.layer.cornerRadius = corner
        levelFour.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        levelOff.layer.cornerRadius = corner
        levelOff.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        updateAlpha(with: defaultAlpha, LATwo: defaultAlpha, LATree: defaultAlpha, LAFour: defaultAlpha)
        
    }
    
    
    //MARK: - Time Slider and Functions
    @IBAction func sliderValueGotChanged(_ sender: UISlider) {
        
        secondsPassed = 0
        timer.invalidate()
        NSObject.cancelPreviousPerformRequests(withTarget: self)

        // Restrain slider by minute steps
        let step: Float = 60
        let roundedTimerValue = round(timeSlider.value/step) * step
        
        totalTimer = Int(roundedTimerValue)
        updateTimeLabel(with: totalTimer, and: nil)
                
        triggerTimer()
    }
    
    
    func triggerTimer() {
        
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        
        if secondsPassed < totalTimer {
            secondsPassed += 1
            
            let remainingTime = totalTimer - secondsPassed
            updateTimeLabel(with: remainingTime, and: nil)
            
            timeSlider.setValue(Float(remainingTime), animated: true)
            print(secondsPassed)
            
            // Timer resets itself after 15 seconds if the light is off.
            if lightIsOff {
                perform(#selector(autoTimerOff), with: nil, afterDelay: 15)
            }
            
        } else {
            offModeToggled()
            timer.invalidate()
            print("The End of Times")
            
        }
    }
    
    func updateTimeLabel(with newTimeLabel: Int, and newSliderValue: Int?) {   // Can the same Int be used for both in all cases?
        
        let displayedTime = timeString(time: TimeInterval(newTimeLabel))
        timeCountdown.text = displayedTime
        
        timeSlider.setValue(Float(newSliderValue ?? totalTimer), animated: true)
        
    }
    
    // Simply to convert the seconds to a 00:00:00 format
    func timeString(time: TimeInterval) -> String {
        let hour = Int(time) / 3600
        let minute = Int(time) / 60 % 60
        let second = Int(time) % 60
        
        // Return formated string
        return String(format: "%02i:%02i:%02i", hour, minute, second)
    }
    
    // To shut timer down if the light is off after a given time.
    @objc func autoTimerOff() {
        
        offModeToggled()
        totalTimer = 0
        updateTimeLabel(with: totalTimer, and: totalTimer)
        timer.invalidate()
    }
    
    
    //MARK: - Light Buttons and Functions
    @IBAction func levelButtonPressed(_ sender: UIButton) {
        
        lightIsOff = false
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        var torchLevel: Float = 1.0
        let chosenLevel = sender.currentTitle!
        
        switch chosenLevel {    
        case "levelOne":
            torchLevel = 0.1
            updateAlpha(with: 0.8, LATwo: nil, LATree: nil, LAFour: nil)   // Caterpillar effect
        case "levelTwo":
            torchLevel = 0.4
            updateAlpha(with: 0.7, LATwo: 0.8, LATree: nil, LAFour: nil)
        case "levelThree":
            torchLevel = 0.7
            updateAlpha(with: 0.6, LATwo: 0.7, LATree: 0.8, LAFour: nil)
        default:
            torchLevel = 1.0
            updateAlpha(with: 0.5, LATwo: 0.6, LATree: 0.7, LAFour: 0.8)
        }
        
        toggleTorch(on: true, with: torchLevel)
        phoneVibe(lightIsOn: true)
        flashlightIcon.image = UIImage(systemName: "flashlight.on.fill")
        
        // If the timer is off, the light defaults to 5 min
        if totalTimer == 0 {
            totalTimer = 300
            triggerTimer()
            updateTimeLabel(with: totalTimer, and: totalTimer)
        }
    }
    
    
    @IBAction func levelOffPressed(_ sender: UIButton) {
        
        if !lightIsOff {
            phoneVibe(lightIsOn: false)
        }
        
        offModeToggled()
    }

    
    func offModeToggled() {
        
        toggleTorch(on: false, with: nil)
        flashlightIcon.image = UIImage(systemName: "flashlight.off.fill")
        lightIsOff = true
        updateAlpha(with: defaultAlpha, LATwo: defaultAlpha, LATree: defaultAlpha, LAFour: defaultAlpha)
    }
    
    
    func toggleTorch(on: Bool, with level: Float?) {
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
                    device.torchMode = .on
                    try device.setTorchModeOn(level: level!)
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    
    func phoneVibe(lightIsOn: Bool) {
        
        if lightIsOn == true {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
        
        if lightIsOn == false { 
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    
    func updateAlpha(with LAOne: CGFloat?, LATwo: CGFloat?, LATree: CGFloat?, LAFour: CGFloat?) {
        
        levelOff.alpha = defaultAlpha
        levelOne.alpha = LAOne ?? defaultAlpha
        levelTwo.alpha = LATwo ?? defaultAlpha
        levelThree.alpha = LATree ?? defaultAlpha
        levelFour.alpha = LAFour ?? defaultAlpha
        
    }

}


