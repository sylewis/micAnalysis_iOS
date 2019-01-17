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

    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var amplitudeLabel: UILabel!
    @IBOutlet weak var noteNameWithSharpsLabel: UILabel!
    @IBOutlet weak var noteNameWithFlatsLabel: UILabel!
    @IBOutlet weak var micFrequencyLabel: UILabel!
    @IBOutlet weak var micAmplitudeLabel: UILabel!
    @IBOutlet weak var audioInputPlot: EZAudioPlot!
    @IBOutlet weak var audioInputPlotPost: EZAudioPlot!
//    @IBOutlet weak var oscInputPlot: EZAudioPlot!
    
    @IBOutlet weak var stackViewBottom: UIStackView!
    @IBOutlet weak var topLabel: UILabel!
    
    // ! Operator unwraps
    var mic: AKMicrophone!
    var micTracker: AKMicrophoneTracker!
    var tracker: AKFrequencyTracker!
    var booster: AKBooster!
    var oscillator1 = AKOscillator(waveform: AKTable(.sine))
    
    //Add vars from Filter effects proj example
    //var delay: AKDelay!
    var decimator: AKDecimator!
    var deciMixer: AKDryWetMixer!
    var reverb: AKCostelloReverb!
    var reverbMixer: AKDryWetMixer!
    var mixer = AKMixer()

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

    func setupPlotPost() {
        let plotPost = AKNodeOutputPlot(reverbMixer, frame: audioInputPlotPost.bounds)
        plotPost.plotType = .rolling
        plotPost.shouldFill = true
        plotPost.shouldMirror = true
        plotPost.color = UIColor.orange
        plotPost.backgroundColor = UIColor.darkGray
        audioInputPlotPost.addSubview(plotPost)
    }

//    func setupPlotOsc() {
//        let plotOsc = AKNodeOutputPlot(oscillator1, frame: oscInputPlot.bounds)
//        plotOsc.plotType = .rolling
//        plotOsc.shouldFill = true
//        plotOsc.shouldMirror = true
//        plotOsc.color = UIColor.yellow
//        plotOsc.backgroundColor = UIColor.darkGray
//        oscInputPlot.addSubview(plotOsc)
//    }
    
    //Put initial setup code that is run once at load here
    override func viewDidLoad() {
        super.viewDidLoad()

        topLabel.layer.cornerRadius = topLabel.frame.height / 6

        AKSettings.audioInputEnabled = true
        mic = AKMicrophone()
        micTracker = AKMicrophoneTracker(hopSize: 4_096, peakCount: 20)
        tracker = AKFrequencyTracker(mic)
        booster = AKBooster(tracker, gain: 1)

        decimator = AKDecimator(booster)
        deciMixer = AKDryWetMixer(booster, decimator)
        reverb = AKCostelloReverb(deciMixer)
        reverbMixer = AKDryWetMixer(deciMixer, reverb)
        
        oscillator1.frequency = 0
        oscillator1.amplitude = 0.025
        
        mixer = AKMixer(oscillator1, reverbMixer)
        
        AudioKit.output = mixer
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
        
        setupUI()
        oscillator1.start()
        micTracker.start()
    }

    //Great place to show and hide stuff before view appears
    override func viewWillAppear(_ animated: Bool) {
        //Code here
    }
    
    //Good place to start animations etc
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        

        setupPlot()
        setupPlotPost()
//        setupPlotOsc()

        Timer.scheduledTimer(timeInterval: 0.1,
                             target: self,
                             selector: #selector(ViewController.updateUI),
                             userInfo: nil,
                             repeats: true)
    }

    @objc func updateUI() {
        
 
        
        if tracker.amplitude > 0.05 {
            frequencyLabel.text = String(format: "%0.1f", tracker.frequency)
            
            oscillator1.frequency = tracker.frequency
//            var micFrequency = Float(micTracker.frequency)
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
        
        micFrequencyLabel.text = String(format: "%0.2f", micTracker.frequency)
        
        micAmplitudeLabel.text = String(format: "%0.2f", micTracker.amplitude)
        
    }
    
    func generateTone() {
        
    }
    
    func setupUI() {

        stackViewBottom.axis = .vertical
        stackViewBottom.distribution = .fillEqually
        stackViewBottom.alignment = .fill
        stackViewBottom.translatesAutoresizingMaskIntoConstraints = false
        stackViewBottom.spacing = 0
        
        stackViewBottom.addArrangedSubview(AKSlider(
            property: "Mic Monitor Level",
            value: self.booster.gain,
            range: 0 ... 1.5,
            format: "%0.2f") { sliderValue in
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
        
        stackViewBottom.addArrangedSubview(AKSlider(
            property: "Osc1 Volume",
            value: self.oscillator1.amplitude,
            range: 0 ... 0.1,
            format: "%0.2f") { sliderValue in
                self.oscillator1.amplitude = sliderValue
        })

        
//        view.addSubview(stackViewBottom)
//
//        stackViewBottom.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9).isActive = true
//        stackViewBottom.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.9).isActive = true
//
//        stackViewBottom.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
//        stackViewBottom.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }

}
