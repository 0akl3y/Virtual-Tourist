//
//  ImageCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Johannes Eichler on 31.07.15.
//  Copyright (c) 2015 Eichler. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    func setImage(image:UIImage){
        
        self.activityIndicator.stopAnimating()
        self.imageView.image = image
    
    }
    
    func removeImage(){
        
        self.imageView.image = nil
        self.activityIndicator.startAnimating()    
    
    }
}