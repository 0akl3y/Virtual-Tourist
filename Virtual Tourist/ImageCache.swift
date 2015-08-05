//
//  ImageCache.swift
//  Virtual Tourist
//
//  Created by Johannes Eichler on 25.07.15.
//  Copyright (c) 2015 Eichler. All rights reserved.
//




import UIKit

class ImageCache: NSObject {
    
    var documentsDirectory: NSURL {
        
        return CoreDataStack.sharedObject().applicationDocumentsDirectory}
    
    let cache = NSCache()
    
    
    func pathForFile(fileName:String) -> String{
        
        let saveLocation:NSURL = self.documentsDirectory.URLByAppendingPathComponent(fileName)
        return saveLocation.path!
    
    }
    
    
    func loadImage(imageName:String?) -> UIImage? {
        
        //Create the file path
        
        let path = self.pathForFile(imageName!)
        
        
        //Check if image is in cache
        
    
        if let image:UIImage = self.cache.objectForKey(path) as? UIImage{
            
            return image
        
        }
        
        //If image is not in cache, load from Documenst Directory
        
        if let data = NSData(contentsOfFile: path){
            
            return UIImage(data: data)!
        
        }
        
        return nil
    
    }
    
    func storeImage(fileName:String, image:UIImage?, completion:((result:String?) -> Void)?){
        
        // Store the image in the documents directory and return path to save location. If no image exists (image == nil) remove any existing image from cache and documents directory.
    
        
        let saveLocation:NSURL = self.documentsDirectory.URLByAppendingPathComponent(fileName)
        
        if (image == nil){
            
            var error:NSError? = nil
            
            cache.removeObjectForKey(fileName)
            NSFileManager.defaultManager().removeItemAtPath(saveLocation.path!, error: &error)
        
        
            if(error != nil){
                
                println("the image \(fileName) is nil and could not be removed: \(error)")
            }
            
            return
        
        }

        //Cache the image
        self.cache.setObject(image!, forKey: saveLocation.path!)

        //Write the image data to the documents directory
        let data = UIImagePNGRepresentation(image)
        data.writeToFile(saveLocation.path!, atomically: true)
        
        //Call the completion handler
        
        if (completion != nil){
            completion!(result: saveLocation.path!)
        }
    }
   
}
