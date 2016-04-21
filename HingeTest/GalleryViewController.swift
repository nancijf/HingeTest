//
//  GalleryViewController.swift
//  HingeTest
//
//  Created by Nanci Frank on 4/20/16.
//  Copyright © 2016 Wildcat Productions. All rights reserved.
//

import UIKit

class GalleryViewController: UIViewController {
    
    var index: Int = 0
    var images = [Images]()
    var networkController: NetworkController?
    var timer = NSTimer()


    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = String("\(index + 1)\\\(images.count)" )
        self.imageView.alpha = 0
        self.imageView.image = images[index].image

        let removeBarButton = UIBarButtonItem(title: "Delete", style: .Plain, target: self, action: #selector(deleteTapped))
        self.navigationItem.rightBarButtonItem = removeBarButton
     }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        fadeInOut()
        timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(fadeInOut), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func deleteTapped(sender: UIBarButtonItem) {
        print("delete button tapped")
        networkController?.deleteImageObject(images[index])
        images.removeAtIndex(index)
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
                    self.imageView.image = image
                    self.fadeInOut()
                }
        }
    }

}
