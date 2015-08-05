//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Johannes Eichler on 21.07.15.
//  Copyright (c) 2015 Eichler. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate, FlickerClientDelegate {
    
    var flickerClient: FlickerClient?
    
    var fetchedImagesController:NSFetchedResultsController!
    var selectedPin: Pin!
    var imageCache = ImageCache()
    
    var indicesToInsert: [NSIndexPath]?
    
    var shouldReloadAll = false
    var itemsToDelete: [NSIndexPath]?

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet var newCollectionButton: UIBarButtonItem!
    @IBOutlet var noImagesLabel: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        var error:NSError? = nil
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.mapView.delegate = self
        
        self.flickerClient?.delegate = self
        
        self.mapView.addAnnotation(self.selectedPin)
        mapView.setCenterCoordinate(self.selectedPin.coordinate, animated: true)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        self.fetchImagesFor(self.selectedPin)
        self.collectionView.reloadData()
        self.collectionView.setNeedsDisplay()
        self.newCollectionButton.enabled = false
        
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.noImagesLabel.hidden = true
        
    }
    
    func fetchImagesFor(pin:Pin){
        
        var error:NSError? = nil
        
        var imageFetchRequest = NSFetchRequest(entityName: "Image")
        
        imageFetchRequest.predicate = NSPredicate(format: "pin = %@", pin)
        let sortDescriptor = NSSortDescriptor(key: "dateAdded", ascending: true)
        
        imageFetchRequest.sortDescriptors = [sortDescriptor]
        
        self.fetchedImagesController = NSFetchedResultsController(fetchRequest: imageFetchRequest, managedObjectContext: CoreDataStack.sharedObject().managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        
        self.fetchedImagesController.delegate = self
        self.fetchedImagesController?.performFetch(&error)
        
        println("Number of fetched objects \(self.fetchedImagesController?.fetchedObjects?.count)")
        
        if(error != nil){
            
            println("There was an error fetching the images: \(error)")
            
        }
        
        //update button status after fetch
        
        if(self.selectedPin.expectedImages == nil){
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.newCollectionButton.enabled = self.fetchedImagesController.fetchedObjects!.count == self.selectedPin.images.count
                self.noImagesLabel.hidden = self.selectedPin.images.count > 0
                println(self.noImagesLabel.hidden)
              
            })

        }
        
    }

    // MARK: - FlickerClient delegate methods
    
    func willDownloadImages() {
        
        // if the number of images had not been available before
        
        self.collectionView.reloadData()

    }
    
    func didDownloadAllImages() {
        
        // download completed no more images expected
        
        println("download completed no more images")
        self.noImagesLabel.hidden = true
        self.newCollectionButton.enabled = true
        
        self.noImagesLabel.hidden = self.flickerClient!.totalEntries > 0
    }
    
    func foundNoImagesForPin() {
        
        //the number of total entries has just been fetched
        
        self.noImagesLabel.hidden = false
        self.newCollectionButton.enabled = true

    }
    
    // MARK: - NSFetchedResultsController delegate methods
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        
        self.noImagesLabel.hidden = true
        
        self.indicesToInsert = [NSIndexPath]()
        self.itemsToDelete = [NSIndexPath]()
    }
    

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        //this is necessary because cellForItemAtIndexPath returns nil for invisible cells (this includes - not in scroll area)
        
        switch type {
        
        case NSFetchedResultsChangeType.Insert:
            
            self.indicesToInsert!.append(newIndexPath!)
            
        case NSFetchedResultsChangeType.Delete:
            
            if(shouldReloadAll == false){
                
                let itemsToDelete = [indexPath!]                
                self.collectionView.deleteItemsAtIndexPaths(itemsToDelete)
            
            }
            

        default:
            return
        
        }
        
    }
    

    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        CoreDataStack.sharedObject().saveContext()
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.collectionView.reloadItemsAtIndexPaths(self.indicesToInsert!)
            
        })
        
        if(self.shouldReloadAll == true){
        
            self.collectionView.reloadData()
            self.shouldReloadAll = false
        
        }

    }
    
    // MARK:- CollectionView Delegate & Data Source
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        var sectionInfo =  self.fetchedImagesController.sections![section] as! NSFetchedResultsSectionInfo
        
        println("the number of expected images is currently: \(self.selectedPin?.expectedImages)")
        
        if let expectedDownloads = self.selectedPin.expectedImages{
            // This means images are expected and eventually not yet in the managedObjectContext
            
            if(expectedDownloads > sectionInfo.numberOfObjects){
            // This means the number of expected object is larger than the number of objects already fetched
                
                println("expectedDownloads is: \(expectedDownloads)")
                return expectedDownloads
            
            }
        
        }
        
        println("The number of objects in section is: \(self.selectedPin.images.count )")
        return self.selectedPin.images.count // sectionInfo.numberOfObjects turned out to be unreliable
    }

    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ImageCollectionViewCell
        cell.removeImage()
        
        let fetchedImagesNumber = self.fetchedImagesController.fetchedObjects!.count
        
        //Is the image already fetched
        
        if (fetchedImagesNumber >= indexPath.row + 1){
            
            let imageForPin = fetchedImagesController.objectAtIndexPath(indexPath) as! Image
            let imageID = imageForPin.id as String

            if let image = self.imageCache.loadImage(imageID){
                
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    cell.setImage(image)
                    cell.setNeedsDisplay()
                })
            }            
        }
        
        cell.contentView.backgroundColor = UIColor.redColor()
        
        return cell
                
    }
    
    @IBAction func fetchNewCollection(sender: UIBarButtonItem) {
        
        self.newCollectionButton.enabled = false
        
        //remove previous fetches from persistent store
        
        var objectsToDelete = self.fetchedImagesController.fetchedObjects
        
        for object in objectsToDelete as! [Image] {
            
            self.imageCache.storeImage(object.id, image: nil, completion: nil)
            self.shouldReloadAll = true
            CoreDataStack.sharedObject().managedObjectContext?.deleteObject(object)
            
        }
        
        //fetch new page
        
        let totalPageNumber = self.selectedPin.totalPages > 0 ? self.selectedPin.totalPages : 1
        
        let nextPageIdx = Int((self.selectedPin.lastPage + 1)) % totalPageNumber!
        let pageToFetch = nextPageIdx > 0 ? nextPageIdx : 1
        
        self.flickerClient?.fetchPinFromFlickr(self.selectedPin, entriesPerPage: 20, page: pageToFetch)
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if(self.newCollectionButton.enabled){
        
            let allImages = self.fetchedImagesController.fetchedObjects as! [Image]
            let imageToDelete = allImages[indexPath.row]
            
            self.selectedPin.expectedImages = nil
            self.imageCache.storeImage(imageToDelete.id, image: nil, completion: nil)
                CoreDataStack.sharedObject().managedObjectContext?.deleteObject(imageToDelete)}
    
        }

}

