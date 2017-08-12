//
//  VisionViewController.swift
//  VisionSample
//
//  Created by Halil İbrahim YILMAZ on 12/08/2017.
//  Copyright © 2017 Halil İbrahim YILMAZ. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class VisionViewController: UIViewController {
    
    var captureSession: AVCaptureSession!
    var device: AVCaptureDevice!
    var queue: DispatchQueue = DispatchQueue(label: "com.halilyilmaz.VisionSample")
    var cameraLayer: AVCaptureVideoPreviewLayer!
    var requests: [VNRequest] = []
    var faceLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.frame = CGRect.zero
        layer.borderColor = UIColor.red.cgColor
        layer.borderWidth = 2
        return layer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        createDetectRequest()
        cameraLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(cameraLayer)
        view.layer.addSublayer(faceLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraLayer.frame = view.bounds
    }
    
    fileprivate func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: queue)
        captureSession.addInput(input)
        captureSession.addOutput(videoDataOutput)
        captureSession.commitConfiguration()
        cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        captureSession.startRunning()
    }
    
    fileprivate func createDetectRequest() {
        let faceRectangleRequest = VNDetectFaceRectanglesRequest(completionHandler: faceHandler)
        requests = [faceRectangleRequest]
    }
    
    fileprivate func faceHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else { return }
        observations.forEach { faceObservation in
            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -view.frame.height)
            let translate = CGAffineTransform.identity.scaledBy(x: view.frame.width, y: view.frame.height)
            let newCoordinate = faceObservation.boundingBox.applying(translate).applying(transform)
            DispatchQueue.main.async {
                self.faceLayer.frame = newCoordinate
            }
        }
    }
}

extension VisionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var requestOptions: [VNImageOption: Any] = [:]
        if let data = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics: data]
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        do {
            try imageRequestHandler.perform(requests)
        } catch {
            print(error.localizedDescription)
        }
    }
}
