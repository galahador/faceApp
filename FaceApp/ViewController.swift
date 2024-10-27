//
//  ViewController.swift
//  FaceApp
//
//  Created by tBug on 26.10.24..
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var consoleView: CustomPrintView!
    @IBOutlet weak var faceDetectionView: FaceDetectionView!
    
    override func viewDidLoad() {
         super.viewDidLoad()
        setupUI()
     }
    
    private func setupUI() {
        faceDetectionView.delegate = self
    }
}

extension ViewController: FaceDetectionViewDelegagte {
    func noFaceDetectedText(text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.consoleView.log(text)
        }
    }
    
    func faceDetectedText(text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.consoleView.log(text)
        }
    }
    
    func actionStart() {
        DispatchQueue.main.async { [weak self] in
            self?.faceDetectionView.layer.borderColor = UIColor.green.cgColor
            self?.faceDetectionView.layer.borderWidth = 1
        }
    }
    
    func actionEnd() {
        DispatchQueue.main.async { [weak self] in
            self?.faceDetectionView.layer.borderColor = UIColor.clear.cgColor
            self?.faceDetectionView.layer.borderWidth = 0
            self?.consoleView.clearLog()
        }
    }
}

