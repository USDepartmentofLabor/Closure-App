//
//  CityDetailPageVC.swift
//
//  Created by George Liu on 7/11/17.
//  Copyright © 2017 OASAM All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire


let DOLREDCOLOR = 0xE31C3D
let DOLGREENCOLOR = 0x7ED321    //0x2E8540
let DOLWHITECOLOR = 0xFFFFFF
let DOLROBOTOLIGHTCOLOR = 0x030303
let DOLORANGECOLOR = 0xFD5739


class CityDetailPageVC: UIViewController {
    
    
    
    @IBOutlet weak var cityDetailImageView: UIImageView!
    @IBOutlet weak var cityDetailTempLabel: UILabel!
    @IBOutlet weak var cityDetailUpdatedLabel: UILabel!
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    @IBOutlet weak var cityStatusLabel: UILabel!
    
    @IBOutlet weak var cityNameLabel: UILabel!

    @IBOutlet weak var cityNotesLabel: UILabel!
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "myCitiesNavVC") as UIViewController
        self.present(controller, animated: true, completion: nil)
    }
    
    private var cs = CityStatus(region: "", state: "", cityName: "", cityStatus: "", cityNotes: "", updatedOn: "")  //LibraryAPI.sharedInstance.getSelectedCityStatus()

    
    //////////////////////////////////////////////////////////////////////
    //MARK: VIEW CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()

        cs = LibraryAPI.sharedInstance.getSelectedCityStatus()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let cityLabel = cs.cityName + " " + cs.state as String
                
        if (cityLabel.characters.count > 10) {
            cityNameLabel.font = cityNameLabel.font.withSize(20)
        }
        
        cityNameLabel.text = cs.cityName + ", " + cs.state
        
        cityStatusLabel.text = "Open"
        if cs.cityStatus.lowercased().range(of:"closed") != nil {
            cityStatusLabel.text = "Closed"
        }
        
        cityStatusLabel.textColor = UIColor(rgb: DOLWHITECOLOR)
        cityStatusLabel.backgroundColor = UIColor(rgb: DOLGREENCOLOR)
        cityStatusLabel.layer.cornerRadius = 50
        
        if cs.cityStatus.lowercased().range(of:"closed") != nil {
            cityStatusLabel.backgroundColor = UIColor(rgb: DOLREDCOLOR)
        }
        
        let newLines = String(repeating: "\n", count: 50)
        cityNotesLabel.numberOfLines = 0
        cityNotesLabel.sizeToFit()
        cityNotesLabel.textColor = UIColor(rgb: DOLROBOTOLIGHTCOLOR)
        cityNotesLabel.text = cs.cityNotes + newLines
        
        showWeatherTempAndIcon()
        
        cityDetailUpdatedLabel.isEnabled = false
        cityDetailUpdatedLabel.text = ""
        let updatedOn = cs.updatedOn
        if (updatedOn != "") {
            cityDetailUpdatedLabel.isEnabled = true
            cityDetailUpdatedLabel.text = "Updated: " + updatedOn
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    //////////////////////////////////////////////////////////////////////
    //MARK: WEATHER SUPPORT - ALAMOFIRE
    func showWeatherTempAndIcon() {
        
        let myUrl = "https://api.weather.gov/gridpoints/TOP/31,80/forecast"  // LibraryAPI.sharedInstance.getDolStagingListOfCitiesBase() as String
            
        Alamofire.SessionManager.default.session.configuration.timeoutIntervalForRequest = 15
            
        Alamofire.request(myUrl, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON { response in
                
            let statusCode = response.response?.statusCode
                
            if (statusCode == 200) {
                    
                switch response.result {
                        
                case .success:
                    
                    // let data: Data // received from a network request, for example
                    let cityWeatherJson = try! JSONSerialization.jsonObject(with: response.data!, options: [])
                    
                    if let cwDictionary = cityWeatherJson as? [String: Any] {

                        if let cwPropertiesDictionary = cwDictionary["properties"] as? [String: Any] {
                    
                            if  let cwPeriodsArray = cwPropertiesDictionary["periods"] as? [Any]  {              //[Dictionary<String, Array<String>>]  {
                                print("DETAILVC: showWeatherTempAndIcon: temperature: ", cwPeriodsArray.count)
                                
                                for item in cwPeriodsArray as [Any] {
                                    
                                    if let dictionary = item as? [String: Any] {
                                        
                                        if (dictionary["isDaytime"] != nil && dictionary["number"] != nil) {
                                            
                                            let number = dictionary["number"] as? Int
                                            
                                            if (number == 1) {
                                                let temperature = dictionary["temperature"] as? Int
                                                var icon = dictionary["icon"] as? String
                                                
                                                var optionalArr = icon?.components(separatedBy: ":")
                                                let backUrl: String = optionalArr![1]
                                                
                                                icon = "https:" + backUrl
                                                
//
//                      self.cityDetailImageView.downloadedFrom(link: icon!)
//                      self.cityDetailTempLabel.text = String(describing: temperature) + " F"
                                                
//                      let tempString = String(describing: temperature)
//                      print(tempString)
                                                
                                                self.cityDetailTempLabel.text = "" //tempString + " F"

                                            }
                                        }
                                    }
                                }   // end for
                            }
                        }
                    }
                    
                default:
                    print("noop")
                }   // end switch
                
            }   // end status code = 200

        }   // end Alamorefire

    }   // end getWeatherTempAndIcon
    
    
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


extension UIImageView {
    /*
    ** make sure to use https or adjust in plist
    */
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
