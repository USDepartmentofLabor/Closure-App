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
        
        if (citySubscriptionSet.count == 0) {
            let alert = UIAlertController(title: "Cannot create subscription list.", message: "Please select one or more cities.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else {
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
                        let alert = UIAlertController(title: "Cannot create subscription list.", message: "No internet connection available.", preferredStyle:  UIAlertControllerStyle.alert)
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
                
                    let alert = UIAlertController(title: "Cannot create subscription list.", message: "No internet connection available.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }   // end Alamorefire
        }   // if citysubscriptinseg == 0
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
    
    var stateCodeToStateDictionary = Dictionary<String, String>()
    
    var cityFilterDictionary = Dictionary<String, Array<String>>()
    var cityFilterTitleArray = [String]()
    var cityFilterUniqueFirstCharacterArray = [String]()
    var cityIndexToSectionDictionary = Dictionary<String, Int>()
    
    var stateFilterDictionary = Dictionary<String, Array<String>>()
    var stateFilterTitleArray = [String]()
    var stateFilterUniqueFirstCharacterArray = [String]()
    var stateIndexToSectionDictionary = Dictionary<String, Int>()
    
    var regionFilterDictionary = Dictionary<String, Array<String>>()
    var regionFilterTitleArray = [String]()
    var regionFilterUniqueFirstCharacterArray = [String]()
    var regionIndexToSectionDictionary = Dictionary<String, Int>()
    
    var indexList = [String]()
    
    @IBOutlet weak var stepOneSearchBar: UISearchBar!
    @IBOutlet weak var stepOneSaveButton: UIButton!
    
    let BYCITY = 0
    let BYSTATE = 1
    let BYREGION = 2
    
    @IBOutlet weak var stepOneSegmentControl: UISegmentedControl!

    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        scopeIndex = stepOneSegmentControl.selectedSegmentIndex
        
        print("STEPONEVC: indexChanged: SCOPEINDEX: ", scopeIndex)
        
        switch (scopeIndex) {
        case BYCITY:
            stepOneSearchBar.placeholder = "Please enter a City name."
        case BYSTATE:
            stepOneSearchBar.placeholder = "Please enter a State name."
        default:
            stepOneSearchBar.placeholder = "Please enter a Region name."
        }
        self.stepOneTableView!.reloadData()
    }
    
    var citiesSubscriptionSearchResultsList: [String] = []
    var statesSubscriptionSearchResultsList: [String] = []
    var regionSubscriptionSearchResultsList: [String] = []
    
    var searching:Bool! = false
    var filtered:[String] = []
    
    @IBOutlet weak var stepOneTableView: UITableView!
    
//    func initializeIndexArray(){
//        indexList = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
//    }
//
    
    ///////////////////////////////////////////////////////////////////
    //MARK: CITY INDEX LIST DATA STRUCTURES AND OPS
    
    // used for city index list
    func initializeCityUniqueFirstCharacterArray() {
        for item in cityNamesList {
            let charString = "\(item[item.startIndex])" as String
            cityFilterUniqueFirstCharacterArray.append(charString)
        }
        cityFilterUniqueFirstCharacterArray = Array(Set(cityFilterUniqueFirstCharacterArray).sorted())
        
//        print("cityFilterUniqueFirstCharacterArray: ", cityFilterUniqueFirstCharacterArray)
    }
    
    func initializeCityFilterTitleArray() {
        
//        print("STEPONEVC: initializeCityFilterTitleArray: cityFilterDictionary", cityFilterDictionary)
        
        cityFilterTitleArray = cityFilterDictionary.keys.sorted()
        
//        print("STEPONEVC: initializeCityFilterTitleArray: cityFilterTitleArray", cityFilterTitleArray)
    }
    
    func initializeCityFilterDictionary() {
        cityFilterDictionary = [
            "A": [],
            "B": [],
            "C": [],
            "D": [],
            "E": [],
            "F": [],
            "G": [],
            "H": [],
            "I": [],
            "J": [],
            "K": [],
            "L": [],
            "M": [],
            "N": [],
            "O": [],
            "P": [],
            "Q": [],
            "R": [],
            "S": [],
            "T": [],
            "U": [],
            "V": [],
            "W": [],
            "X": [],
            "Y": [],
            "Z": []
        ]
    }
    
    // don't expect the number of states to change
    func initializeCityIndexToSectionMapping() {
//        cityIndexToSectionDictionary = ["A": 8, "B": 18, "C": 9, "D": 2, "E": 14, "F": 20, "G": 13, "H": 0, "I": 4, "J": 3, "K": 19, "L": 17, "M": 5, "N": 10, "O": 21, "P": 24, "Q": 25, "R": 12, "S": 7, "T": 23, "U": 16, "V": 15, "W":2, "X": 1, "Y": 11, "Z": 6]
        
        cityIndexToSectionDictionary = ["A": 0, "B": 1, "C": 2, "D": 3, "E": 4, "F": 5, "G": 6, "H": 7, "I": 8, "J": 9, "K": 10, "L": 11, "M": 12, "N": 13, "O": 14, "P": 15, "Q": 16, "R": 17, "S": 18, "T": 19, "U": 20, "V": 21, "W": 22, "X": 23, "Y": 24, "Z": 25]
    }

    
    ///////////////////////////////////////////////////////////////////
    //MARK: REGION INDEX LIST DATA STRUCTURES AND OPS
    func initializeRegionFilterTitleArray() {
        regionFilterTitleArray =  [
            "OASAM Region 4 - Atlanta",
            "OASAM Region 1 - Boston",
            "OASAM Region 5 - Chicago",
            "OASAM Region 6 - Dallas",
            "OASAM Region 8 - Denver",
            "OASAM Region 7 - Kansas City",
            "National Capital Region",
            "OASAM Region 2 - New York",
            "OASAM Region 3 - Philadelphia",
            "OASAM Region 9 - San Francisco",
            "OASAM Region 10 - Seattle"
        ]
    }
    
    func initializeRegionFilterDictionary() {
        regionFilterDictionary = [
            "OASAM Region 4 - Atlanta": [],
            "OASAM Region 1 - Boston": [],
            "OASAM Region 5 - Chicago": [],
            "OASAM Region 6 - Dallas": [],
            "OASAM Region 8 - Denver": [],
            "OASAM Region 7 - Kansas City": [],
            "National Capital Region": [],
            "OASAM Region 2 - New York": [],
            "OASAM Region 3 - Philadelphia": [],
            "OASAM Region 9 - San Francisco": [],
            "OASAM Region 10 - Seattle": []
        ]
    }
    
    // don't expect the number of states to change
    func initializeRegionIndexToSectionMapping() {
        regionIndexToSectionDictionary = ["A": 0, "B": 1, "C": 2, "D": 3, "K": 5, "N": 6, "P": 8, "S": 9]
    }
    
    func initializeRegionUniqueFirstCharacterArray() {
        regionFilterUniqueFirstCharacterArray = ["A", "B", "C", "D", "K", "N", "P", "S"]
    }

    
    ///////////////////////////////////////////////////////////////////
    //MARK: STATE INDEX LIST DATA STRUCTURES AND OPS
    func initializeStateUniqueFirstCharacterArray() {
        for item in stateFilterTitleArray {
            let charString = "\(item[item.startIndex])" as String
            stateFilterUniqueFirstCharacterArray.append(charString)
        }
        stateFilterUniqueFirstCharacterArray = Array(Set(stateFilterUniqueFirstCharacterArray).sorted())
    }
    
    func initializeStateFilterTitleArray() {
        stateFilterTitleArray = stateFilterDictionary.keys.sorted()
    }
    
    func initializeStateFilterDictionary() {
        stateFilterDictionary = [
            "Alabama": [],
            "Alaska": [],
            "Arizona": [],
            "Arkansas": [],
            "California": [],
            "Colorado": [],
            "Connecticut": [],
            "Delaware": [],
            "District of Columbia": [],
            "Florida": [],
            "Georgia": [],
            "Guam": [],
            "Hawaii": [],
            "Idaho": [],
            "Illinois": [],
            "Indiana": [],
            "Iowa": [],
            "Kansas": [],
            "Kentucky": [],
            "Louisiana": [],
            "Maine": [],
            "Maryland": [],
            "Massachusetts": [],
            "Michigan": [],
            "Minnesota": [],
            "Mississippi": [],
            "Missouri": [],
            "Montana": [],
            "Nebraska": [],
            "Nevada": [],
            "New Hampshire": [],
            "New Jersey": [],
            "New Mexico": [],
            "New York": [],
            "North Carolina": [],
            "North Dakota": [],
            "Ohio": [],
            "Oklahoma": [],
            "Oregon": [],
            "Pennsylvania": [],
            "Puerto Rico": [],
            "Rhode Island": [],
            "Saipan": [],
            "South Carolina": [],
            "South Dakota": [],
            "Tennessee": [],
            "Texas": [],
            "Utah": [],
            "Vermont": [],
            "Virginia": [],
            "Washington": [],
            "West Virginia": [],
            "Wisconsin": [],
            "Wyoming": []
        ]
    }

    func initialStateCodeToStateDictionary() {
        stateCodeToStateDictionary = [
                "AL": "Alabama",
                "AK": "Alaska",
                "AZ": "Arizona",
                "AR": "Arkansas",
                "CA": "California",
                "CO": "Colorado",
                "CT": "Connecticut",
                "DE": "Delaware",
                "DC": "District of Columbia",
                "FL": "Florida",
                "GA": "Georgia",
                "GU": "Guam",
                "HI": "Hawaii",
                "ID": "Idaho",
                "IL": "Illinois",
                "IN": "Indiana",
                "IA": "Iowa",
                "KS": "Kansas",
                "KY": "Kentucky",
                "LA": "Louisiana",
                "ME": "Maine",
                "MD": "Maryland",
                "MA": "Massachusetts",
                "MI": "Michigan",
                "MN": "Minnesota",
                "MP": "Saipan",
                "MS": "Mississippi",
                "MO": "Missouri",
                "MT": "Montana",
                "NE": "Nebraska",
                "NV": "Nevada",
                "NH": "New Hampshire",
                "NJ": "New Jersey",
                "NM": "New Mexico",
                "NY": "New York",
                "NC": "North Carolina",
                "ND": "North Dakota",
                "OH": "Ohio",
                "OK": "Oklahoma",
                "OR": "Oregon",
                "PA": "Pennsylvania",
                "PR": "Puerto Rico",
                "RI": "Rhode Island",
                "SC": "South Carolina",
                "SD": "South Dakota",
                "TN": "Tennessee",
                "TX": "Texas",
                "UT": "Utah",
                "VA": "Virginia",
                "VT": "Vermont",
                "WA": "Washington",
                "WV": "West Virginia",
                "WI": "Wisconsin",
                "WY": "Wyoming"
        ]
    }
    
    // don't expect the number of states to change
    func initializeStateIndexToSectionMapping() {
        stateIndexToSectionDictionary = ["A": 0, "C": 4, "D": 7, "F": 9, "G": 10, "H": 12, "I": 13, "K": 17, "L": 19, "M": 20, "N": 28, "O": 36, "P": 39, "R": 40, "S": 41, "T": 43, "U": 45, "V": 46, "W":48]
    }
    

    // to be called AFTER THE ENTIRE CITY LIST IS READ
    func initializeCityDataStructures() {
        initializeCityFilterDictionary()
        initializeCityFilterTitleArray()
        initializeCityUniqueFirstCharacterArray()
        initializeCityIndexToSectionMapping()
       
    }
    
    func initializeThemThangs() {
        
        initializeStateFilterDictionary()
        initializeStateFilterTitleArray()
        initializeStateUniqueFirstCharacterArray()
        initializeStateIndexToSectionMapping()
        
        initializeRegionFilterDictionary()
        initializeRegionFilterTitleArray()
        initializeRegionIndexToSectionMapping()
        initializeRegionUniqueFirstCharacterArray()
        
        initialStateCodeToStateDictionary()
        
//        initializeIndexArray()
    }
    
    
    ///////////////////////////////////////////////////////////////////
    //MARK: API ENDPOINT OPS    
    func readCityListFromMtws() {
        showLoadingHUD()

        
        initializeCityFilterDictionary()
        initializeCityFilterTitleArray()

        initializeThemThangs()
        initializeCityDataStructures()
        
        var cArray = [String]()
        var dArray = [String]()
        var rArray = [String]()
        
        let myUrl =  LibraryAPI.sharedInstance.getDolStagingListOfCitiesBase() as String
        
        Alamofire.SessionManager.default.session.configuration.timeoutIntervalForRequest = 10
        
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
 
                            let cityNameStateRegion = cityState + "|" + stateName + "|" + regionName
                            
                            self.cityNamesRegionList.append(cityNameStateRegion)
                            

                            // state index list data structure and ops
                            cArray.removeAll()
                            // process cityFilterDictionary
                            let charString = "\(cityState[cityState.startIndex])" as String

                            if (self.cityFilterDictionary[charString] == nil) {
                                cArray.append(cityState)
                                self.cityFilterDictionary[charString] = cArray.sorted()
                            }
                            else {
                                cArray = self.cityFilterDictionary[charString]!
                                cArray.append(cityState)
                                self.cityFilterDictionary[charString] = cArray.sorted()
                            }
                            
                            
                            // state index list data structure and ops
                            dArray.removeAll()
                            // process stateFilterDictionary
                            if (self.stateFilterDictionary[stateName] == nil) {
                                dArray.append(cityState)
                                self.stateFilterDictionary[stateName] = dArray.sorted()
                            }
                            else {
                                dArray = self.stateFilterDictionary[stateName]!
                                dArray.append(cityState)
                                self.stateFilterDictionary[stateName] = dArray.sorted()
                            }
                            
                            
                            rArray.removeAll()
                            // process regionFilterDictionary
                            if (self.regionFilterDictionary[regionName] == nil) {
                                rArray.append(cityState)
                                self.regionFilterDictionary[stateName] = rArray.sorted()
                            }
                            else {
                                rArray = self.regionFilterDictionary[regionName]!
                                rArray.append(cityState)
                                self.regionFilterDictionary[regionName] = rArray.sorted()
                            }
                        }   // end if let dictionary = item as? [String: Any]
                    }   // end for
                    
                    
                    /******* FOR THE ALPHABETICAL SORT SCOPE *******/
                    /******* SORT THE cityNamesList alphabetically, ascending *******/
                    self.cityNamesList.sort()
                
                    self.initializeCityUniqueFirstCharacterArray()
                    self.initializeCityIndexToSectionMapping()
                    
                    LibraryAPI.sharedInstance.setMasterCityNameHashWith(cityNameHash: self.cityNamesHash)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: readCityListFromMtwsSuccessNSKey), object: self)
                
                
                case .failure(_):
                    self.hideLoadingHUD()
                    self.doneButton.isEnabled = false
                
                    let alert = UIAlertController(title: "Cannot get city list.", message: "No internet connection available.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: readCityListFromMtwsFailureNSKey), object: self)
                }   // end switch
            
                self.hideLoadingHUD()
            
            }   // end status code = 200
            else {
                self.hideLoadingHUD()
                self.doneButton.isEnabled = false
                
                let alert = UIAlertController(title: "Cannot get city list.", message: "No internet connection available.", preferredStyle: UIAlertControllerStyle.alert)
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
//        self.stepOneTableView.delegate = self
//        self.stepOneTableView.dataSource = self
        
        self.stepOneTableView.allowsSelectionDuringEditing = true
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
    
    
    ///////////////////////////////////////////////////////////////////////////////////
    //MARK: VIEW CYCLE MANAGEMENT
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
        
        self.stepOneTableView.allowsMultipleSelectionDuringEditing = true
        self.stepOneTableView.setEditing(true, animated: false)
        self.stepOneTableView.sectionIndexColor = UIColor.black
        
        self.doneButton.accessibilityLabel = "Done selecting cities"
    }

    func prepStepOneSearchBar() {
        stepOneSearchBar.layer.cornerRadius = 20
        stepOneSearchBar.layer.borderWidth = 1
        
        let fancySwiftColor = UIColor(red: 0xE0, green: 0xE0, blue: 0xE0)
        stepOneSearchBar.layer.borderColor = fancySwiftColor.cgColor
        
        setSearchBarToWhite()
        
        var textFieldInsideSearchBar = stepOneSearchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.black
        
        let imageV = textFieldInsideSearchBar?.leftView as! UIImageView
        imageV.image = imageV.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
//        let fancyMagnifierSwiftColor = UIColor(red: 0xFD, green: 0x57, blue: 0x39)
        let fancyMagnifierSwiftColor = UIColor(red: 0x0, green: 0x0, blue: 0x0)
        imageV.tintColor = fancyMagnifierSwiftColor
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.doneButton.isEnabled = false
        self.doneButton.tintColor = UIColor.black   // UIColor(red: 0xFD, green: 0x57, blue: 0x39)
        
        self.cityNamesStateList.removeAll()
        self.cityNamesList.removeAll()
        self.cityNamesHash.removeAll()
        self.citySubscriptionSet.removeAll()
        self.cityNamesRegionList.removeAll()
        
        self.stateFilterDictionary.removeAll()
        self.regionFilterDictionary.removeAll()
        
        self.citySubscriptionSet = LibraryAPI.sharedInstance.getSubscriptionCitySet()
                
        // need to use notifications cuz Alamofire is an async process...
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleReadCityListFromMtwsSuccess), name: NSNotification.Name(rawValue: readCityListFromMtwsSuccessNSKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleReadCityListFromMtwsFailure), name: NSNotification.Name(rawValue: readCityListFromMtwsFailureNSKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleCreateSubscriptionListSuccess), name: NSNotification.Name(rawValue: createSubscriptionListSuccessNSKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleCreateSubscriptinListFailure), name: NSNotification.Name(rawValue: createSubscriptionListFailureNSKey), object: nil)

        scopeIndex = listByCITIES
        readCityListFromMtws()
        prepStepOneSearchBar()
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        self.stepOneTableView!.reloadData()
    }   // viewWillAppear


    override func viewDidAppear(_ animated: Bool) {        
        
        let runState = LibraryAPI.sharedInstance.getRunStatus() as String
        if (self.citySubscriptionSet.count == 0) {
            if (runState == NORMALRUNSTATE) {
            
                let alertController = UIAlertController(title: "No City Selected", message: "Would you like to select a city to view its status?  If no city is selected, you will not be able to view the status of any cities.", preferredStyle: UIAlertControllerStyle.alert)
                let cancelAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
                }
                
                let okAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                    self.noop()
                }
                
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
            else {      // INITIALSETTINGRUNSTATE
                LibraryAPI.sharedInstance.setRunStatus(myRunState: NORMALRUNSTATE)
            }
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



///////////////////////////////////////////////////////////////////////////////////
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sectionCount = 1
        
        if (searching == false) {
            switch (scopeIndex) {
            case BYCITY:
                sectionCount = cityFilterTitleArray.count
            case BYSTATE:
                sectionCount = stateFilterTitleArray.count
            default:            // BYREGION
                sectionCount = regionFilterTitleArray.count
            }
        }
        return sectionCount
    }
    
    func tableView(_ stepOneTableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle = ""
        
        if (searching == false) {
            switch (scopeIndex) {
            case BYCITY:
                let mySectionTitle = self.cityFilterTitleArray[section]
                let sectionArray = self.cityFilterDictionary[mySectionTitle]
                let numberOfRowsInSectionCount = (sectionArray?.count)!
                if (numberOfRowsInSectionCount > 0) {
                    sectionTitle = cityFilterTitleArray[section]
                }
            case BYSTATE:
                let mySectionTitle = self.stateFilterTitleArray[section]
                let sectionArray = self.stateFilterDictionary[mySectionTitle]
                let numberOfRowsInSectionCount = (sectionArray?.count)!
                if (numberOfRowsInSectionCount > 0) {
                    sectionTitle = stateFilterTitleArray[section]
                }
            default:            // BYREGION
                let mySectionTitle = self.regionFilterTitleArray[section]
                let sectionArray = self.regionFilterDictionary[mySectionTitle]
                let numberOfRowsInSectionCount = (sectionArray?.count)!
                if (numberOfRowsInSectionCount > 0) {
                    sectionTitle = regionFilterTitleArray[section]
                }
            }
        }
        
        return sectionTitle   // stateFilterTitleArray[section]
    }
   
    func tableView(_ stepOneTableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRowsInSectionCount = 0
        
        switch (scopeIndex) {
        case BYCITY:
            if (searching == true) {
                numberOfRowsInSectionCount = self.citiesSubscriptionSearchResultsList.count
            }
            else {
                let sectionTitle = self.cityFilterTitleArray[section]
                let sectionArray = self.cityFilterDictionary[sectionTitle]
                numberOfRowsInSectionCount = (sectionArray?.count)!
            }
            
        case BYSTATE:
            if (searching == true) {
                numberOfRowsInSectionCount = self.citiesSubscriptionSearchResultsList.count
            }
            else {
            let sectionTitle = self.stateFilterTitleArray[section]
            let sectionArray = self.stateFilterDictionary[sectionTitle]
            numberOfRowsInSectionCount = (sectionArray?.count)!
            }
            
        default:            // BYREGION
            if (searching == true) {
                numberOfRowsInSectionCount = self.citiesSubscriptionSearchResultsList.count
            }
            else {
            let sectionTitle = self.regionFilterTitleArray[section]
            let sectionArray = self.regionFilterDictionary[sectionTitle]
            numberOfRowsInSectionCount = (sectionArray?.count)!
            }
        }

        return numberOfRowsInSectionCount
    }
    
    func setCellAccessibilityLabel(cell: UITableViewCell, city: String) {
        let itemCFI = LibraryAPI.sharedInstance.parseCityState(cityState: city)
        let stateName = stateCodeToStateDictionary[itemCFI.stateCode] as! String
        let accessibilityLabel = itemCFI.cityName + " " + stateName
        cell.accessibilityLabel = accessibilityLabel
    }
    
    func tableView(_ stepOneTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.stepOneTableView.dequeueReusableCell(withIdentifier: "stepOneCell")!
        cell.textLabel?.textColor = UIColor.black
        
        var sectionTitle = String()
        var sectionArray = [String]()
        var city = String()
        
        switch (scopeIndex) {      // list by cities
        case BYCITY:
            if (searching == false) {
                sectionTitle = cityFilterTitleArray[indexPath.section]
                sectionArray = cityFilterDictionary[sectionTitle]!
                city = sectionArray[indexPath.row]
                
                cell.textLabel?.text = city
                setCellAccessibilityLabel(cell: cell, city: city)
            }
            else {      // in search mode
                cell.textLabel?.text = citiesSubscriptionSearchResultsList[indexPath.row]
                setCellAccessibilityLabel(cell: cell, city: citiesSubscriptionSearchResultsList[indexPath.row])
            }
            
        case BYSTATE:
            if (searching == false) {
                sectionTitle = stateFilterTitleArray[indexPath.section]
                sectionArray = stateFilterDictionary[sectionTitle]!
                city = sectionArray[indexPath.row]
            
                cell.textLabel?.text = city
                setCellAccessibilityLabel(cell: cell, city: city)
            }
            else {      // in search mode
                cell.textLabel?.text = citiesSubscriptionSearchResultsList[indexPath.row]
                setCellAccessibilityLabel(cell: cell, city: citiesSubscriptionSearchResultsList[indexPath.row])
            }

        default:        // by region
            if (searching == false) {
                sectionTitle = regionFilterTitleArray[indexPath.section]
                sectionArray = regionFilterDictionary[sectionTitle]!
                city = sectionArray[indexPath.row]
            
                cell.textLabel?.text = city
                setCellAccessibilityLabel(cell: cell, city: city)
            }
            else {      // in search mode
                cell.textLabel?.text = citiesSubscriptionSearchResultsList[indexPath.row]
                setCellAccessibilityLabel(cell: cell, city: citiesSubscriptionSearchResultsList[indexPath.row])
            }
        }   // end switch
        
        if (citySubscriptionSet.contains(city)) {
            cell.accessoryType = .checkmark
            self.stepOneTableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.bottom)
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }   // end cellForRowAt

        
    // return title list for section index
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        if (searching == false) {
            switch scopeIndex {
            case BYCITY:
                return self.cityFilterUniqueFirstCharacterArray
            case BYSTATE:
                return self.stateFilterUniqueFirstCharacterArray
            default:
                return nil  // self.regionFilterUniqueFirstCharacterArray
            }
        }
        return nil
    }
    
    
    // return section for given section index title
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        var sectionIndex = 0
        
        if (searching == false) {
            switch scopeIndex {
            case BYCITY:
                sectionIndex = cityIndexToSectionDictionary[title]!
            case BYSTATE:
                sectionIndex = stateIndexToSectionDictionary[title]!
            default:
                sectionIndex = regionIndexToSectionDictionary[title]!
            }   // end switch
        }
        return sectionIndex
        
    }
    
    
    func noop() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "myCitiesNavVC") as UIViewController
        self.present(controller, animated: true, completion: nil)
    }
    
    func setSearchBarToWhite() {
        let textFieldArray = getSubviewsOfViewOfTypeTextField(view: stepOneSearchBar) as [UITextField]
        let textField = textFieldArray[0] 
        textField.background = UIImage.init(named: "searchBarWhite.png")
        textField.textColor = UIColor.red
    }
    
    func getSubviewsOfView(view: UIView) -> [UIView] {
        var subviewArray = [UIView]()
        if view.subviews.count == 0 {
            return subviewArray
        }
        for subview in view.subviews {
            subviewArray += self.getSubviewsOfView(view: subview)
            subviewArray.append(subview)
        }
        return subviewArray
    }
    
    func getSubviewsOfViewOfTypeTextField(view: UIView) -> [UITextField] {
        var subviewArray = [UITextField]()
        for subview in view.subviews {
            subviewArray += self.getSubviewsOfViewOfTypeTextField(view: subview)
            if let subview = subview as? UITextField {
                subviewArray.append(subview)
            }
        }
        return subviewArray
    }
}   // end class



