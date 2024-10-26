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

    // Capture session and related variables
    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var faceDetectionRequest: VNRequest!

    // Face bounding box layer
    private var faceBoundingBoxLayer = CAShapeLayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup UI and vision
        setupCamera()
        setupVision()
        setupBoundingBox()

        // Start session
        captureSession.startRunning()
    }

    // MARK: - Camera Setup
    private func setupCamera() {
        // Set session preset to high quality
        captureSession.sessionPreset = .high

        // Select front camera
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
            previewLayer.frame = view.layer.bounds
            view.layer.addSublayer(previewLayer)

        } catch {
            print("Error setting up camera input: \(error.localizedDescription)")
        }
    }

    // MARK: - Vision Setup
    private func setupVision() {
        // Setup the Vision request
        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: handleFaceDetection)
    }

    // MARK: - Bounding Box Setup
    private func setupBoundingBox() {
        // Setup the shape layer for the bounding box
        faceBoundingBoxLayer.strokeColor = UIColor.red.cgColor
        faceBoundingBoxLayer.lineWidth = 2
        faceBoundingBoxLayer.fillColor = UIColor.clear.cgColor
        faceBoundingBoxLayer.isHidden = true
        view.layer.addSublayer(faceBoundingBoxLayer)
    }

    // MARK: - Handle Face Detection
    private func handleFaceDetection(request: VNRequest, error: Error?) {
        if let error = error {
            print("Face Detection Error: \(error.localizedDescription)")
            return
        }

        // Check if we have face observations
        guard let observations = request.results as? [VNFaceObservation], !observations.isEmpty else {
            print("No face detected.")
            self.faceBoundingBoxLayer.isHidden = true
            return
        }

        print("Detected \(observations.count) face(s).")

        // Use the first detected face for simplicity
        if let face = observations.first {
            updateBoundingBox(for: face)
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
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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

