//
//  ViewController.swift
//  Animate
//
//  Created by Will Haley on 7/9/20.
//  Copyright © 2020 Will Haley. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {
    var videoWriter: VideoWriter?

    override func viewDidLoad() {
        self.videoWriter = VideoWriter.init()
        super.viewDidLoad()
    }

    @IBAction func click(_ sender: UIButton) {
        let images: [UIImage] = [
            UIImage(data:UIImage.init(named: "1")!.jpegData(compressionQuality: 1.0)!, scale:1.0)!,
            UIImage(data:UIImage.init(named: "2")!.jpegData(compressionQuality: 1.0)!, scale:1.0)!,
            UIImage(data:UIImage.init(named: "3")!.jpegData(compressionQuality: 1.0)!, scale:1.0)!,
            UIImage(data:UIImage.init(named: "4")!.jpegData(compressionQuality: 1.0)!, scale:1.0)!,
            UIImage(data:UIImage.init(named: "5")!.jpegData(compressionQuality: 1.0)!, scale:1.0)!,
            UIImage(data:UIImage.init(named: "6")!.jpegData(compressionQuality: 1.0)!, scale:1.0)!,
            UIImage(data:UIImage.init(named: "7")!.jpegData(compressionQuality: 1.0)!, scale:1.0)!,
        ]

        // The image sizes are consistent. Use the first one to determine the video size. 3024 × 4032
        let originalSize = images[0].size

        // This fails. ❌
//        let outputSize = CGSize(width: originalSize.width, height: originalSize.height)

        // This fails. ❌
//        let outputSize = CGSize(width: originalSize.width - 512, height: originalSize.height - 509)

        // This fails. ❌
//        let outputSize = CGSize(width: originalSize.width - 511, height: originalSize.height - 510)

        // This works. ✅ We could go smaller and keep the aspect ratio, but the specific numbers
        // for the cutoff seem worth nothing here.
        let outputSize = CGSize(width: originalSize.width - 512, height: originalSize.height - 510)

        print("outputSize \(outputSize)")

        self.videoWriter!.buildVideoFromImageArray(videoFilename: "output", images: images, size: outputSize) { (url: URL) in
            self.saveVideoToAlbum(url) { (error: Error?) in
                print("error saving to album \(String(describing: error))")
            }
        }
    }

    func requestAuthorization(completion: @escaping ()->Void) {
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else if PHPhotoLibrary.authorizationStatus() == .authorized{
            completion()
        }
    }

    func saveVideoToAlbum(_ outputURL: URL, _ completion: ((Error?) -> Void)?) {
        requestAuthorization {
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .video, fileURL: outputURL, options: nil)
            }) { (result, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        print("Saved successfully")
                    }
                    completion?(error)
                }
            }
        }
    }
}
