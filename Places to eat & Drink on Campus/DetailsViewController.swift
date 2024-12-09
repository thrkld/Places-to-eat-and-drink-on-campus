//
//  DetailsViewController.swift
//  Places to eat & Drink on Campus
//
//  Created by James Thirkeld on 02/12/2024.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    //Venue info being displayed
    var venue: Venue = Venue()
    
    //MARK: UI Element functionality
    //Outlets
    @IBOutlet weak var venueDesc: UITextView!
    @IBOutlet weak var venueTitle: UILabel!
    @IBOutlet weak var openingTimeslbl: UILabel!
    @IBOutlet weak var lastModifiedlbl: UILabel!
    @IBOutlet weak var amenitiesTextView: UITextView!
    @IBOutlet weak var openingTimesSelect: UIPickerView!
    
    //Photos collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let photos = venue.photos as! [String]
        if photos.count == 0{
            return 1 //"empty" cell
        }
        return photos.count //shouldn't occur in assignment!
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if venue.photos as! [String] == []{
            cell.contentView.addSubview(UIImageView(image: UIImage(named: "empty")!)) //add "empty" image
        }
        return cell
    }
    
    
    //PickerView functionality
    let daysOfWeek: [String] = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    //Contains all days of week
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        7
    }
    
    //Update time lbl information to picked day
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        let selectedOption = openingTimes[row]
        openingTimeslbl.text = selectedOption
    }
    
    //Days of week
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return daysOfWeek[row]
    }
    
    //Add label for formatting
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = UILabel()
            label.text = daysOfWeek[row]
            label.font = UIFont.systemFont(ofSize: 10)
            label.textAlignment = .center
            return label
        }
    //MARK: LINK FUNCTIONALITY
    @IBAction func HyperlinkPressed(_ sender: Any) {
        UIApplication.shared.open(URL(string: venue.url!)!)
    }
    //MARK: LIKE FUNCTIONALITY
    let likeImages = ["Unliked","Liked"]
    
    /*Dislike/Undislike a location  - change opacity of image to 1.0 (disliked) or 0.2 (undisliked)
    Also ensure if disliked, like is set to false*/
    @IBOutlet weak var dislikeImage: UIImageView!
    @IBAction func dislike(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        
        //Get core data for dislikes
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Venue")
        
        //Fetch for venue with venue name
        let titleString = venue.name!
        fetchRequest.predicate = NSPredicate(format: "name == %@", titleString)
        
        
        do{
            let results = try managedContext.fetch(fetchRequest)
            if let venueToUpdate = results.first{
                
                //Undisliking
                if venueToUpdate.value(forKey: "dislike") as! Bool{
                    venueToUpdate.setValue(false, forKey: "dislike")
                    dislikeImage.layer.opacity = 0.2
                }
                //Disliking
                else {
                    venueToUpdate.setValue(true, forKey: "dislike")
                    dislikeImage.layer.opacity = 1.0
                    if venueToUpdate.value(forKey: "like") as! Bool{
                        venueToUpdate.setValue(false, forKey: "like")
                        likeImage.image = UIImage(named: likeImages[0])
                    }
                }
            }
            
            //Save updated values
            try managedContext.save()
            
        } catch {
            print("Failed to update")
        }
    }
    
    
    /*Like/Unlike a location  - change image to likeImages[0] unliked or likeImages[1] liked
    Also ensure if liked, dislike is set to false*/
    @IBOutlet weak var likeImage: UIImageView!
    @IBAction func like(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        
        //Get core data for likes
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Venue")
        
        //Fetch for venue with name
        let titleString = venue.name!
        fetchRequest.predicate = NSPredicate(format: "name == %@", titleString)
        do{
            let results = try managedContext.fetch(fetchRequest)
            if let venueToUpdate = results.first{
                //Unliking
                if venueToUpdate.value(forKey: "like") as! Bool{
                    venueToUpdate.setValue(false, forKey: "like")
                    likeImage.image = UIImage(named: likeImages[0])
                }
                //Liking
                else {
                    venueToUpdate.setValue(true, forKey: "like")
                    likeImage.image = UIImage(named: likeImages[1])
                    if venueToUpdate.value(forKey: "dislike") as! Bool{
                        venueToUpdate.setValue(false, forKey: "dislike")
                        dislikeImage.layer.opacity = 0.2
                    }
                }
            }
            
            //Save updated values
            try managedContext.save()
            
        } catch {
            print("Failed to update")
        }
    }
    
    //Once loaded display the information
    override func viewDidLoad() {
        super.viewDidLoad()
        showInf()
    }

    var openingTimes : [String] = []
    
    //Code to display information
    func showInf(){
        //Title
        venueTitle.text = venue.name
        
        //description
        venueDesc.isEditable = false
        //Format as html
        if let data = venue.desc!.data(using: .utf8){
            do{
                let description : NSAttributedString = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html],documentAttributes: nil)
                venueDesc.attributedText = description
            }catch{
                print(error)
            }
        }
        
        
        if venue.desc!.isEmpty{ //display "<NO DESCRIPTION>" in large red font
            let emptyText : NSAttributedString = NSAttributedString(string: "<NO DESCRIPTION>")
            venueDesc.attributedText = emptyText
            venueDesc.textColor = .red
            venueDesc.textAlignment = .center
            venueDesc.font = UIFont(name: "System", size: 30)
        }
        
        //Liked
        if venue.like{
            likeImage.image = UIImage(named: likeImages[1])
        }else{
            likeImage.image = UIImage(named: likeImages[0])
        }
        
        //Disliked
        if venue.dislike{
            dislikeImage.layer.opacity = 1.0
        }else{
            dislikeImage.layer.opacity = 0.2
        }
        
        //Amentities
        if venue.amenities as! [String] != []{
            for amenity in (venue.amenities as? [String] ?? []) {
                amenitiesTextView.text.append("\(amenity)\n")
            }
        }else{
            amenitiesTextView.text = "<BLANK>"
        }
        
        //last modified
        var lastModified = venue.last_modified
        
        //Reformat so it's on 2 lines
        for var i in lastModified!{
            if(i == (" ")){
                i = ("\n")
            }
        }
        lastModifiedlbl.text = lastModified
        
        //Opening times initial
        openingTimes = venue.openingTimes as? [String] ?? []
        
        //Reformat (turns "time-time" to "time - time") and
        var count = 0
        for var openingTime in openingTimes{
        
            if openingTime.contains("-") { //If times are given
                //Replace "-" with " - "
                var openingTimeNew = openingTime.split(separator: "-")
                openingTime = openingTimeNew[0].appending(" - ").appending(openingTimeNew[1])
                openingTimes[count] = openingTime
                
            }else{ //No times given
                openingTimes[count] = "CLOSED"
            }
            count += 1
            
        }
        
        openingTimeslbl.text = openingTimes[0] //Default to "monday"
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
