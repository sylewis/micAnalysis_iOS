//
//  ViewController.swift
//  MicrophoneAnalysis
//
//  Created by Kanstantsin Linou, revision history on Githbub.
//  Copyright © 2018 AudioKit. All rights reserved.
//

import AudioKit
import AudioKitUI
import UIKit

class ViewController: UIViewController {

    @IBOutlet private var frequencyLabel: UILabel!
    @IBOutlet private var amplitudeLabel: UILabel!
    @IBOutlet private var noteNameWithSharpsLabel: UILabel!
    @IBOutlet private var noteNameWithFlatsLabel: UILabel!
    @IBOutlet private var audioInputPlot: EZAudioPlot!
    @IBOutlet weak var stackViewBottom: UIStackView!
    
    var mic: AKMicrophone!
    var tracker: AKFrequencyTracker!
    var booster: AKBooster!
    
    //Add vars from Filter effects proj example
    //var delay: AKDelay!
    var decimator: AKDecimator!
    var deciMixer: AKDryWetMixer!
    var reverb: AKCostelloReverb!
    var reverbMixer: AKDryWetMixer!

    let noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
    let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    func setupPlot() {
        let plot = AKNodeOutputPlot(booster, frame: audioInputPlot.bounds)
        plot.plotType = .rolling
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = UIColor.green
        plot.backgroundColor = UIColor.darkGray
        audioInputPlot.addSubview(plot)
    }

    override func viewDidLoad() {
        super.viewDidLoad()


        AKSettings.audioInputEnabled = true
        mic = AKMicrophone()
        tracker = AKFrequencyTracker(mic)
        booster = AKBooster(tracker, gain: 1)

        //delay = AKDelay(booster)
        //delay.rampDuration = 0.5 // Allows for some cool effects
        //delay.feedback = 0.5
//        delay.start()
        decimator = AKDecimator(booster)
        deciMixer = AKDryWetMixer(booster, decimator)
        reverb = AKCostelloReverb(deciMixer)
        reverbMixer = AKDryWetMixer(deciMixer, reverb)
        
        setupUI()
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AudioKit.output = reverbMixer
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
        setupPlot()
        Timer.scheduledTimer(timeInterval: 0.1,
                             target: self,
                             selector: #selector(ViewController.updateUI),
                             userInfo: nil,
                             repeats: true)
    }

