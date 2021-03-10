//
//  DriverTableTableViewController.swift
//  
//
//  Created by Andranik Karapetyan on 12/7/20.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import MapKit

class DriverTableTableViewController: UITableViewController, CLLocationManagerDelegate {

    var rideRequests : [DataSnapshot] = []
    var locationManager = CLLocationManager()
    var driverLocation = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Database.database().reference().child("RideRequests").observe(.childAdded) {(snapshot) in
            
            if let rideRequestDict = snapshot.value as? [String:AnyObject]
            {
                if let driverLat = rideRequestDict["driverLat"] as? Double
                {

                }
                else
                {
                    self.rideRequests.append(snapshot)
                    self.tableView.reloadData()
                }
            }
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            self.tableView.reloadData()
        }
    }

    @IBAction func LougoutTapped(_ sender: Any)
    {
        try? Auth.auth().signOut()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let coord = manager.location?.coordinate
        {
            driverLocation = coord
        }
    }
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return rideRequests.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rideRequestCell", for: indexPath)

        let snapshot = rideRequests[indexPath.row]
        
        if let rideRequestDict = snapshot.value as? [String:AnyObject]
        {
            if let email = rideRequestDict["email"] as? String
            {
                if let lat = rideRequestDict["lat"] as? Double
                {
                    if let lon = rideRequestDict["lon"] as? Double
                    {
                        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                        let riderCLLocation = CLLocation(latitude: lat, longitude: lon)
                        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
                        let roundedDistance = round(distance * 100) / 100
                        
                        cell.textLabel?.text = "\(email) - \(roundedDistance)km away"
                    }
                }
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let snapshot = rideRequests[indexPath.row]
        performSegue(withIdentifier: "AcceptSegue", sender: snapshot)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let acceptVC = segue.destination as? AcceptRequestViewController
        {
            if let snapshot = sender as? DataSnapshot
            {
                if let rideRequestDict = snapshot.value as? [String:AnyObject]
                {
                    if let email = rideRequestDict["email"] as? String
                    {
                        if let lat = rideRequestDict["lat"] as? Double
                        {
                            if let lon = rideRequestDict["lon"] as? Double
                            {
                                let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                acceptVC.requestLoction = location
                                acceptVC.requestEmail = email
                                acceptVC.driverLocation = driverLocation
                            }
                        }
                    }
                }
            }
        }
    }
}
