//
//  ViewController.swift
//  CoreMLTest
//
//  Created by Ever on 2017/9/16.
//  Copyright © 2017年 Ever. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class VisionViewController: UIViewController, ImageConvertUtil{

    var capView = UIView()
    var previewLayer:AVCaptureVideoPreviewLayer!
    var session = AVCaptureSession()
    var deviceOutput = AVCaptureVideoDataOutput()
    
    var videoConnect:AVCaptureConnection?
    var label = UILabel()
    var queue : DispatchQueue?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        title = "Vision"
        self.initCapture()
        self.configUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stop()
    }
    
    func initCapture()
    {
        if let device = AVCaptureDevice.default(for: AVMediaType.video)
        {
            if device.isFocusPointOfInterestSupported ,
                device.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus)
            {
                try?device.lockForConfiguration()
                device.focusMode = .autoFocus;
                device.unlockForConfiguration()
            }
            
            if let input = try? AVCaptureDeviceInput.init(device: device),
                self.session.canAddInput(input)
            {
                self.session.addInput(input)
            }
        }
        
        self.deviceOutput = AVCaptureVideoDataOutput()
        
        self.deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA];
        
        if self.session.canAddOutput(self.deviceOutput)
        {
            self.session.addOutput(self.deviceOutput)
        }
        
        self.videoConnect = self.deviceOutput.connection(with: .video)
        self.videoConnect?.isEnabled = false
        self.videoConnect?.videoOrientation = .portrait
        
        self.previewLayer = AVCaptureVideoPreviewLayer.init(session: self.session)
        self.previewLayer.videoGravity = .resizeAspectFill
    }
    
    func configUI()
    {
        self.capView.frame = self.view.bounds
        self.view.addSubview(self.capView)
        self.previewLayer.frame = self.view.bounds
        self.capView.layer .addSublayer(self.previewLayer)
        
        self.label.frame = CGRect.init(x: 0, y: self.view.bounds.size.height - 40, width: self.view.bounds.size.width, height: 40)
        self.label.textAlignment = .center
        self.label.text = "default"
         self.label.font = UIFont.systemFont(ofSize: 20)
        self.label.textColor = UIColor.white
        self.label.backgroundColor = UIColor.black
        self.view.addSubview(self.label)
    }
    
    func start()
    {
        self.session.startRunning()
        self.videoConnect?.isEnabled = true
        
        defer {
            self.deviceOutput.setSampleBufferDelegate(self, queue: self.queue!)
        }
        
        guard let _ = self.queue else
        {
            self.queue = DispatchQueue.init(label: "videoQueue")
            return;
        }
    }
    
    func stop()
    {
        self.deviceOutput.setSampleBufferDelegate(nil, queue: nil)
        self.videoConnect?.isEnabled = false
        self.queue = nil
        self.session.stopRunning()
    }
    
    //ML
    func recognizeImage(_ image:UIImage?) -> String?
    {
        let model = Inceptionv3()
        
        if let scaledImage = self.scaleTo299(image), let buffer = self.buffer(withImage: scaledImage)
        {
           if let output = try? model.prediction(image: buffer)
           {
                return output.classLabel;
            }
        }
        
        return nil
    }
    
    //VN
    func detectImage(_ image:CMSampleBuffer)
    {
        if let buffer = CMSampleBufferGetImageBuffer(image)
        {
            let handler = VNImageRequestHandler.init(cvPixelBuffer: buffer, options: [:])
            //文本侦测
            let textDetectReq = VNDetectTextRectanglesRequest.init(completionHandler: { (req, error) in
                
                
                guard let results = (req as? VNDetectTextRectanglesRequest)?.results else { return }
                
                for obj in results
                {
                    if let observation = obj as? VNTextObservation , observation.confidence >= 0.3
                    {
                        self.addTextRectLayer(self.transformBoundingBox(observation.boundingBox))
                    }
                }
            })
            
            //人脸侦测
            let faceDetectReq = VNDetectFaceRectanglesRequest.init(completionHandler: { (req, error) in
                
                guard let results = (req as? VNDetectFaceRectanglesRequest)?.results else { return }
                
                for obj in results
                {
                    if let observation = obj as? VNFaceObservation , observation.confidence >= 0.3
                    {
                        self.addFaceRectLayer(self.transformBoundingBox(observation.boundingBox))
                    }
                }
            })
            
            let faceLandDetectReq = VNDetectFaceLandmarksRequest.init(completionHandler: { (req, error) in
                
                guard let results = (req as? VNDetectFaceLandmarksRequest)?.results else { return }
                
                for obj in results
                {
                    if let observation = obj as? VNFaceObservation ,
                        let points = observation.landmarks?.allPoints?.normalizedPoints
                    {
                        self.addPoints(points, boundingBox: observation.boundingBox)
                    }
                }
            })
            
            try?handler.perform([textDetectReq,faceDetectReq,faceLandDetectReq])
        }
    }
    
    func transformBoundingBox(_ boundingBox:CGRect) -> CGRect
    {
        var rect = CGRect.zero
        let frame = self.view.frame
        rect.size.width = frame.width * boundingBox.width
        rect.size.height = frame.height * boundingBox.height
        rect.origin.x = frame.width * boundingBox.minX
        rect.origin.y = frame.height - frame.height * boundingBox.minY - rect.height
        return rect
    }
    
    func transformLandmarkPoint(_ point:CGPoint , boundingBox:CGRect) -> CGPoint
    {
        let frame = self.view.frame
        
        let width = frame.width * boundingBox.width
        let height = frame.height * boundingBox.height
        let x = frame.width * boundingBox.minX
        let y = frame.height - frame.height * boundingBox.minY - height
        
        return CGPoint(x: x + point.x * width , y: y + (1 - point.y) * height)
    }
    
    func addTextRectLayer(_ frame:CGRect)
    {
        let layer = CALayer()
        layer.frame = frame
        layer.borderColor = UIColor.green.cgColor
        layer.borderWidth = 2
        DispatchQueue.main.async {
            self.view.layer.addSublayer(layer)
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
            layer.removeFromSuperlayer()
        }
    }
    
    func addFaceRectLayer(_ frame:CGRect)
    {
        let layer = CALayer()
        layer.frame = frame
        layer.borderColor = UIColor.red.cgColor
        layer.borderWidth = 2
        DispatchQueue.main.async {
            self.view.layer.addSublayer(layer)
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
            layer.removeFromSuperlayer()
        }
    }
    
    func addPoints(_ points:[CGPoint] , boundingBox:CGRect)
    {
        for point in points
        {
            let loc = self.transformLandmarkPoint(point, boundingBox: boundingBox)
            let layer = CALayer()
            layer.frame = CGRect.init(x: loc.x-0.75, y: loc.y-0.75, width: 2, height: 2)
            layer.backgroundColor = UIColor.red.cgColor
            
            DispatchQueue.main.async {
                self.view.layer.addSublayer(layer)
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                layer.removeFromSuperlayer()
            }
        }
    }
}

extension VisionViewController : AVCaptureVideoDataOutputSampleBufferDelegate
{
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        struct filter {
            static var flag = true
        }
        
        if filter.flag {
            filter.flag = false
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
                filter.flag = true
            })
            
            DispatchQueue.main.async {
                let image = self.image(withBuffer: sampleBuffer)
                self.label.text = self.recognizeImage(image);
                self.detectImage(sampleBuffer)
            }
        }
    }
}


