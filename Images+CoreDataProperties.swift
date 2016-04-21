//
//  Images+CoreDataProperties.swift
//  HingeTest
//
//  Created by Nanci Frank on 4/18/16.
//  Copyright © 2016 Wildcat Productions. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData
import UIKit

extension Images {

    @NSManaged var name: String?
    @NSManaged var imagedesc: String?
    @NSManaged var url: String?
    @NSManaged var image: UIImage?
    @NSManaged var thumb: UIImage?

}
