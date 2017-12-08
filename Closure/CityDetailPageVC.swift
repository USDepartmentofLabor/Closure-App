//
//  CityDetailPageVC.swift
//
//  Created by George Liu on 7/11/17.
//  Copyright © 2017 OASAM All rights reserved.
//

import UIKit

class CityDetailPageVC: UIViewController {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    @IBOutlet weak var cityStatusLabel: UILabel!
    
    @IBOutlet weak var cityNameLabel: UILabel!

    @IBOutlet weak var cityNotesLabel: UILabel!
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "SWRevealVC") as UIViewController
        self.present(controller, animated: true, completion: nil)
    }
    
    private var cs = CityStatus(region: "", state: "", cityName: "", cityStatus: "", cityNotes: "")  //LibraryAPI.sharedInstance.getSelectedCityStatus()

    override func viewDidLoad() {
        super.viewDidLoad()

        cs = LibraryAPI.sharedInstance.getSelectedCityStatus()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        
        let DOLREDCOLOR = 0xE31C3D
        let DOLGREENCOLOR = 0x2E8540
        let DOLWHITECOLOR = 0xFFFFFF
        
        let cityLabel = cs.cityName + " " + cs.state as String
                
        if (cityLabel.characters.count > 10) {
            cityNameLabel.font = cityNameLabel.font.withSize(20)
        }
        
        cityNameLabel.text = cs.cityName + " " + cs.state
        
        cityStatusLabel.text = "Open"
        if cs.cityStatus.lowercased().range(of:"closed") != nil {
            cityStatusLabel.text = "Closed"
        }
        
        cityStatusLabel.textColor = UIColor(rgb: DOLWHITECOLOR)
        cityStatusLabel.backgroundColor = UIColor(rgb: DOLGREENCOLOR)
        
        if (cs.cityStatus == "Closed") {
            cityStatusLabel.backgroundColor = UIColor(rgb: DOLREDCOLOR)
        }
        
        cityNotesLabel.text = cs.cityStatus
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}   // end CityDetailPageVC


extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
