//
//  CityStatus.swift
//  Closure
//
//  Created by George Liu on 6/29/17.
//  Copyright © 2017 OASAM. All rights reserved.
//

import UIKit

class CityStatus {
    
    //MARK: Properties
    
    var region = ""
    var state = ""
    var cityName = ""
    var cityStatus = ""
    var cityNotes = ""

    init(region: String, state: String, cityName: String, cityStatus: String, cityNotes: String) {

            self.cityName = cityName

            self.cityStatus = cityStatus
     
            self.state = state

            self.cityNotes = cityNotes

            self.region = region
    } 
    
}


