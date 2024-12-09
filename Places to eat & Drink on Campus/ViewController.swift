//
//  ViewController.swift
//  Places to eat & Drink on Campus
//
//  Created by James Thirkeld on 01/12/2024.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

//venue structures
struct FoodData: Codable {
    var food_venues: [Venue_Info]
    let last_modified: String
}

struct Venue_Info: Codable {
    let name: String
    let building: String
    let lat: String
    let lon: String
    let description: String
    let opening_times: [String]
    let amenities: [String]?
    let photos: [String]?
    let URL: URL?
    let last_modified: String
}

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate,
MKMapViewDelegate, CLLocationManagerDelegate {
    
    
    
    // MARK: Core Data Operations
    var venues: [Venue] = []
    var venueDistances: [Double] = []
    
    //Fetches venue data from Core Data and stores in 'venues' array
    func fetchData(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Venue")
        
        do{
            //Fetch and cast to correct type
            venues = try managedContext.fetch(fetchRequest) as! [Venue]
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    
     //Function saves venues in FoodData argument to 'venues' array and updates core data for changes in a location
    func saveInitial(foodData: FoodData){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{return}
        
        var count = 0
        for aVenue in foodData.food_venues {
            
            count += 1
            let managedContext = appDelegate.persistentContainer.viewContext
            
            //Check if in core data already according to lat and lon
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Venue")
            let predicate1 = NSPredicate(format: "lat == %@", aVenue.lat)
            let predicate2 = NSPredicate(format: "lon == %@", aVenue.lon)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
            
            var newVenue : Bool = false //new venue false by default
            do{
                let results = try managedContext.fetch(fetchRequest)
                if results.isEmpty{ //if not fetched no match and is new array
                    newVenue = true
                }else{
                    let venue = results.first!
                    venue.setValue(aVenue.building, forKey: "building")
                    venue.setValue(aVenue.name, forKey: "name")
                    venue.setValue(aVenue.description, forKey: "desc")
                    venue.setValue(aVenue.opening_times as NSArray, forKey: "openingTimes")
                    venue.setValue(aVenue.amenities as NSArray?, forKey: "amenities")
                    venue.setValue(aVenue.URL?.absoluteString, forKey: "url")
                    venue.setValue(aVenue.photos as NSArray?, forKey: "photos")
                    venue.setValue(aVenue.last_modified, forKey: "last_modified")
                    do{
                        //Save to core data
                        try managedContext.save()
                        print("Saved" + String(count))
                    } catch let error as NSError {
                        print("Could not save. \(error), \(error.userInfo)")
                    }
                }
            }catch{
                print("Error thrown")
            }
                
            if newVenue{ //Save new venue (false like and dislike defaults)
                let venue = NSEntityDescription.insertNewObject(forEntityName: "Venue", into: managedContext) as! Venue
                venue.name = aVenue.name
                venue.building = aVenue.building
                venue.lat = aVenue.lat
                venue.lon = aVenue.lon
                venue.desc = aVenue.description
                venue.openingTimes = aVenue.opening_times as NSArray
                venue.amenities = aVenue.amenities as NSArray?
                venue.photos = aVenue.photos as NSArray?
                venue.url = aVenue.URL?.absoluteString
                venue.last_modified = aVenue.last_modified
                venue.like = false
                venue.dislike = false
                do{ //Save to core data and update locally stored array
                    try managedContext.save()
                    venues.append(venue)
                    print("Saved" + String(count))
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    //MARK: - LIKE/DISLIKE FUNCTIONALITY
    let likeImages = ["Unliked","Liked"] //Like image names
    var tableModeLikes: Bool = false //Wherher on likes or dislikes table
    
    /*
     Handles whether a venue is liked, unliked, disliked or undisliked
     1. If Liked/Unliked - flip image to alternate
     2. If Disliked/Undisliked - change opacity of image to 1.0 (disliked) or 0.2 (undisliked)
     For both, flip the associated venue boolean attribute, as well as ensure only 1 of Liked and Disliked are true max
     */
    @IBAction func like(_ sender: UIButton) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        
        //Get core data for likes
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Venue")
        
        if let btn = sender as? UIButton{
            
            //access image in same view as button (tagged 1)
            let parent = btn.superview!
            let likeImage = parent.viewWithTag(1) as! UIImageView
            
            //Fetch for venue with button title name
            fetchRequest.predicate = NSPredicate(format: "name == %@", btn.currentTitle!)
            do{
                let results = try managedContext.fetch(fetchRequest)
                if let venueToUpdate = results.first{
                    
                    if tableModeLikes{
                        //unliking
                        if venueToUpdate.value(forKey: "like") as! Bool{
                            venueToUpdate.setValue(false, forKey: "like")
                            likeImage.image = UIImage(named: likeImages[0])
                        }
                        //liking
                        else {
                            venueToUpdate.setValue(true, forKey: "like")
                            likeImage.image = UIImage(named: likeImages[1])
                            if venueToUpdate.value(forKey: "dislike") as! Bool{
                                venueToUpdate.setValue(false, forKey: "dislike")
                            }
                        }
                    }else{
                        //undisliking
                        if venueToUpdate.value(forKey: "dislike") as! Bool{
                            venueToUpdate.setValue(false, forKey: "dislike")
                            likeImage.layer.opacity = 0.2
                        }
                        //disliking
                        else {
                            venueToUpdate.setValue(true, forKey: "dislike")
                            likeImage.layer.opacity = 1.0
                            if venueToUpdate.value(forKey: "like") as! Bool{
                                venueToUpdate.setValue(false, forKey: "like")
                            }
                        }
                    }
                }
                
                //Save updated values
                try managedContext.save()
                
            } catch {
                print("Failed to update")
            }
        
        }else{
            print("Can't Identify Cell")
        }
    }
    
    // MARK: Segmented Control Functionality
    @IBOutlet weak var LikeModeSwitch: UISegmentedControl!
    
    //Swap table's like mode for dislike or like functionality
    @IBAction func Switched(_ sender: Any) {
        //Dislike Mode
        if(LikeModeSwitch.selectedSegmentIndex == 0){
            LikeModeSwitch.backgroundColor = .red
            tableModeLikes = false
        }
        //Like mode
        else{
            LikeModeSwitch.backgroundColor = .systemBlue
            tableModeLikes = true
        }
        likeTable.reloadData()
    }
    
    // MARK: Segue Stuff
    //Call segue function associated with sender type
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "toDetails"{
            if let pin = sender as? MKAnnotation{ //Annotation Clicked
                if let venue = venues.first(where: { $0.name == pin.title }) {
                    detailsSegueA(for: segue, venue: venue)
                } else {
                    print("No matching venue found for pin title: \(pin.title ?? "No title")")
                }
            }
            else if let cell = sender as? UITableViewCell { //Cell Clicked
                
                if let indexPath = venueTable.indexPath(for: cell) {
                    detailsSegueC(for: segue, index: indexPath.row)
                } else {
                    print("No index path found for cell.")
                }
            } else {
                print("Sender type is not recognized.")
                return
            }
        
        }
    }
    
    //Functions to send venue data to detailsViewController
    //1: Cell
    func detailsSegueC(for segue: UIStoryboardSegue, index: Int) {
        if segue.identifier == "toDetails"{
            let destination = segue.destination as! DetailsViewController
            destination.venue = venues[index]
        }
    }
    
    //2: Annotation
    func detailsSegueA(for segue: UIStoryboardSegue, venue: Venue) {
        if segue.identifier == "toDetails"{
            let destination = segue.destination as! DetailsViewController
            destination.venue = venue
        }
    }
    
    // MARK: Map & Location related stuff
    @IBOutlet weak var myMap: MKMapView!
    var locationManager = CLLocationManager()
    var firstRun = true
    var startTrackingTheUser = false
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let locationOfUser = locations[0] //Returns user's location (usually)
        let latitude = locationOfUser.coordinate.latitude
        let longitude = locationOfUser.coordinate.longitude
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        if firstRun {
            firstRun = false
            
            //Define span (size of area displayed on map)
            let latDelta: CLLocationDegrees = 0.0025
            let lonDelta: CLLocationDegrees = 0.0025
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            
            //Define region showed on map + display
            let region = MKCoordinateRegion(center: location, span: span)
            self.myMap.setRegion(region, animated: true)
            
            //the following code is to prevent a bug which affects the zooming of the map to the
            //user's location.
            //We have to leave a little time after our initial setting of the map's location and
            //span,
            //before we can start centering on the user's location, otherwise the map never zooms in
            //because the
            //intial zoom level and span are applied to the setCenter( ) method call, rather than
            //our "requested" ones,
            //once they have taken effect on the map.
            //we setup a timer to set our boolean to true in 5s
            _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector:
        #selector(startUserTracking), userInfo: nil, repeats: false)
            }

            if startTrackingTheUser == true {
                
                myMap.setCenter(location, animated: true)
                
                //Adds pins if not added already
                addPinsToMap()

                //Identifies whether the venues cloesness order has been changed to alter table accordingly
                if (venues != venuesByD(currentLoc:myMap.userLocation.coordinate)){
                    venuesReordered()
                }
            }
    }
    
    //Reorders and updates table according to closeness to users
    func venuesReordered(){
        venues = venuesByD(currentLoc: myMap.userLocation.coordinate)
        venueDistances = distances(currentLoc: myMap.userLocation.coordinate)
        likeTable.reloadData()
        venueTable.reloadData()
    }
    
    //Toggles startTrackingTheUser for centering on location and reordering venue distances
    @objc func startUserTracking() {
        startTrackingTheUser = true
        
    }
    
    //MARK: Table related stuff
    @IBOutlet weak var likeTable: UITableView!
    @IBOutlet weak var venueTable: UITableView!
    var isScrollingTable = false
    
    //Syncs scrolling of tables
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        //Prevent scrolling of other table causing function to call again by accident
        if isScrollingTable{return}
        isScrollingTable = true
        
        //Sync content offset, essentially constant height in table
        if scrollView == likeTable{
            venueTable.contentOffset = likeTable.contentOffset
        }else if scrollView == venueTable{
            likeTable.contentOffset = venueTable.contentOffset
        }
        isScrollingTable = false
    }
    
    //Selection method - If venue table selected then segue
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == venueTable{
            performSegue(withIdentifier: "toDetails", sender: tableView.cellForRow(at: indexPath))
        }
    }

    //Amount of rows = amount of venues
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return venues.count
    }
    
    /*
     Cell content
     display appropriate image and set button properties on like table (right table)
     display location name with distance and average time to distance as subtitle (left table)
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let venue = venues[indexPath.row]
        var cell : UITableViewCell!
        
        //For Like Table
        if tableView == likeTable{
            cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath)
            
            //Button code
            if let button = cell.viewWithTag(2) as? UIButton{
                button.setTitle(venue.name, for: .normal)
            }
            
            //Image code
            if let imageView = cell.viewWithTag(1) as? UIImageView {
                if tableModeLikes{ //Like mode
                    imageView.layer.opacity = 1.0
                    if venue.like{
                        imageView.image = UIImage(named: likeImages[1])
                    }else {
                        imageView.image = UIImage(named: likeImages[0])
                    }
                }
                
                else{ //Dislike mode
                    if venue.dislike{
                        imageView.image = UIImage(named: "Disliked")
                        imageView.layer.opacity = 1.0
                    }else{
                        imageView.image = UIImage(named: "Disliked")
                        imageView.layer.opacity = 0.2
                    }
                }
            }
            cell.selectionStyle = .none //Ensures can't select cell for usability purposes
            
        //For venues table
        }else{
            cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
            var content = UIListContentConfiguration.subtitleCell()
            
            //Primary text
            content.text = (venue.name ?? "")
            
            //Secondary text ("distance: ___km | time: __ minutes")
            
            
            if venueDistances.count >= (indexPath.row + 1) {
                
                //Calculations
                var distance = venueDistances[indexPath.row] //in m for calculation, later in km for formatting
                let time = Int(ceil(distance / (1.2 * 60))) //1.2 m/s average walking speed, corrected to minutes and rounded up
                distance = distance / 1000
                distance = round(distance * 10) / 10 //round to 1dp
                
                //Formatting
                var timeString = ""
                if time < 1 {
                    timeString = "<1 minute"
                }else if time < 2 {
                    timeString = "1 minute"
                }else{
                    timeString = String(time) + " minutes"
                }
                content.secondaryText = ("distance: " + "\(distance)km" + "  |  " + "time: " + timeString)
                
            }else{ //No distance info for cell
                content.secondaryText = ""
            }
            cell.contentConfiguration = content
        }
            return cell
    }
    
    //function to reset core data in case of emergency
    func deleteAll(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        for venue in venues {
            managedContext.delete(venue)
        }
    }
    
    
    // MARK: View related Stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Location manager functions for requesting, then setting up map at user location
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        
        print("aaaaaaaaaaaah")
        locationManager.startUpdatingLocation()
        myMap.showsUserLocation = true
        //fetch Data for later use
        fetchData()
        
        //Add new venues
        getJsonInfo()
        
        //Update UI information
        venueTable.showsVerticalScrollIndicator = false
        likeTable.showsVerticalScrollIndicator = false
        likeTable.separatorStyle = .none
        likeTable.reloadData()
        venueTable.reloadData()
        LikeModeSwitch.backgroundColor = .red
        
    }
    
    //Gets JSON information
    func getJsonInfo(){
        if let url = URL(string: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/eating_venues/data.json"){
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, err) in
                guard let jsonData = data else {
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let venuInfo = try decoder.decode(FoodData.self, from: jsonData)
                    self.saveInitial(foodData: venuInfo)
                } catch let jsonErr {
                    print("Error decoding JSON", jsonErr)
                }
            }.resume()
            print("You are here!")
        }
    }
    
    //Update map/table when reloaded
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        venueTable.reloadData()
        likeTable.reloadData()
        addPinsToMap()
    }
    
    //MARK: Annotations
    var pinsAdded : Bool = false
    //Code to add pins at all venue locations
    func addPinsToMap(){
        if pinsAdded == false {
            for venue in venues{
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: Double(venue.lat!)!, longitude: Double(venue.lon!)!)
                annotation.title = venue.name
                myMap.addAnnotation(annotation)
            }
        }
        
    }

    //Annotation selection
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        mapView.deselectAnnotation(annotation, animated: false)
        performSegue(withIdentifier: "toDetails", sender: annotation)
    }
    
    //Returns venues by distance from given location (currentLoc)
    func venuesByD(currentLoc: CLLocationCoordinate2D) -> [Venue]{
        var resultVenues: [Venue] = [] //to return
        var distances: [Double] = []
        
        //Add distances from user location + the venues themselves to arrays
        for venue in venues{
            let currentLocation = CLLocation(latitude: currentLoc.latitude, longitude: currentLoc.longitude)
            let venueLocation = CLLocation(latitude: Double(venue.lat!)!, longitude: Double(venue.lon!)!)
            let distance = currentLocation.distance(from: venueLocation)
            distances.append(distance)
            resultVenues.append(venue)
        }
        
        var combined = zip(distances, resultVenues).map{($0, $1)} //creates tuple, distances in element 0 venues in element 1
        combined.sort { $0.0 < $1.0 } //Sorts tuple in order of distances
        resultVenues = combined.map { $0.1 } //Set resultVenues to array of element 1 (venues sorted by distance)
        
        return resultVenues
    }
    
    //Same as venuesByD() but returns the distances themselves
    func distances(currentLoc: CLLocationCoordinate2D) -> [Double]{
        var resultVenues: [Venue] = [] //to return
        var distances: [Double] = []
        
        //Add distances from user location + the venues themselves to arrays
        for venue in venues{
            let currentLocation = CLLocation(latitude: currentLoc.latitude, longitude: currentLoc.longitude)
            let venueLocation = CLLocation(latitude: Double(venue.lat!)!, longitude: Double(venue.lon!)!)
            let distance = currentLocation.distance(from: venueLocation)
            distances.append(distance)
            resultVenues.append(venue)
        }
        var combined = zip(distances, resultVenues).map{($0, $1)} //creates tuple, distances in element 0 venues in element 1
        combined.sort { $0.0 < $1.0 } //Sorts tuple in order of distances
        distances = combined.map { $0.0 } //Set resultVenues to array of element 0 (distances sorted)
       
        return distances
    }
    
    
}
