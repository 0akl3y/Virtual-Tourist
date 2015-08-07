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

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate, FlickerClientDelegate{
    
    var pinInFocus:Pin?
    var controller:NSFetchedResultsController?
    var imagesController:NSFetchedResultsController?
    var flickerClient: FlickerClient = FlickerClient()
    var deleteMode = false
    let imageCache = ImageCache()

    @IBOutlet var editButton: UIBarButtonItem!

    @IBOutlet var longTapGesture: UILongPressGestureRecognizer!
    var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer()
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var deleteStatusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        self.longTapGesture.delegate = self
        self.flickerClient.delegate = self
        self.fetchPins()
        

        // Do any additional setup after loading the view.
    }
        
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.presentedViewController?.removeFromParentViewController()
        
        
        self.pinInFocus = nil
        self.deleteStatusLabel.hidden = true
        
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
        
        if(self.deleteMode){return}
        
        switch(sender.state){
            
            case UIGestureRecognizerState.Began:
                
                self.pinInFocus = Pin(coordinate: positionOnMap) as Pin
                self.mapView.addAnnotation(self.pinInFocus!)
                break
            
            case UIGestureRecognizerState.Changed:
                
                self.pinInFocus?.setCoordinate(positionOnMap)            

            case UIGestureRecognizerState.Ended:
                            
                flickerClient.fetchPinFromFlickr(self.pinInFocus!, entriesPerPage: 20, page: 1)
                self.controller?.performFetch(nil)
            
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
        self.mapView.deselectAnnotation(self.pinInFocus, animated: false)
        
        
        if(self.deleteMode){
            
            self.removePinFromStore(self.pinInFocus!)
            return
            
        }
        
        
        self.performSegueWithIdentifier("pictures", sender: self)
        
    }
    
    func removePinFromStore(pin:Pin){
        
        //Remove pin and related images from store and from the map.
        
        for elm in self.controller?.fetchedObjects as! [Pin]{
            
            if((elm.coordinate.latitude == pin.coordinate.latitude) && (pin.coordinate.longitude == elm.coordinate.longitude)){
                
                for img in elm.images {
                    
                    let currentImg = img as! Image
                    
                    self.imageCache.storeImage(currentImg.id, image: nil, completion: nil)
                    CoreDataStack.sharedObject().managedObjectContext?.deleteObject(img as! Image)
                }
                
                CoreDataStack.sharedObject().managedObjectContext?.deleteObject(elm)
                CoreDataStack.sharedObject().saveContext()
                
                self.mapView.removeAnnotation(pin)
            
            }
        }
    }

    @IBAction func deletePins(sender: AnyObject) {
        
        self.deleteMode = !self.deleteMode
        
        if(self.deleteMode){
            
            self.editButton.title = "Done"
            self.deleteStatusLabel.hidden = false
            
        }
        
        else{
            self.editButton.title = "Edit"            
            self.deleteStatusLabel.hidden = true
        }
        
    }
    
    //MARK:- FlickerClient delegate methods
    
    func errorOccuredWhileFetching(error: NSError) {
        var errorMessage = ErrorHandler(targetVC: self)
        errorMessage.displayErrorMessage(error)
    }
    
    

}
