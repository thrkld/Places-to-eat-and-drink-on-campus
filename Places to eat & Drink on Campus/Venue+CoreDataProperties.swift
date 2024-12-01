//
//  Venue+CoreDataProperties.swift
//  Places to eat & Drink on Campus
//
//  Created by James Thirkeld on 01/12/2024.
//
//

import Foundation
import CoreData


extension Venue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Venue> {
        return NSFetchRequest<Venue>(entityName: "Venue")
    }

    @NSManaged public var name: String?
    @NSManaged public var like: Bool
    @NSManaged public var building: String?
    @NSManaged public var lat: String?
    @NSManaged public var lon: String?
    @NSManaged public var desc: String?
    @NSManaged public var openingTimes: NSObject?
    @NSManaged public var amenities: NSObject?
    @NSManaged public var photos: NSObject?
    @NSManaged public var url: String?
    @NSManaged public var last_modified: String?
    @NSManaged public var dislike: Bool

}

extension Venue : Identifiable {

}
