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
    
    // Show label for user to explain Pause and Delete images
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
        
        // Set title to image number and counter
        self.navigationItem.title = String("\(index + 1)\\\(images.count)" )
        self.imageView.alpha = 0
        self.imageView.image = images[index].image

        removeBarButton = UIBarButtonItem(title: "Delete", style: .Plain, target: self, action: #selector(deleteTapped))
        removeBarButton?.enabled = false
        removeBarButton?.tintColor = UIColor.lightGrayColor()
        self.navigationItem.rightBarButtonItem = removeBarButton
        
        // Set up tap gesture for Pause/Delete
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pauseAnimation))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        
        self.view.addSubview(pauseLabel)
     }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        fadeInOut()
        // Create timer for fading images
        timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(fadeInOut), userInfo: nil, repeats: true)
        showPauseHint("Tap to pause and enable delete.")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /**
     Shows user Pause/Delete label
     
     - parameter message: text for label
     */
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
    
    /**
     User tapped screen: check to Pause/Start image animation
     
     - parameter sender: tap gesture
     */
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
    
    /**
     Delete image from image array and core data
     
     - parameter sender: button tapped
     */
    func deleteTapped(sender: UIBarButtonItem) {
        self.delegate?.didDeleteImageInGalleryViewController(self, atIndex: index)
        let imageToDelete = images[index]
        images.removeAtIndex(index)
        networkController?.deleteImageObject(imageToDelete)
        
        // decrement index to account for deleted image and check if at beginning of array
        index -= 1
        if index < 0 {
            index = images.count - 1
        }
        fadeInOut()
    }
    
    /**
     Get next image in array to fade in
     
     - returns: next image
     */
    func getNextImage() -> Images {
        index += 1
        
        // If at end of array reset to start of array
        if index >= images.count {
            index = 0
        }
        self.navigationItem.title = String("\(index + 1)\\\(images.count)" )

        return images[index]
    }
    
    /**
     Fade out current image and fade in next one by setting alpha to 1 or 0
     */
    func fadeInOut() {
        let newAlpha = imageView.alpha == 0
        UIView.animateWithDuration(0.3, animations: {
            self.imageView.alpha = CGFloat(newAlpha)
            }) { (done) in
                // if newAlpha is false then get the next image to fade in
                if !newAlpha {
                    let image = self.getNextImage().image
                    // if image not finished downloading then put in temp image
                    self.imageView.image = image ?? UIImage(named: "ImageLoading")
                    self.fadeInOut()
                }
        }
    }

}
