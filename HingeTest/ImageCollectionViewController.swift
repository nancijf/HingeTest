//
//  ImageCollectionViewController.swift
//  HingeTest
//
//  Created by Nanci Frank on 4/18/16.
//  Copyright © 2016 Wildcat Productions. All rights reserved.
//

import UIKit

private let kReuseIdentifier = "ImageCell"

class ImageCollectionViewController: UICollectionViewController, GalleryViewControllerDelegate {
    
    var images = [Images]()
    var networkController: NetworkController?
    lazy var refreshControl: UIRefreshControl = {
        return UIRefreshControl()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Image Collection"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showNetworkAlert), name: kNetworkDownNotificationName, object: nil)
        refreshControl.addTarget(self, action: #selector(refreshData), forControlEvents: .ValueChanged)
        self.collectionView!.addSubview(refreshControl)
        loadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView?.reloadData()
    }
    
    func refreshData(refreshControl: UIRefreshControl) {
        if let networkAvailable = networkController?.isNetworkAvailable where networkAvailable {
            self.images.removeAll()
            collectionView?.reloadData()
            networkController?.deleteAllObjects()
            loadData()
        }
        refreshControl.endRefreshing()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        print("received memory warning")
    }
    
    func showNetworkAlert(notification: NSNotification) {
        let alert = UIAlertController(title: "Alert", message: "Sorry. Network not available at this time.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func loadData() {
        networkController?.loadImageData({ (images) in
            if NSThread.isMainThread() {
                self.images = images
                self.collectionView?.reloadData()
            } else {
                dispatch_async(dispatch_get_main_queue(), {
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
                if let destinationViewController: GalleryViewController = segue.destinationViewController as? GalleryViewController {
                    destinationViewController.index = indexPath.item
                    destinationViewController.networkController = networkController
                    destinationViewController.images = images
                    destinationViewController.delegate = self
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
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let kWhateverHeightYouWant = ((UIApplication.sharedApplication().keyWindow?.frame.width)! / 3) - 4
        return CGSizeMake(CGFloat(kWhateverHeightYouWant), CGFloat(kWhateverHeightYouWant))
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(kReuseIdentifier, forIndexPath: indexPath) as! ImageCollectionViewCell
        
        // tag the cell with indexPath.item
        cell.tag = indexPath.item
        
        // Update cell with thumbnail when available
        if let thumb = self.images[indexPath.item].thumb {
            cell.activityIndicator.stopAnimating()
            cell.imageView.image = thumb
        } else {
            cell.imageView.image = UIImage(named: "ImageLoading")
            cell.activityIndicator.startAnimating()
            cell.isLoading = true
        }
    
        return cell
    }
    
    // alert user image still loading when tap on cell if not completed
    func loadingAlert() {
        let alert = UIAlertController(title: "Alert", message: "Slideshow unavailable. Image still loading...", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        presentViewController(alert, animated: true, completion: { () -> Void in
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                alert.dismissViewControllerAnimated(true, completion: nil)
            }
        })
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImageCollectionViewCell
        if cell.isLoading {
            loadingAlert()
        } else {
            performSegueWithIdentifier("galleryImageView", sender: cell)
        }
    }
    
    // MARK: GalleryViewControllerDelegate
    
    func didDeleteImageInGalleryViewController(viewController: GalleryViewController, atIndex: Int) {
        images.removeAtIndex(atIndex)
        collectionView?.reloadData()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var isLoading: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateThumbImage), name: kThumbnalLoadedNotificationName, object: nil)
    }
    
    // Run function when receive Notification image is finished downloading
    func updateThumbImage(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject], index = userInfo["index"] where index.integerValue == self.tag {
            if let image = notification.object as? UIImage {
                dispatch_async(dispatch_get_main_queue(), {
                    self.activityIndicator.stopAnimating()
                    self.isLoading = false
                    self.imageView.image = image
                })
            }
        }
    }
    
    override func prepareForReuse() {
        imageView.image = nil
        self.isLoading = false
        self.activityIndicator.stopAnimating()
    }
    
}

