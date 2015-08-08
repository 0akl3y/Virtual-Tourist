//
//  Image.swift
//  Virtual Tourist
//
//  Created by Johannes Eichler on 25.07.15.
//  Copyright (c) 2015 Eichler. All rights reserved.
//

import Foundation
import CoreData

struct ImagePropertyKey {
    
    static let Title = "title"
    static let FileURL = "fileURL"
    static let ID = "id"

}

class Image: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var fileURL: String
    @NSManaged var id: String
    @NSManaged var dateAdded: NSDate
    @NSManaged var pin: Pin
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
    }
    
    init(imageProperties:[String: AnyObject]){
        
        let entity = NSEntityDescription.entityForName("Image", inManagedObjectContext: CoreDataStack.sharedObject().managedObjectContext!)
        
        super.init(entity: entity!, insertIntoManagedObjectContext: CoreDataStack.sharedObject().managedObjectContext!)
        
        self.title = imageProperties[ImagePropertyKey.Title] as! String
        self.fileURL = imageProperties[ImagePropertyKey.FileURL] as! String
        self.id = imageProperties[ImagePropertyKey.ID] as! String
        self.dateAdded = NSDate()
    
    }
}