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

class ViewController: UIViewController, ImageConvertUtil{

    var capView = UIView()
    var previewLayer:AVCaptureVideoPreviewLayer!
    var session = AVCaptureSession()
    var deviceOutput = AVCaptureVideoDataOutput()
    
    var videoConnect:AVCaptureConnection?
    var label = UILabel()
    var queue : DispatchQueue?
    
    lazy var textRectView = { () -> UIView in
        
        let view = UIView()
        view.layer.borderWidth = 1.5;
        view.layer.borderColor = UIColor.green.cgColor
        view.isHidden = true
        return view;
    }()
    
    lazy var faceRectView = { () -> UIView in
        
        let view = UIView()
        view.layer.borderWidth = 1.5;
        view.layer.borderColor = UIColor.red.cgColor
        view.isHidden = true
        return view;
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
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
        
        self.view.addSubview(self.textRectView)
        self.view.addSubview(self.faceRectView)
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
                print("---------------> res : \(output.classLabel)")
                return output.classLabel;
            }
        }
        
        return nil
    }
    
    //VN
    func detectImage(_ image:UIImage?)
    {
        if let sourceImg = image , let buffer = self.buffer(withImage: sourceImg)
        {
            let handler = VNImageRequestHandler.init(cvPixelBuffer: buffer, options: [:])
            //文本侦测
            let textDetectReq = VNDetectTextRectanglesRequest.init(completionHandler: { (req, error) in
                
                
                guard let results = (req as? VNDetectTextRectanglesRequest)?.results else { return }
                
                guard let observation = results.first as? VNTextObservation else { return }
                
                DispatchQueue.main.async {
                    guard observation.confidence >= 0.3 else {
                        self.textRectView.isHidden = true
                        return
                    }
                    
                    self.textRectView.isHidden = false;
                    self.textRectView.frame = self._transformBoundingBox(observation.boundingBox)
                }
            })
            
            //人脸侦测
            let faceDetectReq = VNDetectFaceRectanglesRequest.init(completionHandler: { (req, error) in
                
                guard let results = (req as? VNDetectFaceRectanglesRequest)?.results else { return }
                
                guard let observation = results.first as? VNFaceObservation else { return }
                
                DispatchQueue.main.async {
                    guard observation.confidence >= 0.3 else {
                        self.faceRectView.isHidden = true
                        return
                    }
                    
                    self.faceRectView.isHidden = false;
                    self.faceRectView.frame = self._transformBoundingBox(observation.boundingBox)
                }
            })
            
//            let faceLandDetectReq = VNDetectFaceLandmarksRequest.init(completionHandler: { (req, error) in
//                print("Req:\n\(String(describing: req.results))\nError:\(String(describing: error))")
//            })
            
            try?handler.perform([textDetectReq,faceDetectReq])
        }
    }
    
    func _transformBoundingBox(_ boundingBox:CGRect) -> CGRect
    {
        var rect = CGRect.zero
        let frame = self.view.frame
        rect.size.width = frame.width * boundingBox.width
        rect.size.height = frame.height * boundingBox.height
        rect.origin.x = frame.width * boundingBox.minX
        rect.origin.y = frame.height - frame.height * boundingBox.minY - rect.height
        return rect
    }
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate
{
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        DispatchQueue(label:"sampleBuffer").async {
            let image = self.image(withBuffer: sampleBuffer)
            let text = self.recognizeImage(image);
            self.detectImage(image)
            DispatchQueue.main.async {
                self.label.text = text;
            }
        }
    }
}


