//
//  HingeTestTests.swift
//  HingeTestTests
//
//  Created by Nanci Frank on 4/18/16.
//  Copyright © 2016 Wildcat Productions. All rights reserved.
//

import XCTest
@testable import HingeTest

class HingeTestTests: XCTestCase {
    
    var networkController: NetworkController?
    
    override func setUp() {
        super.setUp()
        
        networkController = NetworkController()
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        let managedObjectContext = appDelegate?.managedObjectContext
        networkController?.managedObjectContext = managedObjectContext
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // Test scaling large image
    func testScaledImage() {
        if let testImage = UIImage(named: "TestImage") {
            let scaledImage = networkController?.scaledImageFor(testImage, maxSize: 250)
            XCTAssertNotNil(scaledImage)
            if let size = scaledImage?.size {
                let maxEdge = max(size.height, size.width)
                XCTAssertTrue(maxEdge == 250)
            }
        }
        else {
            XCTAssert(true)
        }
    }
    
    // Test Core Data components of NetworkController
    func testNCCoreDataOperations() {
        let dictionary: [String: String] = ["imageName": "test-ImageName1", "imageDescription": "test-ImageDesc1", "imageURL": "http://somecompany.com/someimage.jpg"]
        networkController?.imageFromDictionary(dictionary)
        let predicate = NSPredicate(format: "name == %@ and imagedesc == %@ and url == %@", dictionary["imageName"]!, dictionary["imageDescription"]!, dictionary["imageURL"]!)
        let frc = networkController?.fetchedResultsController("Images", sortDescriptors: nil, predicate: predicate)
        XCTAssertNotNil(frc)
        XCTAssertTrue(frc?.fetchedObjects?.count == 1)
        if frc?.fetchedObjects?.count == 1 {
            let imageObj = frc?.fetchedObjects?.first as? Images
            XCTAssertNotNil(imageObj)
            networkController?.deleteImageObject(imageObj)
            do {
                try frc?.performFetch()
                XCTAssertTrue(frc?.fetchedObjects?.count == 0)
            }
            catch {
                XCTAssert(true)
            }
        } else {
            XCTAssert(true)
        }
    }
    
    // Test delete Core Data delete all
    func testNCCoreDataDeleteAllObjects() {
        let frc = networkController?.fetchedResultsController("Images")
        XCTAssertNotNil(frc)
        XCTAssertTrue(frc?.fetchedObjects?.count > 0)
        if frc?.fetchedObjects?.count > 0 {
            networkController?.deleteAllObjects()
            do {
                try frc?.performFetch()
                print("count: \(frc?.fetchedObjects?.count)")
                XCTAssertTrue(frc?.fetchedObjects?.count == 0)
            }
            catch {
                XCTAssert(true)
            }
        } else {
            XCTAssert(true)
        }

    }
    
    //Test performance of scaling image
    func testScaledImagePerformance() {
        // This is an example of a performance test case.
        self.measureBlock {
            if let testImage = UIImage(named: "TestImage") {
                _ = self.networkController?.scaledImageFor(testImage, maxSize: 250)
            }
        }
    }
    
}
