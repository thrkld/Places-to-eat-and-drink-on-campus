//
//  DetailsViewController.swift
//  Places to eat & Drink on Campus
//
//  Created by James Thirkeld on 02/12/2024.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let photos = venue.photos as! [String]
        if photos.count == 0{
            return 1 //"empty" cell
        }
        return photos.count //shouldn't occur!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if venue.photos as! [String] == []{
            cell.contentView.addSubview(UIImageView(image: UIImage(named: "empty")!)) //add "empty" image
        }
        return cell
    }
    
    
    //MARK: PickerView functionality
    let daysOfWeek: [String] = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    //Should Contain all days of week
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        7
    }
    
    //Update time lbl information
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        let selectedOption = openingTimes[row]
        openingTimeslbl.text = selectedOption
    }
    
    //Days of week
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return daysOfWeek[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = UILabel()
            label.text = daysOfWeek[row]
            label.font = UIFont.systemFont(ofSize: 10) // Set your desired font size here
            label.textAlignment = .center
            return label
        }
    

    //images
    let images = ["Unliked","Liked"]
    let images2 = "disliked"
    var venue: Venue = Venue()
    
    //Outlets
    @IBOutlet weak var venueDesc: UITextView!
    @IBOutlet weak var venueTitle: UILabel!
    
    //dislike a location
    @IBOutlet weak var dislikeImage: UIImageView!
    @IBAction func dislike(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Venue")
        
        //Filter by string
        let titleString = venueTitle.text!
        fetchRequest.predicate = NSPredicate(format: "name == %@", titleString)
        do{
            let results = try managedContext.fetch(fetchRequest)
            
            if let venueToUpdate = results.first{
                if venueToUpdate.value(forKey: "dislike") as! Bool{
                    venueToUpdate.setValue(false, forKey: "dislike")
                    print("DISLIKED = FALSE")
                    dislikeImage.layer.opacity = 0.2
                }else {
                    venueToUpdate.setValue(true, forKey: "dislike")
                    print("DISLIKED = TRUE")
                    dislikeImage.layer.opacity = 1.0
                    if venueToUpdate.value(forKey: "like") as! Bool{
                        venueToUpdate.setValue(false, forKey: "like")
                        likeImage.image = UIImage(named: images[0])
                    }
                }
            }
            
            
        } catch {
            print("Failed to update")
        }
    }
    
    //like a location
    @IBOutlet weak var likeImage: UIImageView!
    @IBAction func like(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Venue")
        
        //Filter by string
        let titleString = venueTitle.text!
        fetchRequest.predicate = NSPredicate(format: "name == %@", titleString)
        do{
            let results = try managedContext.fetch(fetchRequest)
            
            if let venueToUpdate = results.first{
                if venueToUpdate.value(forKey: "like") as! Bool{
                    venueToUpdate.setValue(false, forKey: "like")
                    likeImage.image = UIImage(named: images[0])
                }else {
                    venueToUpdate.setValue(true, forKey: "like")
                    likeImage.image = UIImage(named: images[1])
                    if venueToUpdate.value(forKey: "dislike") as! Bool{
                        venueToUpdate.setValue(false, forKey: "dislike")
                        dislikeImage.layer.opacity = 0.2
                    }
                }
            }
            
            
        } catch {
            print("Failed to update")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(venue.name!)
        showInf()
        // Do any additional setup after loading the view.
    }
    
    //Outlets for information
    @IBOutlet weak var openingTimeslbl: UILabel!
    @IBOutlet weak var lastModifiedlbl: UILabel!
    @IBOutlet weak var amenitiesText: UITextView!
    @IBOutlet weak var openingTimesSelect: UIPickerView!
    
    var openingTimes : [String] = []
    func showInf(){
        //Title
        venueTitle.text = venue.name
        
        //description
        venueDesc.isEditable = false
        if let data = venue.desc!.data(using: .utf8){
            do{
                let description : NSAttributedString = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html],documentAttributes: nil)
                venueDesc.attributedText = description
            }catch{
                print(error)
            }
        }
        
        if venue.desc!.isEmpty{
            let emptyText : NSAttributedString = NSAttributedString(string: "<NO DESCRIPTION>")
            venueDesc.attributedText = emptyText
            venueDesc.textColor = .red
            venueDesc.textAlignment = .center
            venueDesc.font = UIFont(name: "System", size: 30)
        }
        
        //Liked
        if venue.like{
            likeImage.image = UIImage(named: images[1])
        }else{
            likeImage.image = UIImage(named: images[0])
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
                amenitiesText.text.append("\(amenity)\n")
            }
        }else{
            amenitiesText.text = "<BLANK>"
        }
        
        //last modified
        var lastModified = venue.last_modified
        for var i in lastModified!{
            if(i == (" ")){
                i = ("\n")
            }
        }
        lastModifiedlbl.text = lastModified
        
        //Opening times initial
        openingTimes = venue.openingTimes as? [String] ?? []
        //Slight reformat
        var count = 0
        for var openingTime in openingTimes{
            if openingTime.contains("-") {
                var openingTimeNew = openingTime.split(separator: "-")
                openingTime = openingTimeNew[0].appending(" - ").appending(openingTimeNew[1])
                openingTimes[count] = openingTime
            }else{
                openingTimes[count] = "CLOSED"
            }
            count += 1
            
        }
        openingTimeslbl.text = openingTimes[0]
        
        //Photos dealt with in collection view
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
