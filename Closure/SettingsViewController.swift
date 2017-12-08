//
//  SettingsViewController.swift
//  Closure
//
//  Created by liu-george-p on 11/2/17.
//  Copyright © 2017 OASAM. All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD



class SettingsViewController: UIViewController {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var settingsSearchBar: UISearchBar!
    
    var cityStatuses = [CityStatus]()
    var cityStatusesShortList = [CityStatus]()

    var cityNamesList: [String] = []
    var cityNamesStateList: [String] = []
    var cityNamesRegionList: [String] = []
        
    var cityNamesHash = [String: String]()
    var isConnectedToServer = false
        
    var deviceTokens: [String] = []
    var citySubscriptionSet = Set<String>()     // TODO: Put this into a SINGLETON cuz other classes will need it.
        
    var isInitialLoad = false
        
    var cityListJsonArray: [Any] = []
        
    var citiesSubscriptionSearchResultsList: [String] = []
    var searching:Bool! = false
    var filtered:[String] = []
        
        //    @IBOutlet weak var stepOneCitySearchBar: UISearchBar!
        
    @IBOutlet weak var settingsTableView: UITableView!
        
    @IBAction func addCitiesButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "settingsAddCitiesSegue", sender: self)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    private func loadCityStatusesFromSubscriptionSet() {
        // pulls city statuses from Nick's server
        var myUrl =  LibraryAPI.sharedInstance.getDolStagingGetCityStatusesBase() as String
        var cityNamesHash = [String: String]()          // hash of cityname and cityid for all cities
        var cityNamesIdHash = [String: String]()        // hash of cityname and cityid for preselected citiex
        var workingHash = [String: String]()
        
        var cityIDs = [String]()
        var cityIntIDs = [Int]()
        let deviceToken = LibraryAPI.sharedInstance.getDeviceToken()
        
        var cityStatusNamesSet = Set<String>()
        
        ///////////////////////////////////////////////////////////////////////////////////
        
        // myUrl = "https://staging.dol.gov/api/v1/GetCityStatuses/d482c88c151da0a/1234,5678"
        
        cityNamesHash.removeAll()
        cityNamesIdHash.removeAll()
        cityIDs.removeAll()
        cityIntIDs.removeAll()
        cityStatusNamesSet.removeAll()
        
        self.citySubscriptionSet.removeAll()
        
        // to get to this point citySubscriptionSet has values.
        citySubscriptionSet = LibraryAPI.sharedInstance.getSubscriptionCitySet()
        
        // the only way you can get to this point is to have a subscription list
        workingHash = LibraryAPI.sharedInstance.getMasterCityNameIdHash()
        
        ////////////  FORMAT URL - GET DEVICE TOKEN AND CITY IDs FROM LibraryAPI //////////
        for item in citySubscriptionSet {
            let cityID = workingHash[item]
            cityIDs.append(cityID!)
        }
        
        let formattedArray = (cityIDs.map{String($0)}).joined(separator: ",")
        let subscriptionParam = deviceToken + "/" + formattedArray
        myUrl += subscriptionParam
        
        //////////////////////////////////////////////////////////////////////////////////////
        
        self.cityStatuses.removeAll()
        
        self.showLoadingHUD()
        
        Alamofire.SessionManager.default.session.configuration.timeoutIntervalForRequest = 15
        
        Alamofire.request(myUrl, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON { response in
            let statusCode = response.response?.statusCode
            
            if (statusCode == 200) {
                
                switch response.result {
                    
                case .success:
                    
                    self.hideLoadingHUD()
                    // let data: Data // received from a network request, for example
                    if let jsonArray = try? JSONSerialization.jsonObject(with: response.data!, options: []) as? NSArray {
                        
                        for updateDictionary in jsonArray! {
                            
                            let ud = updateDictionary as! NSDictionary
                            
                            let dictionary = ud["update"] as? [String:String]
                            
                            let state = (dictionary as AnyObject).value(forKey: "state") as? String
                            
                            let region = (dictionary as AnyObject).value(forKey: "region") as? String
                            
                            let city = (dictionary as AnyObject).value(forKey: "city") as? String
                            
                            let status = (dictionary as AnyObject).value(forKey: "status") as? String
                            
                            let note = (dictionary as AnyObject).value(forKey: "notes") as? String
                            
                            
                            if ( city == nil ) {
                                let alert = UIAlertController(title: "Alert", message: "City Statuses are unavailable at this time.", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                            else {
                                
                                cityStatusNamesSet.insert(city! + " " + state!)
                                
                                let cs3 = CityStatus(region: region!, state: state!, cityName: city!, cityStatus: status!, cityNotes: note! )
                                
                                self.cityStatuses.append(cs3)
                            }
                        }   // end for
                        
                    }   // end if NSDictionary
                    
                    // 2. prep for data table load
                    self.settingsTableView.delegate = self // as! UITableViewDelegate
                    self.settingsTableView.dataSource = self // as! UITableViewDataSource
                    self.settingsTableView.backgroundView = nil
                    self.settingsTableView.reloadData()
                    
                case .failure(let error):
                    self.hideLoadingHUD()
                    /*
                     ** NEED TO NOTIFY USER
                     */
                    print(error)
                    var message = "Cannot get City status. "
                    if (statusCode == nil) {
                        message = message + "Server unavailable."
                    }
                    else {
                        message = message + "Status code: \(String(describing: statusCode))"
                    }
                    
                    let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }   // end switch
                
                
                
            }   // end status == 200
            else {
                self.hideLoadingHUD()
                
                var message = "Cannot get City status. "
                if (statusCode == nil) {
                    message = message + "Server unavailable."
                }
                else {
                    message = message + "Status code: \(String(describing: statusCode))"
                }
                
                let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
        }   // end Alamorefire
        
    }   // end func loadCityStatusesFromSubscriptionSet()

    
    
        func dismissKeyboard() {
            //Causes the view (or one of its embedded text fields) to resign the first responder status.
            view.endEditing(true)
        }
        
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            if self.revealViewController() != nil {
                menuButton.target = self.revealViewController()
                menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
            
            //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
        }
        
        
        override func viewWillAppear(_ animated: Bool) {            
            self.settingsTableView.delegate = self // as! UITableViewDelegate
            self.settingsTableView.dataSource = self // as! UITableViewDataSource
            self.settingsTableView.backgroundView = nil
            self.settingsTableView!.reloadData()
            
            self.cityNamesStateList.removeAll()
            self.cityNamesList.removeAll()
            self.cityNamesHash.removeAll()
            self.citySubscriptionSet.removeAll()
            self.cityNamesRegionList.removeAll()
            
            self.citySubscriptionSet = LibraryAPI.sharedInstance.getSubscriptionCitySet()
            
        }   // viewWillAppear
        
        
        override func viewDidAppear(_ animated: Bool) {
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
            
            //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
            
            settingsSearchBar.delegate = self //as? UISearchBarDelegate
            settingsSearchBar.scopeButtonTitles = ["Cities A-Z", "State Codes A-Z", "Region"]

            
            
            if (self.citySubscriptionSet.count != 0) {
                self.loadCityStatusesFromSubscriptionSet()
                self.settingsTableView!.reloadData()
            }
    }
        
        
        override func viewWillDisappear(_ animated: Bool) {
            
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






//MARK: - Datasource and delegate methods

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func tableView(_ closureTableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        
        if (searching == false) {
            rows = cityStatuses.count
        }
        else {
            rows = cityStatusesShortList.underestimatedCount
        }
        return rows
    }
    
    
    func tableView(_ closureTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = closureTableView.dequeueReusableCell(withIdentifier: "settingsCell")!
        
        var cityStatusCell = cityStatuses[indexPath.row]
        if (searching == true) {
            cityStatusCell = cityStatusesShortList[indexPath.row]
        }
        
        cell.textLabel?.text = cityStatusCell.cityName + " " + cityStatusCell.state
        
        cell.textLabel?.textColor = UIColor.red

        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        LibraryAPI.sharedInstance.setSelectedCityStatus(mySelectedCityStatus: cityStatuses[indexPath.row])
        
        // transition over to MainTableViewApp
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "CityDetailNavigator") as UIViewController
        self.present(controller, animated: true, completion: nil)
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let cityStatusCell = cityStatuses[indexPath.row]
        citySubscriptionSet.remove(cityStatusCell.cityName+" "+cityStatusCell.state)
        LibraryAPI.sharedInstance.setSubscriptionCitySetWith(citySubscriptionSet: citySubscriptionSet)
        
        if editingStyle == .delete {
            cityStatuses.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
}   // end extension






extension SettingsViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText == "") {
            searching = false
        }
        else {
            searching = true
            
            self.cityStatusesShortList.removeAll()
            for index in 0 ..< self.cityStatuses.count {
                var currentString = String()
                
                switch scopeIndex {
                case listByCITIES:
                    currentString = self.cityStatuses[index].cityName as String
                    if currentString.lowercased().range(of: searchText.lowercased())  != nil {
                        self.cityStatusesShortList.append(self.cityStatuses[index])
                    }
                    
                case listBySTATES:
                    currentString = self.cityStatuses[index].state as String
                    if currentString.range(of: searchText.uppercased())  != nil {
                        self.cityStatusesShortList.append(self.cityStatuses[index])
                    }
                    
                case listByREGION:
                    currentString = self.cityStatuses[index].region as String
                    if currentString.lowercased().range(of: searchText.lowercased())  != nil {
                        self.cityStatusesShortList.append(self.cityStatuses[index])
                    }
                    
                default:
                    print("noop")
                }   // end switch
                
            }   // end for
        }
        self.settingsTableView!.reloadData()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        settingsSearchBar.showsScopeBar = true
        settingsSearchBar.sizeToFit()
        settingsSearchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    
    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        settingsSearchBar.showsScopeBar = false
        settingsSearchBar.sizeToFit()
        settingsSearchBar.setShowsCancelButton(false, animated: true)
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        scopeIndex = selectedScope
        settingsSearchBar.becomeFirstResponder()
        self.settingsTableView!.reloadData()
    }
    
    func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        self.view.endEditing(true)
        self.settingsSearchBar.endEditing(true)
        settingsSearchBar.resignFirstResponder()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.settingsSearchBar.endEditing(true)
        settingsSearchBar.resignFirstResponder()
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        settingsSearchBar.resignFirstResponder()
    }
    
}

extension SettingsViewController: UISearchDisplayDelegate {
    
}
