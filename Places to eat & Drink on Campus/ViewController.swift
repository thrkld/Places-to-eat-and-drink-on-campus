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

struct Venue_DL: Codable{
    let like: Bool
    let dislike: Bool
}


import UIKit
import MapKit
import CoreLocation

//view controller class
class ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate,
MKMapViewDelegate, CLLocationManagerDelegate {
    
    // MARK: Core Data related
    
    let images = ["Unliked","Liked"]
    var venues: [Venue] = []
    var venueLikes: [Venue_DL] = []
    var venueDistances: [Double] = []
    
    //receive venue data
    func fetchData(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Venue")
        
        do{
            venues = try managedContext.fetch(fetchRequest) as! [Venue]
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    //Adding to core data
    func saveInitial(foodData: FoodData){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        var count = 0
        for aVenue in foodData.food_venues {
            count += 1
            let managedContext = appDelegate.persistentContainer.viewContext
            let venue = NSEntityDescription.insertNewObject(forEntityName: "Venue", into: managedContext) as! Venue
            
            venue.name = aVenue.name
            venue.building = aVenue.building
            venue.lat = aVenue.lat
            venue.lon = aVenue.lon
            venue.desc = aVenue.description
            
            //transformables
            venue.openingTimes = aVenue.opening_times as NSArray
            venue.amenities = aVenue.amenities as NSArray?
            venue.photos = aVenue.photos as NSArray?
            
            
            venue.url = aVenue.URL?.absoluteString
            venue.last_modified = aVenue.last_modified
            venue.like = false
            venue.dislike = false
            
            do{
                try managedContext.save()
                venues.append(venue)
                print("Saved" + String(count))
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    //like a location
    @IBOutlet weak var likeImage: UIImageView!
    @IBAction func like(_ sender: UIButton) {
        
        if let cell = sender.superview?.superview as? UITableViewCell{
            
            print("performed")
            if let indexPath = likeTable.indexPath(for: cell){
                let venue = venues[indexPath.row]
                venue.like.toggle()
                print(indexPath.row)
                likeTable.reloadRows(at: [indexPath], with: .automatic)
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
                    return
                }
                
                let managedContext = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Venue")
                do {
                        // Fetch the venue in core data
                        let results = try managedContext.fetch(fetchRequest)
                                    
                        // Ensures name in core data is same as name in venue array
                        if let venueToUpdate = results.first(where: { ($0 as! Venue).name == venue.name }) {
                            venueToUpdate.setValue(venue.like, forKey: "like")
                                        
                            // Save core data
                            try managedContext.save()
                        }
                } catch {
                    print("Failed to update")
                }
            }
        }else{
            print("Can't Identify Cell")
        }
    }
    
    // MARK: Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "toDetails"{
            print("HELLO1")
            print(type(of: sender))
            if let pin = sender as? MKAnnotation{
                print("HELLO2")
                // Access the venues array to find a matching venue
                if let venue = venues.first(where: { $0.name == pin.title }) {
                    detailsSegueA(for: segue, venue: venue)
                } else {
                    print("No matching venue found for pin title: \(pin.title ?? "No title")")
                }
            } else if let cell = sender as? UITableViewCell {
                if let indexPath = theTable.indexPath(for: cell) {
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
    func detailsSegueC(for segue: UIStoryboardSegue, index: Int) {
        if segue.identifier == "toDetails"{
            let destination = segue.destination as! DetailsViewController
            
            destination.venue = venues[index]
        }
    }
    
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
            //the following code is to prevent a bug which affects the zooming of the map to the user's location.
            //We have to leave a little time after our initial setting of the map's location and span, before we can start centering on the user's location, otherwise the map never zooms in because the intial zoom level and span are applied to the setCenter( ) method call, rather than our "requested" ones,
            //once they have taken effect on the map.
            
            //we setup a timer to set our boolean to true in 5 seconds.
            _ = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector:
        #selector(startUserTracking), userInfo: nil, repeats: false)
            }
            if startTrackingTheUser == true {
                myMap.setCenter(location, animated: true)
                venues = distance(currentLoc: myMap.userLocation.coordinate)
                venueDistances = distances(currentLoc: myMap.userLocation.coordinate)
                
                print("\n\n\n\n\n")
                var count = 0
                for venue in venues{
                    print(venue.name! + "\(venueDistances[count])")
                }
                
                likeTable.reloadData()
                theTable.reloadData()
            }
    }
    
    //this method sets the startTrackingTheUser boolean class property to true. Once it's true,
    //subsequent calls to didUpdateLocations will cause the map to centre on the user's location.
    @objc func startUserTracking() {
        startTrackingTheUser = true
        
    }
    
    //MARK: Table related stuff
    @IBOutlet weak var likeTable: UITableView!
    @IBOutlet weak var theTable: UITableView!
    var isScrollingTable = false
    
    //Syncs scrolling of tables
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isScrollingTable{
            return
        }
        
        isScrollingTable = true
        
        if scrollView == likeTable{
            theTable.contentOffset = likeTable.contentOffset
        }else if scrollView == theTable{
            likeTable.contentOffset = theTable.contentOffset
        }
        isScrollingTable = false
    }
    
    func selection(for row: Int){
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == theTable{
            print("type is: \(type(of: self))")
            performSegue(withIdentifier: "toDetails", sender: tableView.cellForRow(at: indexPath))
        }
    }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return venues.count
        }
    
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let venue = venues[indexPath.row]
            var cell : UITableViewCell!
            if tableView == likeTable{
                cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath)
                if let imageView = cell.viewWithTag(1) as? UIImageView {
                        if venue.like{
                        // Assign the image to the image view
                        imageView.image = UIImage(named: images[1])
                        }else {
                            imageView.image = UIImage(named: images[0])
                        }
                    }
                cell.selectionStyle = .none
            }else{ //normal table
                cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
                var content = UIListContentConfiguration.subtitleCell()
                content.text = (venue.name ?? "")
                if venueDistances.count >= (indexPath.row + 1) {
                    var distance = venueDistances[indexPath.row] //in m for calculation, later in km for formatting
                    let time = Int(ceil(distance / (1.2 * 60))) //1.2 m/s average walking speed, corrected to minutes and rounded up
                    distance = distance / 1000 //km
                    distance = round(distance * 10) / 10 //round to 1dp
                    var timeString = ""
                    if time < 1 {
                        timeString = "<1 minute"
                    }else if time < 2 {
                        timeString = "1 minute"
                    }else{
                        timeString = String(time) + " minutes"
                    }
                    content.secondaryText = ("distance: " + "\(distance)km" + "  |  " + "time: " + timeString)
                    
                }else{
                    content.secondaryText = ""
                }
                
                cell.contentConfiguration = content
            }
            
            return cell
        }
    //function to reset core data
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
        
        
        //Fetching core data for later use
        fetchData()
        
        //Bug fixing
        //deleteAll()
        //UserDefaults.standard.set(false, forKey: "hasLaunchedBefore")
        
        //acquiring json information and assigning into core data if first launch
        let launchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        
        
        //First launch
        if !launchedBefore {
            print("PERFORMED")
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
            
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        
        //Table settings
        theTable.showsVerticalScrollIndicator = false
        likeTable.showsVerticalScrollIndicator = false
        likeTable.separatorStyle = .none
        likeTable.reloadData()
        theTable.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        likeTable.reloadData()
        addPinsToMap()
        
    }
    
    //MARK: Annotation
    //Code to add pins
    func addPinsToMap(){
        for venue in venues{
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: Double(venue.lat!)!, longitude: Double(venue.lon!)!)
            annotation.title = venue.name
            myMap.addAnnotation(annotation)
        }
    }
    
    //Variable for selection (double tap)
    //Annotation selection
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        performSegue(withIdentifier: "toDetails", sender: annotation)
    }
    
    
    func distance(currentLoc: CLLocationCoordinate2D) -> [Venue]
    {
        var resultVenues: [Venue] = []
        var distances: [Double] = []
        for venue in venues{
            let currentLocation = CLLocation(latitude: currentLoc.latitude, longitude: currentLoc.longitude)
            let venueLocation = CLLocation(latitude: Double(venue.lat!)!, longitude: Double(venue.lon!)!)
            let distance = currentLocation.distance(from: venueLocation)
            distances.append(distance)
            resultVenues.append(venue)
        }
        var combined = zip(distances, resultVenues).map{($0, $1)} //creates tuple, distances in element 0 venues in element 1
        combined.sort { $0.0 < $1.0 }
        
        resultVenues = combined.map { $0.1 }
        
        
        return resultVenues
    }
    
    func distances(currentLoc: CLLocationCoordinate2D) -> [Double]{
        var resultVenues: [Venue] = []
        var distances: [Double] = []
        for venue in venues{
            let currentLocation = CLLocation(latitude: currentLoc.latitude, longitude: currentLoc.longitude)
            let venueLocation = CLLocation(latitude: Double(venue.lat!)!, longitude: Double(venue.lon!)!)
            let distance = currentLocation.distance(from: venueLocation)
            distances.append(distance)
            resultVenues.append(venue)
        }
        var combined = zip(distances, resultVenues).map{($0, $1)} //creates tuple, distances in element 0 venues in element 1
        combined.sort { $0.0 < $1.0 }
        
        distances = combined.map { $0.0 }
        return distances
    }
    
    
}