    @objc func updateUI() {
        
 
        
        if tracker.amplitude > 0.1 {
            frequencyLabel.text = String(format: "%0.1f", tracker.frequency)

            var frequency = Float(tracker.frequency)
            while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
                frequency /= 2.0
            }
            while frequency < Float(noteFrequencies[0]) {
                frequency *= 2.0
            }

            var minDistance: Float = 10_000.0
            var index = 0

            for i in 0..<noteFrequencies.count {
                let distance = fabsf(Float(noteFrequencies[i]) - frequency)
                if distance < minDistance {
                    index = i
                    minDistance = distance
                }
            }
            let octave = Int(log2f(Float(tracker.frequency) / frequency))
            noteNameWithSharpsLabel.text = "\(noteNamesWithSharps[index])\(octave)"
            noteNameWithFlatsLabel.text = "\(noteNamesWithFlats[index])\(octave)"
        }
        amplitudeLabel.text = String(format: "%0.2f", tracker.amplitude)
    }
    
    func setupUI() {
//        let stackView = UIStackView()
//        let stackView = stackViewBottom

        stackViewBottom.axis = .vertical
        stackViewBottom.distribution = .fillEqually
        stackViewBottom.alignment = .fill
        stackViewBottom.translatesAutoresizingMaskIntoConstraints = false
        stackViewBottom.spacing = 10
        
        stackViewBottom.addArrangedSubview(AKSlider(
            property: "Mic Monitor Level",
            value: self.booster.gain,
            range: 0 ... 1.5,
            format: "%0.2f s") { sliderValue in
                self.booster.gain = sliderValue
        })
        
        stackViewBottom.addArrangedSubview(AKSlider(
            property: "Decimate",
            value: self.decimator.decimation,
            range: 0 ... 0.99,
            format: "%0.2f") { sliderValue in
                self.decimator.decimation = sliderValue
        })
        
        stackViewBottom.addArrangedSubview(AKSlider(
            property: "Decimator Mix",
            value: self.deciMixer.balance,
            range: 0 ... 0.99,
            format: "%0.2f") { sliderValue in
                self.deciMixer.balance = sliderValue
        })

        stackViewBottom.addArrangedSubview(AKSlider(
            property: "Reverb Feedback",
            value: self.reverb.feedback,
            range: 0 ... 0.99,
            format: "%0.2f") { sliderValue in
                self.reverb.feedback = sliderValue
        })

        stackViewBottom.addArrangedSubview(AKSlider(
            property: "Reverb Mix",
            value: self.reverbMixer.balance,
            format: "%0.2f") { sliderValue in
                self.reverbMixer.balance = sliderValue
        })
//
//        stackView.addArrangedSubview(AKSlider(
//            property: "Reverb Feedback",
//            value: self.reverb.feedback,
//            range: 0 ... 0.99,
//            format: "%0.2f") { sliderValue in
//                self.reverb.feedback = sliderValue
//        })
//
//        stackView.addArrangedSubview(AKSlider(
//            property: "Reverb Mix",
//            value: self.reverbMixer.balance,
//            format: "%0.2f") { sliderValue in
//                self.reverbMixer.balance = sliderValue
//        })
//
//        stackView.addArrangedSubview(AKSlider(
//            property: "Output Volume",
//            value: self.silence.gain,
//            range: 0 ... 2,
//            format: "%0.2f") { sliderValue in
//                self.silence.gain = sliderValue
//        })
        
//        view.addSubview(stackViewBottom)
//
//        stackViewBottom.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9).isActive = true
//        stackViewBottom.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.9).isActive = true
//
//        stackViewBottom.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
//        stackViewBottom.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }

    
//    func setupUIOrig() {
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.distribution = .fillEqually
//        stackView.alignment = .fill
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.spacing = 10
//
//        stackView.addArrangedSubview(AKSlider(
//            property: "Delay Time",
//            value: self.delay.time,
//            format: "%0.2f s") { sliderValue in
//                self.delay.time = sliderValue
//        })
//
//        stackView.addArrangedSubview(AKSlider(
//            property: "Delay Feedback",
//            value: self.delay.feedback,
//            range: 0 ... 0.99,
//            format: "%0.2f") { sliderValue in
//                self.delay.feedback = sliderValue
//        })
//
//        stackView.addArrangedSubview(AKSlider(
//            property: "Delay Mix",
//            value: self.delayMixer.balance,
//            format: "%0.2f") { sliderValue in
//                self.delayMixer.balance = sliderValue
//        })
//
//        stackView.addArrangedSubview(AKSlider(
//            property: "Reverb Feedback",
//            value: self.reverb.feedback,
//            range: 0 ... 0.99,
//            format: "%0.2f") { sliderValue in
//                self.reverb.feedback = sliderValue
//        })
//
//        stackView.addArrangedSubview(AKSlider(
//            property: "Reverb Mix",
//            value: self.reverbMixer.balance,
//            format: "%0.2f") { sliderValue in
//                self.reverbMixer.balance = sliderValue
//        })
//
//        stackView.addArrangedSubview(AKSlider(
//            property: "Output Volume",
//            value: self.silence.gain,
//            range: 0 ... 2,
//            format: "%0.2f") { sliderValue in
//                self.silence.gain = sliderValue
//        })
//
//        view.addSubview(stackView)
//
//        stackView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9).isActive = true
//        stackView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.9).isActive = true
//
//        stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
//        stackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
//    }
}
