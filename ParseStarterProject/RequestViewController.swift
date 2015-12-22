//
//  RequestViewController.swift
//  Moffee
//

import UIKit
import Parse
import MapKit

class RequestViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var requestLocation: CLLocationCoordinate2D!
    var requestCSLocation: CLLocationCoordinate2D!
    var requestCSName: String!
    var requestUsername: String!
    
    @IBAction func pickUpRider(sender: AnyObject) {
        
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: requestUsername)
        
        query.findObjectsInBackgroundWithBlock { (user_requests, error) -> Void in
            
            if error == nil {
                if let user_requests = user_requests {
                    
                    
                    for user_request in user_requests {
                        
                        let query = PFQuery(className: "RiderRequest")
                        query.getObjectInBackgroundWithId(user_request.objectId!, block: { (objectReturned, error) -> Void in
                            if error == nil {
                                
                                if (objectReturned != nil) {
                                    print("updating driver: \(PFUser.currentUser()?.username)");
                                    print("to object: \(objectReturned)");
 
                                    objectReturned!["driverResponded"] = PFUser.currentUser()?.username
                                    objectReturned!.saveInBackgroundWithBlock {
                                        (success: Bool, error: NSError?) -> Void in
                                        if (success) {
                                            print("driver has been updated \(PFUser.currentUser()?.username)");
                                        } else {
                                            print(error);
                                        }
                                    }
                                    
                                    let requestCLLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
                                    CLGeocoder().reverseGeocodeLocation(requestCLLocation, completionHandler: { (placemarks, error) -> Void in
                                        
                                        if error != nil {
                                            print("Reverse geocoder failed with " + error!.localizedDescription)
                                        } else {
                                            if placemarks!.count > 0 {
                                                let pm = placemarks![0];
                                                let mkPm = MKPlacemark(placemark: pm)
                                                let mapItem = MKMapItem(placemark: mkPm)
                                                
                                                mapItem.name = self.requestUsername
                                                
                                                let launchOption = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                                mapItem.openInMapsWithLaunchOptions(launchOption)
                                            }
                                        }
                                        
                                    })
                                }
                            }
                        })
                        
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //print(requestLocation)
        //print(requestUsername)
        
        let center = CLLocationCoordinate2D(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)
        
        var pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(requestLocation.latitude, requestLocation.longitude)
        var objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = pinLocation
        objectAnnotation.title = requestUsername
        self.mapView.addAnnotation(objectAnnotation)
        
        pinLocation = CLLocationCoordinate2DMake(requestCSLocation.latitude, requestCSLocation.longitude)
        objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = pinLocation
        objectAnnotation.title = requestCSName
        self.mapView.addAnnotation(objectAnnotation)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