extension StepOne: UITableViewDelegate {

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var sectionTitle = ""
        var sectionArray = [String]()
        var city = ""
        
        if (searching == false) {
            switch scopeIndex {
            case BYCITY:
                sectionTitle = cityFilterTitleArray[indexPath.section]
                sectionArray = cityFilterDictionary[sectionTitle]!
                city = sectionArray[indexPath.row]
                
            case BYSTATE:
                sectionTitle = stateFilterTitleArray[indexPath.section]
                sectionArray = stateFilterDictionary[sectionTitle]!
                city = sectionArray[indexPath.row]
                
            default:
                sectionTitle = regionFilterTitleArray[indexPath.section]
                sectionArray = regionFilterDictionary[sectionTitle]!
                city = sectionArray[indexPath.row]
            }
            
        }
        else {
            city = citiesSubscriptionSearchResultsList[indexPath.row]
        }
        
        if (citySubscriptionSet.contains(city) == true) {
            citySubscriptionSet.remove(city)         // means was selected and now de-selected
        }
        else {
            citySubscriptionSet.insert(city)           // means was NOT selected and now IS SELECTED
        }
        
    }

    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        var sectionTitle = ""
        var sectionArray = [String]()
        var city = ""
        
        if (searching == false) {
            switch scopeIndex {
            case BYCITY:
                sectionTitle = cityFilterTitleArray[indexPath.section]
                sectionArray = cityFilterDictionary[sectionTitle]!
                city = sectionArray[indexPath.row]
                
            case BYSTATE:
                sectionTitle = stateFilterTitleArray[indexPath.section]
                sectionArray = stateFilterDictionary[sectionTitle]!
                city = sectionArray[indexPath.row]
                
            default:
                sectionTitle = regionFilterTitleArray[indexPath.section]
                sectionArray = regionFilterDictionary[sectionTitle]!
                city = sectionArray[indexPath.row]
            }
            
        }
        else {
            city = citiesSubscriptionSearchResultsList[indexPath.row]
        }
        
        if (citySubscriptionSet.contains(city) == true) {
            citySubscriptionSet.remove(city)         // means was selected and now de-selected
        }
        else {
            citySubscriptionSet.insert(city)           // means was NOT selected and now IS SELECTED
        }
    }
}


