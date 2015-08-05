//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Johannes Eichler on 25.07.15.
//  Copyright (c) 2015 Eichler. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class Pin: NSManagedObject, MKAnnotation {
    

    @NSManaged var longitude: Double
    @NSManaged var latitude: Double
    @NSManaged var lastPage: Int32
    
    @NSManaged var images: NSOrderedSet
    
    var expectedImages:Int?
    var totalPages:Int?
    
    var coordinate: CLLocationCoordinate2D {
        
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    init(coordinate:CLLocationCoordinate2D){
        
        var entityDescription = NSEntityDescription.entityForName("Pin", inManagedObjectContext: CoreDataStack.sharedObject().managedObjectContext!)
        
        super.init(entity: entityDescription!, insertIntoManagedObjectContext: CoreDataStack.sharedObject().managedObjectContext!)
        
        self.longitude = coordinate.longitude
        self.latitude = coordinate.latitude
        self.lastPage = 1
    
    }    
    
    //MKAnnotationDelegateMethods
    

    func setCoordinate(coordinate: CLLocationCoordinate2D){
        
        self.willChangeValueForKey("coordinate")
        self.longitude = coordinate.longitude
        self.latitude = coordinate.latitude
        self.didChangeValueForKey("coordinate")
    }

}
