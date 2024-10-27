//
//  FaceDetectionView.swift
//  FaceApp
//
//  Created by tBug on 27.10.24..
//

import UIKit
import AVFoundation
import Vision

protocol FaceDetectionViewDelegagte: AnyObject {
    func noFaceDetectedText(text: String)
    func faceDetectedText(text: String)
    
    func actionStart()
    func actionEnd()
}

class FaceDetectionView: UIView {
    
    
    // MARK: - Private Properties
    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var faceDetectionRequest: VNRequest!
    private var faceBoundingBoxLayers: [CAShapeLayer] = []
    private var faceBoundingBoxLayer = CAShapeLayer()
    
    weak var delegate: FaceDetectionViewDelegagte?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Private
    private func setupView() {
        setupCamera()
        setupVision()
        setupBoundingBox()
        addTapGesture()
    }
    
    private func addTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 1
        
        let tripleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap))
        tripleTapGesture.numberOfTapsRequired = 2
        
        doubleTapGesture.require(toFail: tripleTapGesture)
        
        // Add gesture recognizers to the UIView
        self.addGestureRecognizer(doubleTapGesture)
        self.addGestureRecognizer(tripleTapGesture)
    }
    
    //MARK: -  Function to handle triple tap (start)
    @objc func handleDoubleTap() {
        self.delegate?.actionStart()
        captureSession.startRunning()
    }
    
    //MARK: -  Function to handle triple tap (stop)
    @objc func handleTripleTap() {
        self.delegate?.actionEnd()
        captureSession.stopRunning()
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession.sessionPreset = .high
        
        // Select the front camera
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Front camera is not available.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            captureSession.addOutput(videoOutput)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = self.bounds
            self.layer.addSublayer(previewLayer)
            
        } catch {
            print("Error setting up camera input: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Vision Setup
    private func setupVision() {
        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: handleFaceDetection)
    }
    
    // MARK: - Bounding Box Setup
    private func setupBoundingBox() {
        faceBoundingBoxLayer.strokeColor = UIColor.red.cgColor
        faceBoundingBoxLayer.lineWidth = 2
        faceBoundingBoxLayer.fillColor = UIColor.clear.cgColor
        faceBoundingBoxLayer.isHidden = true
        faceBoundingBoxLayer.zPosition = 1
        self.layer.addSublayer(faceBoundingBoxLayer)
    }
    
    // MARK: - Handle Face Detection
    private func handleFaceDetection(request: VNRequest, error: Error?) {
        if let error = error {
            print("Face Detection Error: \(error.localizedDescription)")
            return
        }
        
        // Remove any existing bounding box layers
        DispatchQueue.main.async { [weak self] in
            self?.clearBoundingBoxes()
        }
        
        // Check if we have face observations
        guard let observations = request.results as? [VNFaceObservation], !observations.isEmpty else {
            self.delegate?.noFaceDetectedText(text: "No face detected.")
            print("No face detected.")
            return
        }
        
        print("Detected \(observations.count) face(s).")
        self.delegate?.faceDetectedText(text: "Detected \(observations.count) face(s).")
        
        // Create bounding boxes for each detected face
        DispatchQueue.main.async { [weak self] in
            observations.forEach { face in
                self?.createBoundingBox(for: face)
            }
        }
    }
    
    private func createBoundingBox(for face: VNFaceObservation) {
        let convertedRect = transformBoundingBox(face.boundingBox)
        
        let boundingBoxLayer = CAShapeLayer()
        boundingBoxLayer.strokeColor = UIColor.red.cgColor
        boundingBoxLayer.lineWidth = 2
        boundingBoxLayer.fillColor = UIColor.clear.cgColor // Transparent fill
        boundingBoxLayer.frame = convertedRect
        boundingBoxLayer.zPosition = 1
        
        //MARK: - Draw the bounding box
        let path = UIBezierPath(rect: boundingBoxLayer.bounds)
        boundingBoxLayer.path = path.cgPath
        
        self.layer.addSublayer(boundingBoxLayer)
        self.faceBoundingBoxLayers.append(boundingBoxLayer)
    }
    
    private func clearBoundingBoxes() {
        faceBoundingBoxLayers.forEach { $0.removeFromSuperlayer() }
        faceBoundingBoxLayers.removeAll()
    }
    
    // MARK: - Update the bounding box based on the detected face
    private func updateBoundingBox(for face: VNFaceObservation) {
        let boundingBox = face.boundingBox
        
        let convertedRect = transformBoundingBox(boundingBox)
        
        DispatchQueue.main.async {
            self.faceBoundingBoxLayer.path = nil
            let path = UIBezierPath(rect: convertedRect)
            self.faceBoundingBoxLayer.path = path.cgPath
            
            self.faceBoundingBoxLayer.isHidden = false
        }
    }
    
    private func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        let previewLayerSize = previewLayer.bounds.size
        
        let x = boundingBox.origin.x * previewLayerSize.width
        let width = boundingBox.size.width * previewLayerSize.width

        
        let y = (1 - boundingBox.origin.y - boundingBox.height) * previewLayerSize.height
        let height = boundingBox.size.height * previewLayerSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - Video Frame Handling
extension FaceDetectionView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to convert sampleBuffer to pixelBuffer.")
            return
        }
        
        // Use proper orientation for the front camera
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        
        // Perform Vision request
        do {
            try requestHandler.perform([faceDetectionRequest])
        } catch {
            print("Vision request failed: \(error.localizedDescription)")
        }
    }
}
