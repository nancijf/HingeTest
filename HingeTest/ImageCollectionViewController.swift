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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showNetworkAlert), name: "com.nancifrank.NetworkIsDown", object: nil)
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
//            print("isMainThread: \(NSThread.isMainThread())")
            if NSThread.isMainThread() {
                self.images = images
                self.collectionView?.reloadData()
            } else {
                dispatch_async(dispatch_get_main_queue(), {
//                    print("in CollectionVC images: \(images)")
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
        
    
        // Configure the cell
        // tag the cell with indexPath.item
        cell.tag = indexPath.item
        
        if let thumb = self.images[indexPath.item].thumb {
            cell.activityIndicator.stopAnimating()
            cell.imageView.image = thumb
        }
    
        return cell
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateThumbImage), name: "thumbnailUpdateAvailable", object: nil)
    }
    
    override func awakeFromNib() {
        self.activityIndicator.startAnimating()
    }
    
    func updateThumbImage(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject], index = userInfo["index"] where index.integerValue == self.tag {
            if let image = notification.object as? UIImage {
                dispatch_async(dispatch_get_main_queue(), {
                    self.imageView.image = image
                    self.activityIndicator.stopAnimating()
                })
            }
        }
    }
    
    override func prepareForReuse() {
        imageView.image = nil
    }
    
}

