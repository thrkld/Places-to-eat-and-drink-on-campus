//
//  DetailsViewController.swift
//  Places to eat & Drink on Campus
//
//  Created by James Thirkeld on 02/12/2024.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController {

    //like a location
    @IBOutlet weak var likeImage: UIImageView!
    @IBAction func like(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Venue")
        
        do{
            let results = try managedContext.fetch(fetchRequest)
            
            if let venueToUpdate = results.first{
                venueToUpdate.setValue(true, forKey: "like")
            }
        } catch {
            print("Failed to update")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
