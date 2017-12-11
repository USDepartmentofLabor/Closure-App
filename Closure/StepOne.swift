//
//  StepOne.swift
//
//
//  Created by George Liu on 9/12/17.
//  Copyright © 2017 OASAM All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD

let readCityListFromMtwsSuccessNSKey = "gov.dol.oasam.readCityListFromMtwsSuccess"
let readCityListFromMtwsFailureNSKey = "gov.dol.oasam.readCityListFromMtwsFailure"

let createSubscriptionListSuccessNSKey = "gov.dol.oasam.createSubscriptionListSuccess"
let createSubscriptionListFailureNSKey = "gov.dol.oasam.createSubscriptionListFailure"

let listByCITIES = 0
let listBySTATES = 1
let listByREGION = 2

var scopeIndex = 0
var statesArray = [String]()
var cityStates = [[String]]()


class StepOne : UIViewController {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        var cityNamesHash = [String: String]()
        var cityNamesIdHash = [String: String]()
        
        var cityIDs = [String]()
        var cityIntIDs = [Int]()
        
        
        cityNamesHash.removeAll()
        cityNamesIdHash.removeAll()
        
        cityIDs.removeAll()
        cityIntIDs.removeAll()
        
        cityNamesHash = LibraryAPI.sharedInstance.getMasterCityNameHash()
        
        
        // build an array of string city_ids like: "city_ids": ["", "1", "2", "3", "4", "5"]
        
        for item in citySubscriptionSet {
            cityIDs.append(cityNamesHash[item]!)
            cityIntIDs.append(Int(cityNamesHash[item]!)!)
            
            cityNamesIdHash[item] = cityNamesHash[item]
        }
        
        LibraryAPI.sharedInstance.setMasterCityNameIdHashWith(cityNameIdHash: cityNamesIdHash)
        
        LibraryAPI.sharedInstance.setSubscriptionCitySetWith(citySubscriptionSet: citySubscriptionSet)

                
        let myDeviceToken = LibraryAPI.sharedInstance.getDeviceToken()
        
        //      Example:    https://staging.dol.gov/api/v1/CreateSubscriptionList/old-asdfasdf/7767,77675
        
        let formattedArray = (cityIntIDs.map{String($0)}).joined(separator: ",")
        let subscriptionParam = myDeviceToken + "/" + formattedArray
        
        // build json document with device id and cities
        // let jsonObject = [ "device": ["token": myDeviceToken, "city_ids": ["", "1", "2", "3", "4", "5"]] ]
        
        let jsonObject = [ "device": ["token": myDeviceToken, "city_ids": cityIDs] ]
        
        var myUrl =  LibraryAPI.sharedInstance.getDolStagingCreateSubscriptionListBase() as String
        
        myUrl += subscriptionParam
        
        showLoadingHUD()
        
        Alamofire.SessionManager.default.session.configuration.timeoutIntervalForRequest = 15
        
