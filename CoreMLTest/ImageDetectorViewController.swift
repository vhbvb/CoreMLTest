//
//  ImageDetectorViewController.swift
//  CoreMLTest
//
//  Created by Max on 2018/11/15.
//  Copyright © 2018 Ever. All rights reserved.
//

import UIKit
import WebKit

class ImageDetectorViewController: UIViewController,ImageConvertUtil {
    
    lazy var webView:WKWebView = {
        let web = WKWebView(frame: view.bounds)
        web.load(URLRequest(url: URL(string: "https://image.baidu.com")!))
        web.navigationDelegate = self
        return web
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.green
        view.addSubview(webView)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "预测", style: .plain, target: self, action: #selector(self.onTap))
    }
    
    @objc func onTap()
    {
        var title = "default"
        if let result = detect() {
            if result.0.contains("daisy")
            {
                title = "雏菊"
            }
            else if result.0.contains("roses")
            {
                title = "玫瑰"
            }
            else if result.0.contains("dandelion")
            {
                title = "蒲公英"
            }
            else if result.0.contains("sunflowers")
            {
                title = "向日葵"
            }
            else if result.0.contains("tulips")
            {
                title = "郁金香"
            }
            
            let alert = UIAlertController(title:title , message: "准确度:\(String(format: "%%%.2f", result.1! * 100.0))", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func detect() -> (String, Double?)?
    {
        if let image = nomalSnapshotImage(), let scaledImage = self.scaleTo299(image), let buffer = self.buffer(withImage: scaledImage)
        {
//            let imageView = UIImageView(image: image)
//            imageView.center = view.center;
//            let bg = UIView(frame: view.bounds)
//            bg.backgroundColor = UIColor.red
//            bg.addSubview(imageView)
//            view.addSubview(bg)
            
            
            let classifier = ImageClassifier()
            if let output = try? classifier.prediction(image: buffer)
            {
                return (output.classLabel,output.classLabelProbs[output.classLabel]);
            }
        }
        
        return nil
    }
    
    func nomalSnapshotImage() -> UIImage? {
        
        let rect = CGRect(origin: CGPoint(x: 0, y: ((view.frame.height - 110.0)/2.0 + 110.0 - view.frame.width)), size: CGSize(width: view.frame.width, height: view.frame.width))
            
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 1.0);
        if let current = UIGraphicsGetCurrentContext(){
            view.layer.render(in: current)
            if let image = UIGraphicsGetImageFromCurrentImageContext(),
                let originCGImage = image.cgImage,
                let conventedCGImage = originCGImage.cropping(to: rect)
            {
                return UIImage(cgImage: conventedCGImage)
            }
        }
        UIGraphicsEndImageContext()
        return nil
    }
}

extension ImageDetectorViewController:WKNavigationDelegate
{
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        print("------------->\(String(describing: navigationAction.request.url))")
        
        decisionHandler(.allow)
    }
}
