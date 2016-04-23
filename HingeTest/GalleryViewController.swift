//
//  GalleryViewController.swift
//  HingeTest
//
//  Created by Nanci Frank on 4/20/16.
//  Copyright © 2016 Wildcat Productions. All rights reserved.
//

import UIKit

protocol GalleryViewControllerDelegate {
    func didDeleteImageInGalleryViewController(viewController: GalleryViewController, atIndex: Int)
}

class GalleryViewController: UIViewController {
    
    var index: Int = 0
    var images = [Images]()
    var networkController: NetworkController?
    var timer = NSTimer()
    var removeBarButton: UIBarButtonItem?
    var delegate: GalleryViewControllerDelegate?
    
    lazy var pauseLabel: UILabel = {
        let frame = UIApplication.sharedApplication().keyWindow?.frame
        let labelRect = CGRect(x: 10, y: 80, width: (frame?.width)! - 20, height: 44)
        let pauseLabel = UILabel(frame: labelRect)
        pauseLabel.layer.cornerRadius = 15
        pauseLabel.clipsToBounds = true
        pauseLabel.textAlignment = .Center
        pauseLabel.backgroundColor = UIColor ( red: 0.8129, green: 0.8129, blue: 0.8129, alpha: 0.8 )
        pauseLabel.text = "Tap to pause and enable delete."
        pauseLabel.alpha = 0
        
        return pauseLabel
    }()
    
    var animationPaused: Bool = false

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = String("\(index + 1)\\\(images.count)" )
        self.imageView.alpha = 0
        self.imageView.image = images[index].image

        removeBarButton = UIBarButtonItem(title: "Delete", style: .Plain, target: self, action: #selector(deleteTapped))
        removeBarButton?.enabled = false
        removeBarButton?.tintColor = UIColor.lightGrayColor()
        self.navigationItem.rightBarButtonItem = removeBarButton
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pauseAnimation))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        
        self.view.addSubview(pauseLabel)
     }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        fadeInOut()
        timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(fadeInOut), userInfo: nil, repeats: true)
        showPauseHint("Tap to pause and enable delete.")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showPauseHint(message: String) {
        pauseLabel.text = message
        UIView.animateWithDuration(0.5, animations: {
            self.pauseLabel.alpha = 1
        }) { (done) in
            UIView.animateWithDuration(0.5, delay: 1, options: [.CurveEaseInOut], animations: {
                self.pauseLabel.alpha = 0
                }, completion: nil)
        }
    }
    
    func pauseAnimation(sender: UITapGestureRecognizer) {
        if !animationPaused {
            timer.invalidate()
            removeBarButton?.tintColor = UIColor.blackColor()
            removeBarButton!.enabled = true
            animationPaused = true
            showPauseHint("Tap to continue.")
        } else {
            removeBarButton?.tintColor = UIColor.lightGrayColor()
            removeBarButton!.enabled = false
            animationPaused = false
            timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(fadeInOut), userInfo: nil, repeats: true)
        }
    }
    
    func deleteTapped(sender: UIBarButtonItem) {
        self.delegate?.didDeleteImageInGalleryViewController(self, atIndex: index)
        let imageToDelete = images[index]
        images.removeAtIndex(index)
        networkController?.deleteImageObject(imageToDelete)
        index -= 1
        if index < 0 {
            index = images.count - 1
        }
        fadeInOut()
    }
    
    func getNextImage() -> Images {
        index += 1
        if index >= images.count {
            index = 0
        }
        self.navigationItem.title = String("\(index + 1)\\\(images.count)" )

        return images[index]
    }
    
    func fadeInOut() {
        let newAlpha = imageView.alpha == 0
        UIView.animateWithDuration(0.3, animations: {
            self.imageView.alpha = CGFloat(newAlpha)
            }) { (done) in
                if !newAlpha {
                    let image = self.getNextImage().image
                    self.imageView.image = image ?? UIImage(named: "ImageLoading")
                    self.fadeInOut()
                }
        }
    }

}
