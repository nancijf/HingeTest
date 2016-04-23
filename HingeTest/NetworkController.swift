//
//  NetworkController.swift
//  HingeTest
//
//  Created by Nanci Frank on 4/19/16.
//  Copyright © 2016 Wildcat Productions. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class NetworkController: NSObject {
    
    typealias SuccessBlock = (image: [Images]) -> ()
    typealias ErrorBlock = (error: ErrorType) -> ()
    typealias ImageBlock = (image: UIImage?, thumbnail: UIImage?) -> ()
    
    var managedObjectContext: NSManagedObjectContext?
    var reachability: Reachability?
    var isNetworkAvailable: Bool = false
    var myPersistentStoreCoordinator: NSPersistentStoreCoordinator?
    
    lazy var imageCache: NSCache = {
        return NSCache()
    }()
    
    override init() {
        super.init()
        setupReachability(hostName: kHostname)
        startNotifier()
    }
    
    func loadImageData(onSuccess: SuccessBlock, onError: ErrorBlock) {
        
        // Check the DataStore. If no images returned get data from the network
        let imageArray = loadImageDataFromDataStore()
        if imageArray.count == 0 {
            loadImageDataFromNetwork(onSuccess, onError: onError)
        }
        else {
            onSuccess(image: imageArray)
        }
    }
    
    func loadImageDataFromNetwork(onSuccess: SuccessBlock, onError: ErrorBlock) {
        var images = [Images]()
        
        // Check for netowrk connection
        guard isNetworkAvailable else {
            NSNotificationCenter.defaultCenter().postNotificationName(kNetworkDownNotificationName, object: nil)
            return
        }
        let url = NSURL(string: kJSONFeedURL)
        guard let requestURL = url else { abort() }
        let session = NSURLSession.sharedSession()
        session.dataTaskWithURL(requestURL, completionHandler: {data, response, error -> Void in
            do {
                let jsonOptions: NSJSONReadingOptions = [.AllowFragments, .MutableLeaves, .MutableContainers]
                let photoArray = try NSJSONSerialization.JSONObjectWithData(data!, options: jsonOptions) as? [[String: String]]
                if let photos = photoArray {
                    for photo in photos {
                        if let imageObj = self.imageFromDictionary(photo) {
                            images.append(imageObj)
                            let index = images.indexOf(imageObj)
                            self.load(imageObj, onCompletion: { (image, thumbnail) in
                                imageObj.image = image
                                imageObj.thumb = thumbnail
                                self.saveCoreData()
                                NSNotificationCenter.defaultCenter().postNotificationName(kThumbnalLoadedNotificationName, object: thumbnail, userInfo: ["index": index!])
                            })
                        }
                    }
                    onSuccess(image: images)
                }
            } catch {
                print(error)
                onError(error: error)
            }
        }).resume()
    }
    
    func load(image: Images, onCompletion: ImageBlock) {
        
        guard let photoDict = self.imageCache.objectForKey(image.url!) as? [String: UIImage] else {
            let url = NSURL(string: image.url!)
            guard let requestURL = url else { abort() }
            let session = NSURLSession.sharedSession()
            session.dataTaskWithURL(requestURL, completionHandler: {imageData, response, error -> Void in
                if let httpResponse = response as? NSHTTPURLResponse {
                    // Check that successfully received data - response code 200
                    if imageData?.length > 0 && httpResponse.statusCode == 200 {
                        var photoDict = [String: UIImage]()
                        if let photo: UIImage = UIImage(data: imageData!) {
                            photoDict[kImageKey] = photo
                            photoDict[kThumbKey] = self.scaledImageFor(photo, maxSize: 300)
                            self.imageCache.setObject(photoDict, forKey: image.url!)
                            onCompletion(image: photoDict[kImageKey], thumbnail: photoDict[kThumbKey])
                        }
                    } else {
                        var photoDict = [String: UIImage]()
                        photoDict[kImageKey] = UIImage(named: "BrokenImage")
                        photoDict[kThumbKey] = UIImage(named: "BrokenImage")
                        self.imageCache.setObject(photoDict, forKey: image.url!)
                        onCompletion(image: photoDict[kImageKey], thumbnail: photoDict[kThumbKey])
                    }
                }
            }).resume()
            return
        }
        onCompletion(image: photoDict[kImageKey], thumbnail: photoDict[kThumbKey])
    }
    
    func scaledImageFor(photo: UIImage, maxSize: CGFloat) -> UIImage {
        let size = photo.size
        let maxEdge = max(size.height, size.width)
        let scale = 300 / maxEdge
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        let rect = CGRect(origin: CGPointZero, size: scaledSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, 1.0)
        photo.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func loadImageDataFromDataStore() -> [Images] {
        var images = [Images]()
        
        if let frc = self.fetchedResultsController("Images") {
            if frc.fetchedObjects?.count > 0 {
                images = frc.fetchedObjects as! [Images]
            }
        }
        
        return images
    }
    
    func imageFromDictionary(dictionary: [String: String]) -> Images? {
        
        if let imageObj = NSEntityDescription.insertNewObjectForEntityForName("Images", inManagedObjectContext: self.managedObjectContext!) as? Images {
            
            imageObj.setUpWithDictionary(dictionary)
            saveCoreData()
            
            return imageObj
        }
        
        return nil
    }
    
    func deleteImageObject(imageObj: Images? = nil) {
        if let imageEntity = imageObj {
            self.managedObjectContext?.deleteObject(imageEntity)
            
            // Save the context.
            saveCoreData()
        }
    }
    
    func deleteAllObjects() {
        let fetchRequest = NSFetchRequest(entityName: "Images")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try myPersistentStoreCoordinator?.executeRequest(deleteRequest, withContext: self.managedObjectContext!)
        } catch let error as NSError {
            print("an error occured \(error.localizedDescription)")
        }
    }
    
    func saveCoreData() {
        do {
            try self.managedObjectContext?.save()
        } catch let error as NSError {
            print("an error occured \(error.localizedDescription)")
        }
    }
    
    func fetchedResultsController(entityName: String, sortDescriptors: [NSSortDescriptor]? = nil, predicate: NSPredicate? = nil) -> NSFetchedResultsController? {
        
        var fetchedResultsController: NSFetchedResultsController?
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = []
        
        if let aFetchedResultsController: NSFetchedResultsController? = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil) {
            fetchedResultsController = aFetchedResultsController
            do {
                try fetchedResultsController!.performFetch()
            } catch let error as NSError {
                print("an error occured \(error.localizedDescription)")
            }
        }
        
        return fetchedResultsController
    }
    
    // MARK: - Reachability code to check for network connection
    
    func isConnectedToNetwork() -> Bool {
        guard let isReachable = self.reachability?.isReachable() else {
//            print("self.reachability is nil")
            return false
        }
        
        return isReachable
    }
    
    func setupReachability(hostName hostName: String?) {
        
//        print("--- set up with host name: \(hostName!)")
        
        do {
            let reachability = try hostName == nil ? Reachability.reachabilityForInternetConnection() : Reachability(hostname: hostName!)
            self.reachability = reachability
        } catch ReachabilityError.FailedToCreateWithAddress(_) {
//            print("network connection is not available")
            self.isNetworkAvailable = false
            return
        } catch {}
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: reachability)

    }
    
    func startNotifier() {
//        print("--- start notifier")
        do {
            try reachability?.startNotifier()
        } catch {
            self.isNetworkAvailable = false
            return
        }
    }
    
    func stopNotifier() {
//        print("--- stop notifier")
        reachability?.stopNotifier()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: nil)
        reachability = nil
    }

    
    func reachabilityChanged(note: NSNotification) {
        if let reachability = note.object as? Reachability {
            if reachability.isReachable() {
                self.isNetworkAvailable = true
            } else {
                self.isNetworkAvailable = false
            }
        }
    }
    
    // Remove NSNotificationCenter observers for Reachability and stop notifier that checks for network connection
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        stopNotifier()
    }

}



