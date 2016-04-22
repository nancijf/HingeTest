//
//  ImageCollectionViewController.swift
//  HingeTest
//
//  Created by Nanci Frank on 4/18/16.
//  Copyright © 2016 Wildcat Productions. All rights reserved.
//

import UIKit

private let kReuseIdentifier = "ImageCell"

class ImageCollectionViewController: UICollectionViewController {
    
    var images = [Images]()
    var networkController: NetworkController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadData() {
        networkController?.loadImageData({ (images) in
            print("isMainThread: \(NSThread.isMainThread())")
            if NSThread.isMainThread() {
                self.images = images
                self.collectionView?.reloadData()
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    print("in CollectionVC images: \(images)")
                    self.images = images
                    self.collectionView?.reloadData()
                })
            }
            }, onError: { (error) in
                print(error)
        })
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let indexPath = self.collectionView?.indexPathForCell((sender as? UICollectionViewCell)!) {
            if segue.identifier == "galleryImageView" {
                if let cell: ImageCollectionViewCell = sender as? ImageCollectionViewCell, let destinationViewController: GalleryViewController = segue.destinationViewController as? GalleryViewController {
                    destinationViewController.index = indexPath.item
                    destinationViewController.networkController = networkController
                    destinationViewController.images = images
                }
            }
        }
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let kWhateverHeightYouWant = ((UIApplication.sharedApplication().keyWindow?.frame.width)! / 3) - 4
        return CGSizeMake(CGFloat(kWhateverHeightYouWant), CGFloat(kWhateverHeightYouWant))
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(kReuseIdentifier, forIndexPath: indexPath) as! ImageCollectionViewCell
    
        // Configure the cell
        // tag the cell with indexPath.item
        
        cell.tag = indexPath.item
        
        if let thumb = self.images[indexPath.item].thumb {
            print("thumb: \(thumb)")
            cell.imageView.image = thumb
        }
//        else {
//            networkController?.load(images[indexPath.item], onCompletion: { (image, thumbnail) in
//                print("isMainThread: \(NSThread.isMainThread())")
//                dispatch_async(dispatch_get_main_queue(), {
//                    cell.imageView.image = thumbnail
//                })
//            })
//        }
    
        return cell
    }
    
//    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
//            performSegueWithIdentifier("galleryImageView", sender: cell)
//        }
//    }


    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateThumbImage), name: "thumbnailUpdateAvailable", object: nil)
    }
    
    func updateThumbImage(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject], index = userInfo["index"] where index.integerValue == self.tag {
            if let image = notification.object as? UIImage {
                dispatch_async(dispatch_get_main_queue(), {
                    print("index: \(index)")
                    self.imageView.image = image
                })
            }
        }
    }
    
    override func prepareForReuse() {
        imageView.image = nil
    }
    
}

