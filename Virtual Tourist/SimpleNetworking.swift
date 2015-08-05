//
//  SimpleNetworking.swift
//  Virtual Touris
//
//  Created by Johannes Eichler on 19.05.15.
//  Copyright (c) 2015 Eichler. All rights reserved.
//

import UIKit

class SimpleNetworking: NSObject {
   
    var sharedSession: NSURLSession {
        
        get{
            
            return NSURLSession.sharedSession()
        }
    }
    
    func escapeToURL(targetURL: String, methodCall: [String: AnyObject]?) -> String{
        
        //takes the methodCall array containing the method call and all parameters and returns the complete URL for the GET request
        
        var parsedURLString = [String]()
        
        for (key, value) in methodCall! {
            
            let currentValue: String = "\(value)".stringByAddingPercentEncodingWithAllowedCharacters( NSCharacterSet.URLQueryAllowedCharacterSet())!
            let methodElement = "\(key)" + "=" + "\(currentValue)"
            
            parsedURLString.append(methodElement)
            
        }
        
        var getRequestPart = join("&", parsedURLString)
        var completeURL = targetURL + "?" + getRequestPart
        
        return completeURL
    }
    
    func sendJSONRequest(targetURL: String, method: String, additionalHeaderValues:[String:String]?, bodyData: [String:AnyObject]?, completion:(result:NSData?, error:NSError?) -> Void){
        
        let request = NSMutableURLRequest(URL: NSURL(string: targetURL)!)
        
        request.HTTPMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        if var additionalHeaderFields = additionalHeaderValues {
            
            for (key, value) in additionalHeaderFields{
                
                request.addValue(value , forHTTPHeaderField: key)
            
            }        
        }
        
        var JSONError: NSError? = nil
        
        if(bodyData != nil){
            
            request.HTTPBody = NSJSONSerialization.dataWithJSONObject(bodyData!, options: nil, error: &JSONError)
        
        }        
        
        let task = sharedSession.dataTaskWithRequest(request) { data, response, error in
            
            if error != nil { // Handle error…
                completion(result: nil, error: error!)
                return
            }
            
            completion(result: data, error: error)
            
        }
        task.resume()
        
    }
    
    func sendGETRequest(targetURL: String, GETData: [String:AnyObject]?, headerValues:[String: String]?, completion:(result:NSData?, error:NSError?) -> Void) {
            
            var requestURL: NSURL = NSURL(string: targetURL)!
        
            if(GETData != nil){

                let requestURLString: String = self.escapeToURL(targetURL, methodCall: GETData)
                requestURL = NSURL(string: requestURLString)!
            }
        
            var currentRequest = NSMutableURLRequest(URL: requestURL)
        
            if var additionalHeaderFields = headerValues {
                
                for (key, value) in additionalHeaderFields{
                    
                    currentRequest.addValue(value , forHTTPHeaderField: key)
                    
                }
                
            }
        
            let task = sharedSession.dataTaskWithRequest(currentRequest) { data, response, error in
            
            if error != nil {
                completion(result: nil, error: error!)
                return
            }
            
            completion(result: data, error: error)
            
        }
        task.resume()
            
    }
    
}
