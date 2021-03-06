//
//  MapScreen.swift
//  testing
//
//  Created by Arti Patankar on 11/14/18.
//  Copyright © 2018 com.example. All rights reserved.
//
import UIKit
import MapKit
import CoreLocation
import GoogleSignIn

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shareLocationButton: UIButton!
    
    @IBOutlet weak var stopSharingLocationButton: UIButton!
    let locationManager = CLLocationManager()
    let newPin = MKMarkerAnnotationView()
    
    var indoor_floorplan = UIImage()
    var building : String?
    var floor : String?
    
    let range : Double = 1000
    let qs = QueryService()
    // List of user's friends emails
    var friends : [String] = []
    var selected_friend_email : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "customcell")
        checkLocationServices()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSNotification.Name(rawValue: "load"), object: nil)
        
        // Register location upon loading
        qs.registerLocation(location: locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 34.0730698442746, longitude: -118.452035458737))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        qs.getFriends() { response in
            guard let friendList = response else {
                print("No friends! :(")
                return
            }
            self.friends = friendList
            DispatchQueue.main.async(execute: {self.do_table_refresh()})
        }
    }
    
    func do_table_refresh() {
        self.tableView.reloadData()
    }
    
    @objc func refresh(notification: NSNotification) {
        qs.getFriends() { response in
            guard let friendList = response else {
                print("No friends! :(")
                return
            }
            self.friends = friendList
            DispatchQueue.main.async(execute: {self.do_table_refresh()})
        }
        self.tableView.reloadData()
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customcell", for: indexPath)
        qs.getName(email: friends[indexPath.row]) { response in
            cell.textLabel?.text = response!
        }
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        //let selected_friend = cell.textLabel?.text! // friends name
        selected_friend_email = friends[indexPath.row]
        
//        qs.lookup(friend_email: selected_friend_email) // add check to see if selected_friend is nill
//        {
//            response in
//            guard let location = response else {
//                print("No loction received.")
//                return
//            }
//            // Set friend_location in NavigationViewController to location returned by the server
//            vc.friend_location = location
//        }
        self.performSegue(withIdentifier: "showNavigation", sender: self)
    }
    
    
    // Called before segue is performed to set parameters in Target View Controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier ==  "showNavigation"
        {
            let vc = segue.destination as! NavigationViewController
            vc.friend_email = selected_friend_email
        }

        if segue.identifier == "setIndoor"
        {
            let vc = segue.destination as? SetIndoorLocationController
            vc?.image = self.indoor_floorplan
            vc?.building = self.building!
            vc?.floor = self.floor!
        }
    }
    
    func setUpLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerView() {
        if let location = locationManager.location?.coordinate {
            // center is user's location, set bounds
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: range, longitudinalMeters: range)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setUpLocationManager()
            checkLocationAuthorization()
        }
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            centerView()
            locationManager.startUpdatingLocation()
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    
    // Update your location and start sharing your location with all your friends
    @IBAction func shareLocationButtonTapped(_ sender: Any) {
        let mylocation = locationManager.location?.coordinate
        qs.registerLocation(location: mylocation!)
        
//        // IF NO BUILDING AT THAT LOCATION
//        let alert = UIAlertController(title: "Success", message: "You updated your location", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
//         self.present(alert, animated: true, completion: nil)
        
        // IF BUILDING AT THAT LOCATION
        let indoorAlert = UIAlertController(title: "Enter Building and Floor Number", message: nil, preferredStyle: .alert)
        indoorAlert.addTextField{
            textField in textField.text = "Building"
        }
        indoorAlert.addTextField{
            textField in textField.text = "1"
        }
        indoorAlert.addAction(UIAlertAction(title: "OK", style: .default)
        {
            action in
            
            // Check if it exists
            self.building =  indoorAlert.textFields![0].text!
            self.floor = indoorAlert.textFields![1].text!
            self.qs.getBuildingMetadata(building_name: self.building!) { response in
                guard response != nil else {
                    // FLOOR DOESN'T EXIST
                    let floorAlert = UIAlertController(title: "Error", message: "Floor does not exist", preferredStyle: .alert)
                    floorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                    self.present(floorAlert, animated: true, completion: nil)
                    return
                }
                self.qs.getFloorImage(building_name: self.building!, floor: self.floor!) { response in
                    guard let image = response else {
                        print("No file in database")
                        return
                    }
                    self.indoor_floorplan = image 
                    self.performSegue(withIdentifier: "setIndoor", sender: self)
                }
            }
        })
        indoorAlert.addAction(UIAlertAction(title: "Cancel", style:  UIAlertAction.Style.cancel))

        self.present(indoorAlert, animated: true, completion: nil)
    }
    
    // TO DO: Stop sharing location button that calls toggle()
    // User's are automatically not sharing location when they first log in
    // Function is_sharing to check if a user is currently sharing their location
    
    
}

extension HomeViewController: CLLocationManagerDelegate {
    // called whenever user's location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //mapView.removeAnnotation(newPin)
        guard let location = locations.last else {
            return
        }
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: range, longitudinalMeters: range)
        mapView.setRegion(region, animated: true)
        //newPin.coordinate = location.coordinate
        //mapView.addAnnotation(newPin)
    }
    
    // called whenever permission changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    @IBAction func unwindToHome(segue:UIStoryboardSegue) { }
}






