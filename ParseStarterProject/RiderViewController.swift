//
//  RiderViewController.swift
//  Moffee


import UIKit
import MapKit
import CoreLocation
import Parse

class RiderViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var callUberButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager: CLLocationManager!
    
    var latitude: CLLocationDegrees! = 0 , longitude: CLLocationDegrees! = 0
    
    var uberRequested = false
    
    var driverOnTheWay = false
    
    @IBAction func callUber(sender: AnyObject) {
        if uberRequested == false {
            let riderRequest = PFObject(className: "RiderRequest")
            riderRequest["username"] = PFUser.currentUser()!.username
            riderRequest["location"] = PFGeoPoint(latitude: latitude, longitude: longitude)
            riderRequest.saveInBackgroundWithBlock { (success, error) -> Void in
                if success {
                    self.callUberButton.setTitle("Cancel Moffee", forState: UIControlState.Normal)
                    self.uberRequested = true
                } else {
                    Helpers.displayAlert("There was an error.", message: "There was an error on requesting coffee, please try again.", viewController: self)
                }
            }
        } else {
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
            
            query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                
                if error == nil {
                    print("Succesfully retrieved \(objects?.count) objects.")
                    
                    if let objects = objects {
                        for object in objects {
                            object.deleteInBackground()
                        }
                        self.callUberButton.setTitle("Request Moffee", forState: UIControlState.Normal)
                        self.uberRequested = false
                    }
                }
                
            })
        }
        
        
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // Starts getting the location
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if manager.location?.coordinate != nil {
            
            let location: CLLocationCoordinate2D = (manager.location?.coordinate)!
            
            latitude = location.latitude
            longitude = location.longitude
            //            print("Latitude \(latitude) and Longitude \(longitude)")
            
            if let currentUserUsername = PFUser.currentUser()?.username {
                let query = PFQuery(className: "RiderRequest")
                query.whereKey("username", equalTo: currentUserUsername)
                query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                    
                    if error == nil {
                        
                        if let objects = objects {
                            
                            for object in objects {
                                if let driverUsername = object["driverResponded"] {
                                    
                                    let query = PFQuery(className: "DriverLocation")
                                    query.whereKey("username", equalTo: driverUsername)
                                    query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                                        
                                        if error == nil {
                                            if let objects = objects {
                                                for object in objects {
                                                    if let driverLocation = object["driverLocation"] as? PFGeoPoint {
                                                        
                                                        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                                        
                                                        let userCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                                                        
                                                        let distanceMeters = userCLLocation.distanceFromLocation(driverCLLocation)
                                                        let distanceKM = distanceMeters / 1000
                                                        let roudedTwoDigitsDistance = Double(round(distanceKM * 100) / 100)
                                                        
                                                        
                                                        self.callUberButton.setTitle("Driver is \(roudedTwoDigitsDistance) km away.", forState: UIControlState.Normal)
                                                        
                                                        self.driverOnTheWay = true
                                                        
                                                        let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                                                        
                                                        let latDelta = abs(driverLocation.latitude - location.latitude) * 2 + 0.005
                                                        let longDelta = abs(driverLocation.longitude - location.longitude) * 2 + 0.005
                                                        
                                                        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta))
                                                        
                                                        self.mapView.setRegion(region, animated: true)
                                                        
                                                        self.mapView.removeAnnotations(self.mapView.annotations)
                                                        
                                                        var pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                                                        var objectAnnotation = MKPointAnnotation()
                                                        objectAnnotation.coordinate = pinLocation
                                                        objectAnnotation.title = "You are here"
                                                        self.mapView.addAnnotation(objectAnnotation)
                                                        
                                                        pinLocation = CLLocationCoordinate2DMake(driverLocation.latitude, driverLocation.longitude)
                                                        objectAnnotation = MKPointAnnotation()
                                                        objectAnnotation.coordinate = pinLocation
                                                        objectAnnotation.title = "Driver is here"
                                                        self.mapView.addAnnotation(objectAnnotation)
                                                        
                                                    }
                                                }
                                            }
                                        }
                                        
                                    })
                                    
                                    
                                }
                            }
                            
                        }
                        
                    }
                    
                })
            }
            
            if driverOnTheWay == false {
                
                let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                
                self.mapView.setRegion(region, animated: true)
                
                self.mapView.removeAnnotations(mapView.annotations)
                
                let pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                let objectAnnotation = MKPointAnnotation()
                objectAnnotation.coordinate = pinLocation
                objectAnnotation.title = "You are here"
                self.mapView.addAnnotation(objectAnnotation)
            }
            
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "logOutRider" {
            
            PFUser.logOut()
        }
        
    }
    
    
}
