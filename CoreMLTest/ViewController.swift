//
//  ViewController.swift
//  CoreMLTest
//
//  Created by Ever on 2017/9/16.
//  Copyright © 2017年 Ever. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, ImageConvertUtil{

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
    
    func recognizeImages(_ image:UIImage?) -> String?
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
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate
{
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        DispatchQueue(label:"recognizeImages").async {
            let image = self.image(withBuffer: sampleBuffer)
            let text = self.recognizeImages(image);
            DispatchQueue.main.async {
                self.label.text = text;
            }
        }
    }
}


