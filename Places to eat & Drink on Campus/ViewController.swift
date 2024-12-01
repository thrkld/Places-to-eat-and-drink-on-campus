//
//  ViewController.swift
//  Places to eat & Drink on Campus
//
//  Created by James Thirkeld on 01/12/2024.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        var content = UIListContentConfiguration.cell()
        //content.text = "Place \(indexPath.row)"
        /*
        if places[indexPath.row]["name"] != nil {
            content.text = places[indexPath.row]["name"]
        }
         */
        cell.contentConfiguration = content
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

