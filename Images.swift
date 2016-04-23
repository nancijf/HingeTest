//
//  Images.swift
//  HingeTest
//
//  Created by Nanci Frank on 4/18/16.
//  Copyright © 2016 Wildcat Productions. All rights reserved.
//

import Foundation
import CoreData


class Images: NSManagedObject {

    func setUpWithDictionary(dictionary: [String: String]) {
        self.name = dictionary["imageName"]
        self.imagedesc = dictionary["imageDescription"]
        self.url = dictionary["imageURL"]
    }
    
}
