//
//  ViewController.swift
//  Places to eat & Drink on Campus
//
//  Created by James Thirkeld on 01/12/2024.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate {

    // MARK: Map & Location related stuff
    @IBOutlet weak var myMap: MKMapView!
    var locationManager = CLLocationManager()
    var firstRun = true
    var startTrackingTheUser = false

    func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationOfUser = locations[0] //this method returns an array of locations
        //generally we always want the first one (usually there's only 1 anyway)
        let latitude = locationOfUser.coordinate.latitude
        let longitude = locationOfUser.coordinate.longitude
        //get the users location (latitude & longitude)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        if firstRun {
            firstRun = false
            let latDelta: CLLocationDegrees = 0.0025
            let lonDelta: CLLocationDegrees = 0.0025
            //a span defines how large an area is depicted on the map.
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            //a region defines a centre and a size of area covered.
            let region = MKCoordinateRegion(center: location, span: span)
            //make the map show that region we just defined.
            self.myMap.setRegion(region, animated: true)
            //the following code is to prevent a bug which affects the zooming of the map to the
            //user's location.
            //We have to leave a little time after our initial setting of the map's location and span,
            //before we can start centering on the user's location, otherwise the map never zooms in
            //because the initial zoom level and span are applied to the setCenter() method call,
            //rather than our "requested" ones, once they have taken effect on the map.
            //we setup a timer to set our boolean to true in 5 seconds.
            _ = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector:
                #selector(startUserTracking), userInfo: nil, repeats: false)
        }
        if startTrackingTheUser {
            myMap.setCenter(location, animated: true)
        }
    }

    //this method sets the startTrackingTheUser boolean class property to true. Once it's true,
    //subsequent calls to didUpdateLocations will cause the map to centre on the user's location.
    @objc func startUserTracking() {
        startTrackingTheUser = true
        
    }

    //MARK: Table related stuff
    @IBOutlet weak var theTable: UITableView!

    func tableView(
        _ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(
        _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        var content = UIListContentConfiguration.subtitleCell()
        content.text = "testing"
        content.secondaryText = "more testing"
        cell.contentConfiguration = content
        return cell
    }

    // MARK: View related Stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        // Make this view controller a delegate of the Location Manager, so that it
        //is able to call functions provided in this view controller.
        locationManager.delegate = self as CLLocationManagerDelegate
        //set the level of accuracy for the user's location.
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        //Ask the location manager to request authorisation from the user. Note that this
        //only happens once if the user selects the "when in use" option. If the user
        //denies access, then your app will not be provided with details of the user's
        //location.
        locationManager.requestWhenInUseAuthorization()
        //Once the user's location is being provided then ask for updates when the user
        //moves around.
        locationManager.startUpdatingLocation()
        //configure the map to show the user's location (with a blue dot).
        myMap.showsUserLocation = true
    }
}
