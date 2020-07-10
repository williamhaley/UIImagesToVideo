//
//  VideoWriter.swift
//  changes
//
//  Created by Will Haley on 7/9/20.
//  Copyright © 2020 Will Haley. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import Photos

class VideoWriter {
    let imagesPerSecond: TimeInterval = 2

    func buildVideoFromImageArray(videoFilename: String, images: [UIImage], size: CGSize, completion: @escaping (URL) -> Void) {
        var outputURL: URL {
            let fileManager = FileManager.default
            if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                return tmpDirURL.appendingPathComponent(videoFilename).appendingPathExtension("mp4")
            }
            fatalError("URLForDirectory() failed")
        }

        do {
            try FileManager.default.removeItem(atPath: outputURL.path)
        } catch _ as NSError {
            // Assume file didn't already exist.
        }

        self.animateImages(outputSize: size, outputURL: outputURL, images: images, completion: completion)
    }

    func animateImages(outputSize: CGSize, outputURL: URL, images: [UIImage], completion: @escaping (URL) -> Void) {
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4) else {
            fatalError("AVAssetWriter error")
        }

        let outputSettings = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : NSNumber(value: Float(outputSize.width)),
            AVVideoHeightKey : NSNumber(value: Float(outputSize.height))
        ] as [String : Any]

        guard videoWriter.canApply(outputSettings: outputSettings, forMediaType: AVMediaType.video) else {
            fatalError("Negative : Can't apply the Output settings...")
        }

        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: Float(outputSize.width)),
                kCVPixelBufferHeightKey as String: NSNumber(value: Float(outputSize.height))
            ]
        )

        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }

        if videoWriter.startWriting() {
            let zeroTime = CMTimeMake(value: Int64(imagesPerSecond),timescale: Int32(1))
            videoWriter.startSession(atSourceTime: zeroTime)

            assert(pixelBufferAdaptor.pixelBufferPool != nil)

            let media_queue = DispatchQueue(label: "mediaInputQueue")
            videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
                let fps: Int32 = 1
                let framePerSecond: Int64 = Int64(self.imagesPerSecond)
                let frameDuration = CMTimeMake(value: Int64(self.imagesPerSecond), timescale: fps)
                var frameCount: Int64 = 0
                var appendSucceeded = true
                for image in images {
                    if (videoWriterInput.isReadyForMoreMediaData) {
                        let lastFrameTime = CMTimeMake(value: frameCount * framePerSecond, timescale: fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        // Ownership of this follows the "Create Rule" but that is auto-managed in Swift so we do not need to release.
                        var pixelBuffer: CVPixelBuffer? = nil
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                        // Validate that the pixelBuffer is not nil and the status is 0
                        if let pixelBuffer = pixelBuffer, status == 0 {
                            self.drawImage(pixelBuffer: pixelBuffer, outputSize: outputSize, image: image)

                            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                        } else {
                            print("Failed to allocate pixel buffer")
                            appendSucceeded = false
                        }
                    }
                    if !appendSucceeded {
                        print("Failed to append to pixel buffer!")
                        break
                    }
                    frameCount += 1
                }

                videoWriterInput.markAsFinished()
                videoWriter.finishWriting { () -> Void in
                    completion(outputURL)
                }
            })
        }
    }

    func drawImage(pixelBuffer: CVPixelBuffer, outputSize: CGSize, image: UIImage) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let pxdata = CVPixelBufferGetBaseAddress(pixelBuffer)
        let context = CGContext(
            data: pxdata,
            width: Int(outputSize.width),
            height: Int(outputSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )

        let rect = CGRect(x: 0, y: 0, width: CGFloat(outputSize.width), height: CGFloat(outputSize.height))
        context!.clear(rect)

        context!.translateBy(x: 0, y: outputSize.height)
        context!.scaleBy(x: 1, y: -1)

        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height))
        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    }
}
