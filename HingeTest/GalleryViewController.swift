//
//  GalleryViewController.swift
//  HingeTest
//
//  Created by Nanci Frank on 4/20/16.
//  Copyright © 2016 Wildcat Productions. All rights reserved.
//

import UIKit

class GalleryViewController: UIViewController {
    
    var imageToDisplay: UIImage?
    var imageLoc: Int?
    var imageCount: Int?
    var images = [Images]()
    var networkController: NetworkController?


    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let imageLoc = imageLoc, imageCount = imageCount {
            self.navigationItem.title = String("\(imageLoc)\\\(imageCount)" )
        }
        imageView.image = imageToDisplay
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