///////////////////////////////////////////////////////////////////////////////////
//MARK: UISEARCHBAR OPS
extension StepOne: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText == "") {
            searching = false
        }
        else {
            searching = true
            
            self.citiesSubscriptionSearchResultsList.removeAll()
            self.statesSubscriptionSearchResultsList.removeAll()
            
            for index in 0 ..< self.cityNamesRegionList.count {
                
                let formattedString = self.cityNamesRegionList[index] as String
                let formattedArray = formattedString.components(separatedBy: "|")
                
                let cityState = formattedArray[0]
                let stateName = formattedArray[1]
                let region = formattedArray[2]
                
                var currentString = String()
                
                switch (scopeIndex) {       // list by cities
                case BYCITY:
                    currentString = cityState  // city SG
                    let cityStateArray = formattedString.components(separatedBy: " ")
                    let cityName = cityStateArray[0]
                    if cityName.lowercased().range(of: searchText.lowercased())  != nil {
                        self.citiesSubscriptionSearchResultsList.append(cityState)
                    }
                    
                case BYSTATE:
                    currentString = cityState  // city SG
                    let itemCFI = LibraryAPI.sharedInstance.parseCityState(cityState: cityState)
                    currentString = stateName
                    if ( (currentString.lowercased().range(of: searchText.lowercased())  != nil) ||
                         (itemCFI.stateCode.lowercased().range(of: searchText.lowercased())  != nil) ) {
                        self.citiesSubscriptionSearchResultsList.append(cityState)
                    }
                    
                default:
                     currentString = region
                     if currentString.lowercased().range(of: searchText.lowercased())  != nil {
                        self.citiesSubscriptionSearchResultsList.append(cityState)
                    }
                }   // end switch

                self.citiesSubscriptionSearchResultsList.sort()
            }   // end for
        }
        self.stepOneTableView!.reloadData()
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        stepOneSearchBar.showsScopeBar = true
        stepOneSearchBar.sizeToFit()        
        return true
    }
 
    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        stepOneSearchBar.showsScopeBar = false
        stepOneSearchBar.sizeToFit()
//        stepOneSearchBar.setShowsCancelButton(false, animated: true)
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
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        stepOneSearchBar.text = ""
    }
    
}   // end extension




