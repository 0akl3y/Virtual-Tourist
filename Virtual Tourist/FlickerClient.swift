//
//  FlickerClient.swift
//  Virtual Tourist
//
//  Created by Johannes Eichler on 25.07.15.
//  Copyright (c) 2015 Eichler. All rights reserved.
//

import UIKit
import CoreData


@objc protocol FlickerClientDelegate{
    
    // If the basic information is fetche the flicker client will start to fetcht the images
    optional func willDownloadImages()
    
    // When the images have been completely fetched to the persistent store
    optional func didDownloadAllImages()
    
    // If there are no images to fetch
    optional func foundNoImagesForPin()
    
    // If a network error occured
    optional func errorOccuredWhileFetching(error:NSError)

}


class FlickerClient: SimpleNetworking {
    
    let fileCache: ImageCache = ImageCache()
    var delegate: FlickerClientDelegate?

    //The number of images that will be fetched
    var totalEntries: Int?
    
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "c4dc51c04f295239e710aa593fd4e641"
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    
    
    func fetchPinFromFlickr(pin:Pin, entriesPerPage:Int, page:Int?){
        
        
        let flickerClient = SimpleNetworking()
        
        let lat = pin.coordinate.latitude
        let lon = pin.coordinate.longitude
        
        var methodArguments: [String: AnyObject] = ["method": METHOD_NAME, "api_key": API_KEY, "lat": lat, "lon": lon, "per_page": entriesPerPage, "format": DATA_FORMAT, "nojsoncallback": NO_JSON_CALLBACK, "extras": EXTRAS ]
        
        if(page != nil){
            
            methodArguments["page"] = page!
        
        }
        
        var requetError:NSError? = nil
        
        self.sendGETRequest(BASE_URL, GETData: methodArguments, headerValues: nil) { (result, error) -> Void in
            
            if(error != nil){
                
                println("There was an error converting the JSON Data: \(error)")
                self.delegate?.errorOccuredWhileFetching?(error!)
                return
            
            }
            
            let parsedResult = NSJSONSerialization.JSONObjectWithData(result!, options: NSJSONReadingOptions.allZeros, error: nil) as! [String:AnyObject]
            
            if let photoList = parsedResult["photos"] as? [String: AnyObject]{
                
                //set number of expected entries for later reference
                
                let totalImages = photoList["total"] as! NSString // Workaroud for a strange error
                self.totalEntries = totalImages.integerValue
                
                let photosPerPage = photoList["perpage"] as! Int
                
                pin.expectedImages =  photosPerPage > self.totalEntries ? self.totalEntries : photosPerPage
                pin.totalPages = self.totalEntries! / photosPerPage
                
                let lastPageNumber = photoList["page"] as! NSNumber
                pin.lastPage = lastPageNumber.intValue
                
                
                //Keep track of the current indx in a cheap way
                var currentIdx = 0
                let allPhotos = photoList["photo"] as! [[String: AnyObject]]
                
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if(self.totalEntries == 0){
                        
                        pin.expectedImages = nil //Download completed no more images expectedd
                        self.delegate?.foundNoImagesForPin?()
                        CoreDataStack.sharedObject().saveContext()
                        return
                    }

                    self.delegate?.willDownloadImages?()

                })
                
                var existingKeys = [String]()
                
                for photoDict in allPhotos  {
                    
                    //Store image to disk
                    let imageURL = photoDict["url_m"] as! String
                        
                    self.sendGETRequest(imageURL, GETData: nil, headerValues: nil, completion: { (result, error) -> Void in
                        
                            if(error != nil){
                                println("Imaged data error: \(error!)")
                                self.delegate?.errorOccuredWhileFetching?(error!)
                                return
                            }
                        
                            if let currentImage = UIImage(data: result!){

                                //let path = self.fileCache.storeImage(photoDict["title"] as! String, image: currentImage)
                                
                                self.fileCache.storeImage(photoDict["id"] as! String, image: currentImage, completion: { (result) -> Void in
                                    
                                    //start adding the image entities when the actual image has been stored completely to keep everyting
                                    //in sync.
                                    
                                    
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        
                                        var argumentsDict = [ImagePropertyKey.Title: photoDict["title"]!, ImagePropertyKey.FileURL:  result!, ImagePropertyKey.ID: photoDict["id"] as! String]
                                        
                                        var newImage = Image(imageProperties: argumentsDict)
                                        
                                        // Add PIN relation Test
                                        
                                        currentIdx += 1
                                        newImage.pin = pin
                                        
                                        // Save context in the completion handler when all photo are fetched
                                        
                                        if(currentIdx == allPhotos.count){
                                            
                                            pin.expectedImages = nil // download completed no more images expected
                                            CoreDataStack.sharedObject().saveContext()
                                            self.delegate?.didDownloadAllImages?()
                                            
                                        }
                                        
                                        
                                    })
                                    
                                })
                            }
                    })
                }
            }
        }
    }
}
