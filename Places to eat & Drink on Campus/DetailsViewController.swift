//
//  DetailsViewController.swift
//  Places to eat & Drink on Campus
//
//  Created by James Thirkeld on 02/12/2024.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController {

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
    
    func showInf(){
        //Title
        venueTitle.text = venue.name
        
        //description
        if let data = venue.desc!.data(using: .utf8){
            do{
                let description : NSAttributedString = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html],documentAttributes: nil)
                venueDesc.attributedText = description
            }catch{
                print(error)
            }
        }
        
        //Liked
        if venue.like{
            likeImage.image = UIImage(named: images[1])
        }else{
            likeImage.image = UIImage(named: images[0])
        }
        
        //Liked
        if venue.dislike{
            dislikeImage.layer.opacity = 1.0
        }else{
            dislikeImage.layer.opacity = 0.2
        }
        
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
