//
//  DriverViewController.swift
//  Moffee
//
//  Created by Guilherme Souza on 10/26/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class DriverViewController: UITableViewController, CLLocationManagerDelegate {

    var usernames = [String]()
    var locations = [CLLocationCoordinate2D]()
    var distances = [CLLocationDistance]()
    
    var locationManager: CLLocationManager!
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup location
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = manager.location?.coordinate
        self.latitude = location!.latitude
        self.longitude = location!.longitude
        print("Latitude \(self.latitude) and Longitude \(self.longitude)")

        var query = PFQuery(className: "DriverLocation")
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            
            if error == nil {
                
                if let objects = objects {
                    
                    if objects.count > 0 {
                    
                        for object in objects {
                            
                            object["driverLocation"] = PFGeoPoint(latitude: (location?.latitude)!, longitude: (location?.longitude)!)
                            object.saveInBackground()
                            
                        }
                    } else {
                    
                        let driverLocation = PFObject(className: "DriverLocation")
                        driverLocation["username"] = PFUser.currentUser()?.username
                        driverLocation["driverLocation"] = PFGeoPoint(latitude: (location?.latitude)!, longitude: (location?.longitude)!)
                        
                        driverLocation.saveInBackground()
                    }
                }
                
            }
            
        }
        
        
        
        
        
        
        
        
        
        // Query the requests for displaying on the table
        query = PFQuery(className: "RiderRequest")
        query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: self.latitude, longitude: self.longitude))
        query.limit = 10
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            
            if error == nil {
                
                if let objects = objects {
                    
                    self.usernames.removeAll()
                    self.locations.removeAll()
                    
                    for object in objects {
                        
                        if object["driverResponded"] == nil {
                        
                            if let username = object["username"] as? String {
                                self.usernames.append(username)
                            }
                            if let returnedLocation = object["location"] as? PFGeoPoint {
                                let requestLocation = CLLocationCoordinate2DMake(returnedLocation.latitude, returnedLocation.longitude)
                                self.locations.append(requestLocation)
                                
                                let requestCLLocation = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
                                
                                let driverCLLocation = CLLocation(latitude: location!.latitude, longitude: location!.longitude)
                                
                                let distance = driverCLLocation.distanceFromLocation(requestCLLocation)
                                
                                self.distances.append(distance/1000)
                            }
                        }
                        
                    }
                    self.tableView.reloadData()
//                    print(self.locations)
//                    print(self.usernames)
                }
                
            } else {
                // treat error
            }
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return usernames.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

        let distanceDouble = Double(distances[indexPath.row])
        let distanceRouded = round(distanceDouble * 10)/10
        
        
        cell.textLabel?.text = usernames[indexPath.row] + " - \(distanceRouded) km away"
        return cell
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "logOutDriver" {
            
            locationManager.stopUpdatingLocation()
            navigationController?.setNavigationBarHidden(true, animated: false)
            
            PFUser.logOut()
        } else if segue.identifier == "showViewRequests" {
            
            if let destination = segue.destinationViewController as? RequestViewController {
                destination.requestLocation = locations[tableView.indexPathForSelectedRow!.row]
                destination.requestUsername = usernames[tableView.indexPathForSelectedRow!.row]
                
                locationManager.stopUpdatingLocation()
            }
            
            
        }
    }
    

}
