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

    // Capture session and related variables
    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var faceDetectionRequest: VNRequest!
    
    weak var delegate: FaceDetectionViewDelegagte?

    // Face bounding box layer
    private var faceBoundingBoxLayer = CAShapeLayer()

    // Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // Setup the view, camera, and Vision
    private func setupView() {
        setupCamera()
        setupVision()
        setupBoundingBox()
        addTapGesture()
    }
    
    private func addTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
             doubleTapGesture.numberOfTapsRequired = 1
             
             // Triple tap gesture to stop
             let tripleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap))
             tripleTapGesture.numberOfTapsRequired = 2
             
             // Make sure double tap is recognized before triple tap
             doubleTapGesture.require(toFail: tripleTapGesture)
             
             // Add gesture recognizers to the UIView
             self.addGestureRecognizer(doubleTapGesture)
             self.addGestureRecognizer(tripleTapGesture)
    }
    
    
    @objc func handleDoubleTap() {
        // Session Start
        self.delegate?.actionStart()
        captureSession.startRunning()
    }

    // Function to handle triple tap (stop)
    @objc func handleTripleTap() {
        // Session End
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
            // Setup camera input
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)

            // Setup video output
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            captureSession.addOutput(videoOutput)

            // Setup preview layer
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
        self.layer.addSublayer(faceBoundingBoxLayer)
    }

    // MARK: - Handle Face Detection
    private func handleFaceDetection(request: VNRequest, error: Error?) {
        if let error = error {
            print("Face Detection Error: \(error.localizedDescription)")
            return
        }

        // Check if we have face observations
        guard let observations = request.results as? [VNFaceObservation], !observations.isEmpty else {
            self.delegate?.noFaceDetectedText(text: "No face detected.")
            print("No face detected.")
            self.faceBoundingBoxLayer.isHidden = true
            return
        }

        print("Detected \(observations.count) face(s).")
        self.delegate?.faceDetectedText(text: "Detected \(observations.count) face(s).")
    
        if let face = observations.first {
            DispatchQueue.main.async { [weak self] in
                self?.updateBoundingBox(for: face)
            }
        }
    }

    // Update the bounding box based on the detected face
    private func updateBoundingBox(for face: VNFaceObservation) {
        let boundingBox = face.boundingBox

        // Convert the bounding box to UIKit coordinates
        let convertedRect = transformBoundingBox(boundingBox)

        // Update the face bounding box layer on the main thread
        DispatchQueue.main.async {
            self.faceBoundingBoxLayer.frame = convertedRect
            self.faceBoundingBoxLayer.isHidden = false
        }
    }
    
    private func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        // Get the size of the video preview layer
        let previewLayerSize = previewLayer.bounds.size

        // Calculate the converted bounding box
        let x = boundingBox.origin.x * previewLayerSize.width
        let width = boundingBox.size.width * previewLayerSize.width
        // Vision uses the bottom-left origin, UIKit uses the top-left origin
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
