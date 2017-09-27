//
//  ImageUtil.swift
//  CoreMLTest
//
//  Created by Ever on 2017/9/27.
//  Copyright © 2017年 Ever. All rights reserved.
//

import AVFoundation
import UIKit

protocol ImageConvertUtil
{
    func image(withBuffer buffer:CMSampleBuffer) -> UIImage?
    
    func buffer(withImage image:UIImage?) -> CVPixelBuffer?
    
    func scaleTo299(_ image:UIImage?) -> UIImage?;
}


extension ImageConvertUtil
{
    func image(withBuffer buffer:CMSampleBuffer) -> UIImage?
    {
        if let imageBuffer = CMSampleBufferGetImageBuffer(buffer)
        {
            CVPixelBufferLockBaseAddress(imageBuffer, .init(rawValue: 0))
            
            let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
            
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            
            let width = CVPixelBufferGetWidth(imageBuffer)
            
            let height = CVPixelBufferGetHeight(imageBuffer)
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: 8194)
            
            let imageRef = context?.makeImage()
            
            CVPixelBufferUnlockBaseAddress(imageBuffer, .init(rawValue: 0))
            
            if let ref = imageRef
            {
                return UIImage.init(cgImage: ref)
            }
        }
        
        return nil;
    }
    
    func buffer(withImage image:UIImage?) -> CVPixelBuffer?
    {
        if let imageRef = image?.cgImage
        {
            let width = imageRef.width
            
            let height = imageRef.height
            
            let options = [kCVPixelBufferCGImageCompatibilityKey:true,
                           kCVPixelBufferCGBitmapContextCompatibilityKey:true]
            
            var pixelbuffer : CVPixelBuffer?
            
            guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, 0x00000020, options as CFDictionary, &pixelbuffer) == 0 else
            {
                return nil
            }
            
            if let buffer = pixelbuffer
            {
                CVPixelBufferLockBaseAddress(buffer, .init(rawValue: 0))
                let pxdata = CVPixelBufferGetBaseAddressOfPlane(buffer, 0)
                
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                
                if let context = CGContext(data: pxdata,
                                           width: width,
                                           height: height,
                                           bitsPerComponent: 8,
                                           bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                           space: colorSpace,
                                           bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
                {
                    context.concatenate(CGAffineTransform.identity)
                    
                    context.draw(imageRef, in: CGRect.init(x: 0, y: 0, width: width, height: height))
                    
                    CVPixelBufferUnlockBaseAddress(buffer, .init(rawValue: 0));
                    
                    return buffer;
                }
            }
        }
        
        return nil
    }
    
    func scaleTo299(_ image:UIImage?) -> UIImage?
    {
        UIGraphicsBeginImageContext(CGSize.init(width: 299.0, height: 299.0))
        
        image?.draw(in: CGRect.init(x: 0, y: 0, width: 299.0, height: 299.0))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}
