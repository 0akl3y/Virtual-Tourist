//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Johannes Eichler on 21.07.15.
//  Copyright (c) 2015 Eichler. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate{
    
    var pinInFocus:Pin?
    var controller:NSFetchedResultsController?
    var imagesController:NSFetchedResultsController?
    var flickerClient: FlickerClient = FlickerClient()


    @IBOutlet var longTapGesture: UILongPressGestureRecognizer!
    var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer()
    
    @IBOutlet var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        self.longTapGesture.delegate = self
        self.fetchPins()

        // Do any additional setup after loading the view.
    }
        
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchPins(){
        
        var error:NSError? = nil
        
        // fetchRequest to fetch all pins
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        self.controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedObject().managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        
        self.controller?.delegate = self
        self.controller?.performFetch(&error)
        
        if(error != nil){
            
            println("There was an error fetching all pins: \(error)")
            
        }
    }
    
    
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView!) {
        
        for pinObject in self.controller!.fetchedObjects as! [Pin]{
            
            mapView.addAnnotation(pinObject)
            
        }

    }
    
    func convertTapToPosition(tapPosition: CGPoint) -> CLLocationCoordinate2D{
        //convert the tapPosition to the correct coordinate
        
        return self.mapView.convertPoint(tapPosition, toCoordinateFromView: self.mapView)
   
    }
    
    
    @IBAction func longTapMap(sender: UILongPressGestureRecognizer) {
        
        let tapPosition:CGPoint = sender.locationInView(self.mapView)
        let positionOnMap = self.convertTapToPosition(tapPosition)
        
        switch(sender.state){
            
            case UIGestureRecognizerState.Began:
                
                self.pinInFocus = Pin(coordinate: positionOnMap)
                self.mapView.addAnnotation(self.pinInFocus!)
                break
            
            case UIGestureRecognizerState.Changed:
                
                self.pinInFocus?.setCoordinate(positionOnMap)            

            case UIGestureRecognizerState.Ended:
                            
                flickerClient.fetchPinFromFlickr(self.pinInFocus!, entriesPerPage: 20, page: 1)
            
            default:
                
                return
        
        }        

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if(segue.identifier == "pictures"){
            
            var photoVC = segue.destinationViewController as! PhotoAlbumViewController
            photoVC.fetchedImagesController = sender!.imagesController!
            photoVC.selectedPin = sender!.pinInFocus
            photoVC.flickerClient = sender!.flickerClient
        
        }
    }
    

    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        
        let annotationView = views[0] as! MKAnnotationView
        let selectedPin = annotationView.annotation as! Pin
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        self.pinInFocus = view.annotation as? Pin
        self.performSegueWithIdentifier("pictures", sender: self)
        
    }


}
