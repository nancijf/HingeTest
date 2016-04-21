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

let kImageKey = "image"
let kThumbKey = "thumb"

class NetworkController: NSObject {
    
    typealias SuccessBlock = (image: [Images]) -> ()
    typealias ErrorBlock = (error: ErrorType) -> ()
    typealias ImageBlock = (image: UIImage?, thumbnail: UIImage?) -> ()
    
    var managedObjectContext: NSManagedObjectContext?
    
    lazy var imageCache: NSCache = {
        return NSCache()
    }()
    
    lazy var thumbCache: NSCache = {
        return NSCache()
    }()
    
    func loadImageData(onSuccess: SuccessBlock, onError: ErrorBlock) {
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
        
        let url = NSURL(string: "https://hinge-homework.s3.amazonaws.com/client/services/homework.json")
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
                                self.saveData()
                                NSNotificationCenter.defaultCenter().postNotificationName("thumbnailUpdateAvailable", object: thumbnail, userInfo: ["index": index!])
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
    
    func saveData() {
        do {
            try self.managedObjectContext?.save()
        } catch {
            print(error)
        }
        
    }
    
    func load(image: Images, onCompletion: ImageBlock) {
        
        guard let photoDict = self.imageCache.objectForKey(image.url!) as? [String: UIImage] else {
            let url = NSURL(string: image.url!)
            guard let requestURL = url else { abort() }
            let session = NSURLSession.sharedSession()
            session.dataTaskWithURL(requestURL, completionHandler: {imageData, response, error -> Void in
//                print(response)
                if let httpResponse = response as? NSHTTPURLResponse {
                    print("response code: \(httpResponse.statusCode)")
                    if imageData?.length > 0 && httpResponse.statusCode == 200 {
                        var photoDict = [String: UIImage]()
                        if let photo: UIImage = UIImage(data: imageData!) {
                            print("image is fine")
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
            print("Name: \(dictionary["imageName"])")
            print("URL: \(dictionary["imageURL"])")
            print("Description: \(dictionary["imageDescription"])")
            
            imageObj.name = dictionary["imageName"]
            imageObj.imagedesc = dictionary["imageDescription"]
            imageObj.url = dictionary["imageURL"]
            
            do {
                try self.managedObjectContext?.save()
                return imageObj
            } catch {
                abort()
            }
            
        }
        
        return nil
    }
    
    func fetchedResultsController(entityName: String, sortDescriptors: [NSSortDescriptor]? = nil, predicate: NSPredicate? = nil) -> NSFetchedResultsController? {
        
        var fetchedResultsController: NSFetchedResultsController?
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
//        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = []
//        fetchRequest.predicate = predicate
        
        if let aFetchedResultsController: NSFetchedResultsController? = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil) {
            fetchedResultsController = aFetchedResultsController
            do {
                try fetchedResultsController!.performFetch()
            } catch {
                abort()
            }
        }
        
        return fetchedResultsController
    }


}