        Alamofire.request(myUrl, method: .post, parameters: jsonObject, encoding: JSONEncoding.default).responseString { response in
          
            let statusCode = response.response?.statusCode
            
            if (statusCode == 200) {

                switch response.result {
                
                case .success:
                    self.hideLoadingHUD()
                    self.noop()
                    
                case .failure( _):
                    self.hideLoadingHUD()
                    let alert = UIAlertController(title: "Alert", message: "Cannot create subscription list. Failure error \(String(describing: statusCode))", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                }   // end switch
            }   // end status == 200
            else {
                self.hideLoadingHUD()
                
                var message = "Cannot create subscription list. "
                if (statusCode == nil) {
                    message = message + "Server not responding."
                }
                else {
                    message = message + "Status code: \(String(describing: statusCode))"
                }
                
                let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }   // end Alamorefire
    }   // end doneButtonPressed
    
 
    var cityNamesList: [String] = []
    var cityNamesStateList: [String] = []
    var cityNamesRegionList: [String] = []
    
    var cityNamesHash = [String: String]()
    var isConnectedToServer = false
    
    var deviceTokens: [String] = []
    var citySubscriptionSet = Set<String>()     // TODO: Put this into a SINGLETON cuz other classes will need it.
    
    var isInitialLoad = false
    
    var cityListJsonArray: [Any] = []
    
    @IBOutlet weak var stepOneSearchBar: UISearchBar!
    @IBOutlet weak var stepOneSaveButton: UIButton!
    
    var citiesSubscriptionSearchResultsList: [String] = []
    var searching:Bool! = false
    var filtered:[String] = []
    
    @IBOutlet weak var stepOneTableView: UITableView!
    
    func readCityListFromMtws() {
        showLoadingHUD()
        
        let myUrl =  LibraryAPI.sharedInstance.getDolStagingListOfCitiesBase() as String
        
        Alamofire.SessionManager.default.session.configuration.timeoutIntervalForRequest = 15
        
        Alamofire.request(myUrl, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON { response in

            let statusCode = response.response?.statusCode
            
            if (statusCode == 200) {
            
                switch response.result {
                
                case .success:
                
                    self.doneButton.isEnabled = true
                    self.hideLoadingHUD()
                
                    // let data: Data // received from a network request, for example
                    self.cityListJsonArray = try! JSONSerialization.jsonObject(with: response.data!, options: []) as! [Any]
                
                    for item in self.cityListJsonArray as [Any] {
                        
                        if let dictionary = item as? [String: Any] {

                            var city = "NOCITY"
                            if (!(dictionary["city"] is NSNull)) {
                                city = dictionary["city"] as! String
                            }
                        
                            let cityID = dictionary["city_id"] as! String
                    
                            var stateCode = "XX"
                            if (dictionary["stateCode"] != nil) {
                                stateCode = dictionary["stateCode"] as! String
                            }
                             
                            var stateName = "NOSTATE"
                            if (dictionary["state"] != nil) {
                                stateName = dictionary["state"] as! String
                            }
                            
                            var regionName = "NOREGION"
                            if (dictionary["oasamRegion"] != nil) {
                                regionName = dictionary["oasamRegion"] as! String
                            }
                            
                            let cityState = city + " " + stateCode
                            
                            self.cityNamesHash[cityState] = cityID
                            self.cityNamesList.append(cityState)
                            
                            let cityNameState = cityState + "|" + stateName + "|" + stateCode
                            self.cityNamesStateList.append(cityNameState)
 
                            let cityNameRegion = cityState + "|" + regionName
                            
                            self.cityNamesRegionList.append(cityNameRegion)
                        }
                    }
                
                    /******* FOR THE ALPHABETICAL SORT SCOPE *******/
                    /******* SORT THE cityNamesList alphabetically, ascending *******/
                    self.cityNamesList.sort()
                
                    LibraryAPI.sharedInstance.setMasterCityNameHashWith(cityNameHash: self.cityNamesHash)
                
                    NotificationCenter.default.post(name: Notification.Name(rawValue: readCityListFromMtwsSuccessNSKey), object: self)
                
                case .failure(_):
                    self.hideLoadingHUD()
                    self.doneButton.isEnabled = false
                
                    let alert = UIAlertController(title: "Alert", message: "Cannot get City list.  Failure status code: \(String(describing: statusCode))", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: readCityListFromMtwsFailureNSKey), object: self)
                }   // end switch
            
                self.hideLoadingHUD()
            
            }   // end status code = 200
            else {
                self.hideLoadingHUD()
                self.doneButton.isEnabled = false
            
                var message = "Cannot get City list. "
                if (statusCode == nil) {
                    message = message + "Server not responding."
                }
                else {
                    message = message + "Status code: \(String(describing: statusCode))"
                }
                
                let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: readCityListFromMtwsFailureNSKey), object: self)
            }
            
        }   // end Alamorefire

    }   // readCityListFromMtws
    
    
    // MARK: handle notifications
    func handleCreateSubscriptionListSuccess() {
        self.hideLoadingHUD()
        self.noop()
    }
    
    func handleCreateSubscriptinListFailure() {
        self.hideLoadingHUD()
    }
    
    func handleReadCityListFromMtwsSuccess() {
        self.hideLoadingHUD()
        // 2. prep for data table load
        self.stepOneTableView.delegate = self
        self.stepOneTableView.dataSource = self
        self.stepOneTableView.backgroundView = nil
        self.stepOneTableView!.reloadData()
        
        self.stepOneSearchBar.delegate = self
    }
    
    func handleReadCityListFromMtwsFailure() {
        self.hideLoadingHUD()
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        stepOneSearchBar.scopeButtonTitles = ["Cities A-Z", "State Codes A-Z", "Region"]
    }

    
    override func viewWillAppear(_ animated: Bool) {
        self.doneButton.isEnabled = false
        
        self.cityNamesStateList.removeAll()
        self.cityNamesList.removeAll()
        self.cityNamesHash.removeAll()
        self.citySubscriptionSet.removeAll()
        self.cityNamesRegionList.removeAll()
        
        self.citySubscriptionSet = LibraryAPI.sharedInstance.getSubscriptionCitySet()
        
        // need to use notifications cuz Alamofire is an async process...
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleReadCityListFromMtwsSuccess), name: NSNotification.Name(rawValue: readCityListFromMtwsSuccessNSKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleReadCityListFromMtwsFailure), name: NSNotification.Name(rawValue: readCityListFromMtwsFailureNSKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleCreateSubscriptionListSuccess), name: NSNotification.Name(rawValue: createSubscriptionListSuccessNSKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleCreateSubscriptinListFailure), name: NSNotification.Name(rawValue: createSubscriptionListFailureNSKey), object: nil)

        scopeIndex = listByCITIES
        
        readCityListFromMtws()

        self.stepOneTableView!.reloadData()
    }   // viewWillAppear


    override func viewDidAppear(_ animated: Bool) {
        if (self.citySubscriptionSet.count == 0) {
            let alert = UIAlertController(title: "Alert", message: "Please choose which cities for which you wold like to receive notifications.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }   // viewWillDisappear
    
    
    //MARK : Progress loading HUD Ops ----------------------
    private func showLoadingHUD() {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Loading..."
    }
    
    private func hideLoadingHUD() {
        MBProgressHUD.hide(for: self.view, animated: true)
    }
}   // end class


extension StepOne: UITableViewDataSource {
    func stepOneSwitchChangedX(_ sender: Any) {        
        let rowIndex:String = (sender as AnyObject).restorationIdentifier!!
        var optionalArr = rowIndex.components(separatedBy: "\"")
        let selectedCity: String = optionalArr[0]
        
        dismissKeyboard()
        
        if (citySubscriptionSet.contains(selectedCity) == true) {
            citySubscriptionSet.remove(selectedCity)         // means was selected and now de-selected
        }
        else {
            citySubscriptionSet.insert(selectedCity)           // means was NOT selected and now IS SELECTED
        }
    }
    
    func tableView(_ stepOneTableView: UITableView, numberOfSections: Int) -> Int {
        return 1
    }

    func tableView(_ stepOneTableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (searching == true) {
            return self.citiesSubscriptionSearchResultsList.count
        }
        else {
            return self.cityNamesList.count
        }
    }
    
    
    func tableView(_ stepOneTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.stepOneTableView.dequeueReusableCell(withIdentifier: "stepOneCell")!
        cell.textLabel?.textColor = UIColor.black
        
        if (searching == false) {
            
            cell.textLabel?.text = cityNamesList[indexPath.row]
            
            let useAuthenticationSwitch = UISwitch()
            cell.accessoryView = useAuthenticationSwitch
            useAuthenticationSwitch.setOn(false, animated: true)
            useAuthenticationSwitch.addTarget(self, action: #selector(StepOne.stepOneSwitchChangedX(_:)), for: UIControlEvents.valueChanged)
            
            if (citySubscriptionSet.contains(cityNamesList[indexPath.row]) == true) {
                useAuthenticationSwitch.setOn(true, animated: true)
                cell.textLabel?.textColor = UIColor.red
            }
        
            useAuthenticationSwitch.restorationIdentifier = cityNamesList[indexPath.row]
        }
        else {
            
            cell.textLabel?.text = citiesSubscriptionSearchResultsList[indexPath.row]
            
            let useAuthenticationSwitch = UISwitch()
            cell.accessoryView = useAuthenticationSwitch
            useAuthenticationSwitch.setOn(false, animated: true)
            useAuthenticationSwitch.addTarget(self, action: #selector(StepOne.stepOneSwitchChangedX(_:)), for: UIControlEvents.valueChanged)
            
            if (citySubscriptionSet.contains(citiesSubscriptionSearchResultsList[indexPath.row]) == true) {
                useAuthenticationSwitch.setOn(true, animated: true)
                cell.textLabel?.textColor = UIColor.red
            }
            
            useAuthenticationSwitch.restorationIdentifier = citiesSubscriptionSearchResultsList[indexPath.row]
        }

        return cell
    }

    func noop() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "SWRevealVC") as UIViewController
        self.present(controller, animated: true, completion: nil)
    }
    
}   // end class



extension StepOne: UITableViewDelegate {
    
}

extension StepOne: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText == "") {
            searching = false
        }
        else {
            searching = true
    
            self.citiesSubscriptionSearchResultsList.removeAll()
            
            switch scopeIndex {
            case listByCITIES:
                for index in 0 ..< self.cityNamesList.count {
                    let currentString = self.cityNamesList[index] as String
                    if currentString.lowercased().range(of: searchText.lowercased())  != nil {
                        self.citiesSubscriptionSearchResultsList.append(currentString)
                    }
                }

            case listBySTATES:
                for index in 0 ..< self.cityNamesStateList.count {
                    let currentString = self.cityNamesStateList[index] as String
                    
                    if currentString.range(of: searchText.uppercased())  != nil {
                        self.citiesSubscriptionSearchResultsList.append(currentString.components(separatedBy: "|")[0])
                    }
                }

            case listByREGION:
                for index in 0 ..< self.cityNamesRegionList.count {
                    let currentString = self.cityNamesRegionList[index] as String
                    if currentString.lowercased().range(of: searchText.lowercased())  != nil {
                        self.citiesSubscriptionSearchResultsList.append(currentString.components(separatedBy: "|")[0])
                    }
                }
                
            default:
                print("noop")
            }   // end switch
        }
        self.stepOneTableView!.reloadData()
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        stepOneSearchBar.showsScopeBar = true
        stepOneSearchBar.sizeToFit()
        stepOneSearchBar.setShowsCancelButton(true, animated: true)
        return true
    }
 
    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        stepOneSearchBar.showsScopeBar = false
        stepOneSearchBar.sizeToFit()
        stepOneSearchBar.setShowsCancelButton(false, animated: true)
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        scopeIndex = selectedScope
        stepOneSearchBar.becomeFirstResponder()
        self.stepOneTableView!.reloadData()
    }
    
    func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        self.view.endEditing(true)
        self.stepOneSearchBar.endEditing(true)
        stepOneSearchBar.resignFirstResponder()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.stepOneSearchBar.endEditing(true)
        stepOneSearchBar.resignFirstResponder()
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        stepOneSearchBar.resignFirstResponder()
    }
    
}
