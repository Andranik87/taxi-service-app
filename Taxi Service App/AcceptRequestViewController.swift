//
//  AcceptRequestViewController.swift
//  Uber Clone
//
//  Created by Andranik Karapetyan on 12/7/20.
//  Copyright © 2020 Andranik Karapetyan. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class AcceptRequestViewController: UIViewController
{

    @IBOutlet weak var map: MKMapView!
    
    var requestLoction = CLLocationCoordinate2D()
    var requestEmail = ""
    var driverLocation = CLLocationCoordinate2D()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        let region = MKCoordinateRegion(center: requestLoction, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        map.setRegion(region, animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = requestLoction
        annotation.title = requestEmail
        map.addAnnotation(annotation)
    }

    @IBAction func AcceptTapped(_ sender: Any)
    {
        Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: requestEmail).observe(.childAdded) { (snapshot) in
            
            snapshot.ref.updateChildValues(["driverLat":self.driverLocation.latitude, "driverLon":self.driverLocation.longitude])
        }
        
        let requestCLLocation = CLLocation(latitude: requestLoction.latitude, longitude: requestLoction.longitude)
        CLGeocoder().reverseGeocodeLocation(requestCLLocation) { (placemarks, error) in
            
            if let placemarks = placemarks
            {
                if placemarks.count > 0
                {
                    let mkPlacemark = MKPlacemark(placemark: placemarks[0])
                    let mapItem = MKMapItem(placemark: mkPlacemark)
                    mapItem.name = self.requestEmail
                    let options = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                    mapItem.openInMaps(launchOptions: options)
                }
            }
        }
    }
}
