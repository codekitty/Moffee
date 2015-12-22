//
//  DriverViewController.swift
//  Moffee
//

import UIKit
import Parse
import MapKit

class DriverViewController: UITableViewController, CLLocationManagerDelegate {

    var usernames = [String]()
    var locations = [CLLocationCoordinate2D]()
    var cslocations = [CLLocationCoordinate2D]() // coffee shops location
    var csnames = [String]() // coffee shops names
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
                            if let location = location {
                                object["driverLocation"] = PFGeoPoint(latitude: location.latitude, longitude: location.longitude)
                                object.saveInBackground()
                            }
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
        query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: self.latitude, longitude: self.longitude),withinKilometers: 20)
        query.limit = 10
//        query.orderByDescending("createdAt")
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in

            if error == nil && objects != nil {
                
                self.usernames.removeAll()
                self.locations.removeAll()
                self.cslocations.removeAll()
                print("returned request count: \(objects!.count)")
                
                for object in objects! {
                    
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
                        
                        if let returnedcsID = object["coffeeshopid"] as? String {
                            let csquery = PFQuery(className: "CoffeeShop")
                            csquery.whereKey("id", equalTo: returnedcsID)
                            csquery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
                                
                                if error == nil && objects != nil {
                                    for object in objects! {
                                        let returnedcsLocation = object["location"]
                                        let csLocation = CLLocationCoordinate2DMake(returnedcsLocation.latitude, returnedcsLocation.longitude)
                                        self.cslocations.append(csLocation)
                                        self.csnames.append(object["name"] as! (String))
                                    }
                                }
                            }
                        }
                    }
                    
                }
                self.tableView.reloadData()
                //print(self.locations)
                //print(self.usernames)
                
                
            } else {
                print(error);
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
            
//            locationManager.stopUpdatingLocation()
            navigationController?.setNavigationBarHidden(true, animated: false)
            
            PFUser.logOut()
        } else if segue.identifier == "showViewRequests" {
            
            if let destination = segue.destinationViewController as? RequestViewController {
                destination.requestCSName = csnames[tableView.indexPathForSelectedRow!.row]
                destination.requestCSLocation = cslocations[tableView.indexPathForSelectedRow!.row]
                destination.requestLocation = locations[tableView.indexPathForSelectedRow!.row]
                destination.requestUsername = usernames[tableView.indexPathForSelectedRow!.row]
                
//                locationManager.stopUpdatingLocation()
            }
            
            
        }
    }
    

}
