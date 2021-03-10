//
//  RiderViewController.swift
//  Uber Clone
//
//  Created by Andranik Karapetyan on 12/6/20.
//  Copyright © 2020 Andranik Karapetyan. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth
import GoogleMobileAds

class RiderViewController: UIViewController, CLLocationManagerDelegate
{
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var uberButton: UIButton!
    @IBOutlet weak var bannerView: GADBannerView!
    
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var uberHasBeenCalled = false
    var driverLocation = CLLocationCoordinate2D()
    var driverOnTheWay = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let email = Auth.auth().currentUser?.email
        {
            Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded)
            { (snapshot) in
                
                self.uberHasBeenCalled = true
                self.uberButton.setTitle("Cancel Uber", for: .normal)
                Database.database().reference().child("RideRequests").removeAllObservers()
                
                if let rideRequestDict = snapshot.value as? [String:AnyObject]
                {
                    if let driverLat = rideRequestDict["driverLat"] as? Double
                    {
                        if let driverLon = rideRequestDict["driverLon"] as? Double
                        {
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                            self.driverOnTheWay = true
                            self.displayDriverAndRider()
                            
                            if let email = Auth.auth().currentUser?.email
                            {
                            Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged) { (snapshot) in
                                    
                                    if let rideRequestDict = snapshot.value as? [String:AnyObject]
                                    {
                                        if let driverLat = rideRequestDict["driverLat"] as? Double
                                        {
                                            if let driverLon = rideRequestDict["driverLon"] as? Double
                                            {
                                                self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                                                self.driverOnTheWay = true
                                                self.displayDriverAndRider()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func displayDriverAndRider()
    {
        let driverCLLocation  = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        let roundedDistance = round(distance * 100) / 100
        
        uberButton.setTitle("Your driver is \(roundedDistance)km away", for: .normal)
        map.removeAnnotations(map.annotations)
        
        let latDelta = abs(driverLocation.latitude - userLocation.latitude) * 2 + 0.005
        let lonDelta = abs(driverLocation.longitude - userLocation.longitude) * 2 + 0.005
        
        let region = MKCoordinateRegion(center: userLocation, latitudinalMeters: latDelta, longitudinalMeters: lonDelta)
        map.setRegion(region, animated: true)
        
        let riderAnno = MKPointAnnotation()
        riderAnno.coordinate = userLocation
        riderAnno.title = "Your Location"
        map.addAnnotation(riderAnno)

        let driverAnno = MKPointAnnotation()
        driverAnno.coordinate = driverLocation
        driverAnno.title = "Your Driver"
        map.addAnnotation(driverAnno)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let coordinates = manager.location?.coordinate
        {
            let center = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
            self.userLocation = center

            
            if uberHasBeenCalled
            {
                displayDriverAndRider()
            }
            else
            {
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                map.setRegion(region, animated: true)
                //-/ Remove previous Annotations from map
                    // - prevents multiple annotations for moving objects
                self.map.removeAnnotations(self.map.annotations)
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                annotation.title = "Your Location"
                map.addAnnotation(annotation)
            }
        }
    }
    
    @IBAction func LogoutTapped(_ sender: Any)
    {
        try? Auth.auth().signOut()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func UberTapped(_ sender: Any)
    {
        if !driverOnTheWay
        {
            //-/ Find value belonging to user in Firebase
            if let email = Auth.auth().currentUser?.email
            {
                if uberHasBeenCalled
                {
                    uberHasBeenCalled = false
                    uberButton.setTitle("Call an Uber", for: .normal)
                    
                    //-/ FIREBASE: QUERY DATABSE FOR VALUE BY VALUE
                    //-/ Retrieve database reference
                    //-/ Retrieve child of database reference
                    //-/ Query for child by it's value type with "queryOrdered(byChild:)"
                    //-/ Give this query a value to look for with "queryEqual(toValue:)"
                    //-/ Look for a change in the retrieved value with "observe(.childAdded)"
                    //-/ Implement observe methos block
                    Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded)
                    { (snapshot) in
                        //-/ remove value returned by the observed query with "removeValue()"
                        snapshot.ref.removeValue()
                        //-/ Remove observers from a database child with "removeAllObservers()"
                        Database.database().reference().child("RideRequests").removeAllObservers()
                    }
                }
                else
                {
                    //-/ Firebase: Example dictionary structure matching database structure on Firebase
                    let rideRequestDictionary : [String:Any] = ["email":email, "lat":userLocation.latitude ,"lon":userLocation.longitude]
                    //-/ Firebase: set value of a database structure with matching dictionary structure
                    //-/ Retrieve database reference
                    //-/ Retrieve child of database reference
                    //-/ Set the value by dictionary of the child by getting its "auto ID"
                    Database.database().reference().child("RideRequests").childByAutoId().setValue(rideRequestDictionary)
                    
                    uberHasBeenCalled = true
                    uberButton.setTitle("Cancel Uber", for: .normal)
                }
            }
        }
    }
}
