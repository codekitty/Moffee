//
//  RiderViewController.swift
//  Moffee


import UIKit
import MapKit
import CoreLocation
import Parse

class RiderViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var callUberButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager: CLLocationManager!
    
    var latitude: CLLocationDegrees! = 0 , longitude: CLLocationDegrees! = 0
    
    var uberRequested = false
    
    var driverOnTheWay = false
    
    var lastLocation: CLLocation!;
    
    var userLocation: CLLocation?;
    
    let userAnnotationTitle = "You are here";
    let driverAnnotationTitle = "Your Coffee is Here"
    
    @IBAction func callUber(sender: AnyObject) {
        if uberRequested == false {

            if self.mapView.selectedAnnotations.count == 0 {
                print("Please select a coffee shop")
                Helpers.displayAlert("Operation cannot be performed", message: "Please select a coffee shop", viewController: self)
                return
            }
            
            let ann = self.mapView.selectedAnnotations[0]
            print ("\(ann.title!)")
            
            
            let riderRequest = PFObject(className: "RiderRequest")
            riderRequest["username"] = PFUser.currentUser()!.username
            riderRequest["location"] = PFGeoPoint(latitude: latitude, longitude: longitude)
            riderRequest["coffeeshopname"] = ann.title!
            riderRequest["coffeeshopid"] = ann.subtitle!
            
            // make sure it's public so that drivers can accept request
            let acl = PFACL()
            acl.setPublicReadAccess(true)
            acl.setPublicWriteAccess(true)
            riderRequest.ACL = acl
            
            // save
            riderRequest.saveInBackgroundWithBlock { (success, error) -> Void in
                if success {
                    self.callUberButton.setTitle("Cancel Moffee", forState: UIControlState.Normal)
                    self.uberRequested = true
                } else {
                    Helpers.displayAlert("There was an error while saving request.", message: "There was an error on requesting coffee, please try again.", viewController: self)
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
        
        mapView.delegate = self
        mapView.showsUserLocation = true;
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if manager.location?.coordinate != nil {
            
            let location: CLLocationCoordinate2D = (manager.location?.coordinate)!
            
//            if (userLocation != nil) {
//                let distanceUserMoved = userLocation?.distanceFromLocation(CLLocation(latitude: location.latitude, longitude: location.longitude));
//                print("distance user \(distanceUserMoved)");
//                userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude);
//            }
            
            
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
                                                        objectAnnotation.title = self.userAnnotationTitle
                                                        self.mapView.addAnnotation(objectAnnotation)
                                                        
                                                        pinLocation = CLLocationCoordinate2DMake(driverLocation.latitude, driverLocation.longitude)
                                                        objectAnnotation = MKPointAnnotation()
                                                        objectAnnotation.coordinate = pinLocation
                                                        objectAnnotation.title = self.driverAnnotationTitle
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
            
            if driverOnTheWay == false && userLocation == nil {
                
                let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                self.userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude);

                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                
                self.mapView.setRegion(region, animated: true)
                print("region set");
                
                self.mapView.removeAnnotations(mapView.annotations)
            }
        }
    }
    
    func fetchCafesAroundLocation(center:CLLocation){
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations( annotationsToRemove );
        
        // add nearby coffee places
        print("fetching nearby coffee places...")
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = "Coffee"
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.startWithCompletionHandler ({(response, error) -> Void in
            
            if error != nil {
                print("Error occured in search: \(error!.localizedDescription)")
            } else if response!.mapItems.count == 0 {
//                print("No matches found")
            } else {
//                print("Matches found")
                
                for item in response!.mapItems {
                    if item.phoneNumber != nil {
//                        print("Name = \(item.name)")
//                        print("Phone = \(item.phoneNumber)")
                        
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = item.placemark.coordinate
                        annotation.title = item.name
                        annotation.subtitle = item.phoneNumber
                        self.mapView.addAnnotation(annotation)
                    }
                }
            }
        })

        
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool){
//        print("region did change");
        
        let centre = mapView.centerCoordinate as CLLocationCoordinate2D
        
        let getLat: CLLocationDegrees = centre.latitude
        let getLon: CLLocationDegrees = centre.longitude
        
        
        let getMovedMapCenter: CLLocation =  CLLocation(latitude: getLat, longitude: getLon)
        if self.lastLocation != nil {
            let distanceMapMoved = self.lastLocation.distanceFromLocation(getMovedMapCenter)
            print("moved this much: \(distanceMapMoved)")
            if distanceMapMoved < 80 {
                return
            }
        }
        self.lastLocation = getMovedMapCenter
        
        let deltaLatitude = self.mapView.region.span.latitudeDelta;
        let deltaLongitude = self.mapView.region.span.longitudeDelta;
        let regionSize = deltaLatitude * deltaLongitude;
        
        if (regionSize < 0.0003) {
            self.fetchCafesAroundLocation(getMovedMapCenter)
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//        print("creating annotation views")
        if annotation.isEqual(mapView.userLocation) {
            return nil;
        }
        
        let pinView:MKPinAnnotationView = MKPinAnnotationView()
        pinView.annotation = annotation
        if (annotation.title! == userAnnotationTitle) {
            pinView.pinTintColor = UIColor.blueColor()
            pinView.animatesDrop = false
        } else if (annotation.title! == driverAnnotationTitle) {
            pinView.pinTintColor = UIColor.greenColor()
            pinView.animatesDrop = false
        } else {
            pinView.pinTintColor = UIColor.redColor()
            pinView.animatesDrop = false
        }
        
        pinView.canShowCallout = true
        
        return pinView

    }
    
    
}
