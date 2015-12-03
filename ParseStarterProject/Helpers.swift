//
//  Helpers.swift
//  Moffee
//
//  Created by Guilherme Souza on 10/23/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit

class Helpers {
    
    // Function for displaying default alerts
    static func displayAlert(title: String!, message: String!, viewController: UIViewController!) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Try again", style: UIAlertActionStyle.Default, handler: nil))
        viewController.presentViewController(alert, animated: true, completion: nil)
        
    }
    
}