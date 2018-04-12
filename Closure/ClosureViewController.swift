//
//  ClosureViewController.swift
//
//  Created by George Liu on 9/12/17.
//  Copyright © 2017 OASAM All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD

let applicationDidBecomeActiveNSKey = "gov.dol.oasam.applicationDidBecomeActive"

let loadCityStatusesFromMtwsSuccessNSKey = "gov.dol.oasam.loadCityStatusesFromMtwsSuccess"
let loadCityStatusesFromMtwsFailureNSKey = "gov.dol.oasam.loadCityStatusesFromMtwsFailure"


class ClosureViewController: UIViewController {
    
    @IBOutlet weak var closureTableView: UITableView!

    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    @IBOutlet weak var closureSearchBar: UISearchBar!
    
    @IBOutlet weak var addCityButton: UIBarButtonItem!
    
    @IBOutlet weak var statusImageView: UIImageView!

    //MARK: - data management
    //MARK: Properties
    var cityListJsonArray: [Any] = []       // short list city stuff
    var cityStateCodeList: [String] = []
    
    var cityStatuses = [CityStatus]()
    var cityStatusesShortList = [CityStatus]()
    
    let openPhoto = UIImage(named: "open36")
    let closedPhoto = UIImage(named: "closed36")
    
    var deviceTokens: [String] = []
    var citySubscriptionSet = Set<String>()     // TODO: Put this into a SINGLETON cuz other classes will need it.
    let NOCITYSUBSCRIPTIONS = 0
    var refreshControl: UIRefreshControl!
    
    @IBAction func addCityButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "selectCitiesNavVC") as UIViewController
        self.present(controller, animated: true, completion: nil)       
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        LibraryAPI.sharedInstance.setOriginatingNavVC(originatingNavVC: "myCitiesNavVC")
    }
    
    
    private func loadCityStatusesFromMtws() {
        if (LibraryAPI.sharedInstance.isInternetAvailable() == true) {
            self.loadCityStatusesFromMtwsX()
        }
        else {
            refreshControl.endRefreshing()
            
            HelperLibrary.delay( 1, completion: {
                let alert = UIAlertController(title: "Cannot get city status.", message: "No internet connection available.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            })
        }
    }
    

    private func loadCityStatusesFromMtwsX() {
        // pulls city statuses from Nick's server
        var myUrl =  LibraryAPI.sharedInstance.getDolStagingGetCityStatusesBase() as String
        var cityNamesHash = [String: String]()          // hash of cityname and cityid for all cities
        var cityNamesIdHash = [String: String]()        // hash of cityname and cityid for preselected citiex
        var workingHash = [String: String]()
        
        var cityStatusDictionary = [String: CityStatus]()
        
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
        cityStatuses.removeAll()
        
        self.citySubscriptionSet.removeAll()
        
        // to get to this point citySubscriptionSet has values.
        citySubscriptionSet = LibraryAPI.sharedInstance.getSubscriptionCitySet()
        
        // the only way you can get to this point is to have a subscription list
        workingHash = LibraryAPI.sharedInstance.getMasterCityNameIdHash()
        
        ////////////  FORMAT URL - GET DEVICE TOKEN AND CITY IDs FROM LibraryAPI //////////
        self.cityStatuses.removeAll()
        self.closureTableView.reloadData()
        
        for item in citySubscriptionSet {
            let cityID = workingHash[item]
            cityIDs.append(cityID!)
            let itemCFI = LibraryAPI.sharedInstance.parseCityState(cityState: item)
            
            
//            let formatter = DateFormatter()
//            // initially set the format based on your datepicker date
//            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//
//            let myString = formatter.string(from: Date())
//            // convert your string to date
//            let yourDate = formatter.date(from: myString)
//            //then again set the date format whhich type of output you need
//            formatter.dateFormat = ">  MMMM d, HH:mm:ss"
//            // again convert your date to string
//            let myStringafd = formatter.string(from: yourDate!)
            
            let cs3 = CityStatus(region: "", state: itemCFI.stateCode, cityName: itemCFI.cityName, cityStatus: "Open", cityNotes: "Open", updatedOn: "" )
            
            cityStatusDictionary[item] = cs3

        }   // end for item in citySubscriptionSet
        
        let formattedArray = (cityIDs.map{String($0)}).joined(separator: ",")
        let subscriptionParam = deviceToken + "/" + formattedArray
        myUrl += subscriptionParam
        
        //////////////////////////////////////////////////////////////////////////////////////        
        self.cityStatuses.removeAll()
        
//            self.showLoadingHUD()
        
            Alamofire.SessionManager.default.session.configuration.timeoutIntervalForRequest = 10
        
//            Alamofire.request(myUrl, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON { response in
        
        Alamofire.SessionManager.default.requestWithoutCache(myUrl, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON { response in
                let statusCode = response.response?.statusCode
                
                if (statusCode == 200) {
                
                    switch response.result {
                    
                    case .success:
                    
                        self.hideLoadingHUD()
                    
                        if let jsonArray = try? JSONSerialization.jsonObject(with: response.data!, options: []) as? NSArray {
                            
                            for updateDictionary in jsonArray! {
                                
                                let ud = updateDictionary as! NSDictionary
                                
                                let dictionary = ud["update"] as? [String:String]
                                
                                let state = (dictionary as AnyObject).value(forKey: "state") as? String
                            
                                let region = (dictionary as AnyObject).value(forKey: "region") as? String
                            
                                let city = (dictionary as AnyObject).value(forKey: "city") as? String
                            
                                let status = (dictionary as AnyObject).value(forKey: "status") as? String
                        
                                let note = (dictionary as AnyObject).value(forKey: "notes") as? String
                                
                                let updatedOn = (dictionary as AnyObject).value(forKey: "updated_on") as? String
                                                                    
                                self.hideLoadingHUD()
                                if ( city != nil ) {
                                    cityStatusNamesSet.insert(city! + " " + state!)
                                    let cityStateCode = city! + " " + state!
                                    let cs3 = CityStatus(region: region!, state: state!, cityName: city!, cityStatus: status!, cityNotes: note!, updatedOn: updatedOn ?? "" )
                                    
                                    cityStatusDictionary[cityStateCode] = cs3
                                }
                            }   // end for
                    
                            self.cityStatuses.removeAll()
                            for item in cityStatusDictionary {
                                self.cityStatuses.append(item.value)
                            }
                            
                        }   // end if NSDictionary
                    
                        // 2. prep for data table load
                        self.closureTableView.delegate = self
                        self.closureTableView.dataSource = self
                        self.closureTableView.backgroundView = nil
                        NotificationCenter.default.post(name: Notification.Name(rawValue: loadCityStatusesFromMtwsSuccessNSKey), object: self)

                    case .failure(_):
                        self.hideLoadingHUD()
                        /*
                            ** NEED TO NOTIFY USER
                            */
                        NotificationCenter.default.post(name: Notification.Name(rawValue: loadCityStatusesFromMtwsFailureNSKey), object: self)

                    }   // end switch
                
                }   // end status == 200
                else {
                    self.hideLoadingHUD()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: loadCityStatusesFromMtwsFailureNSKey), object: self)
                }
                
            }   // end Alamorefire

    }   // end func loadCityStatusesFromMtws()
    
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func refreshFromPullDown() {
        self.loadCityStatusesFromMtws()
        refreshControl.endRefreshing()
    }
    
    
    func refreshFromApplicationBecomingActive() {
        self.showLoadingHUD()
        self.loadCityStatusesFromMtws()
    }
    
    
    func handleLoadCityStatusFromMtwsSuccess() {
        self.closureTableView.reloadData()
    }
    
    func handleLoadCityStatusFromMtwsFailure() {
        let alert = UIAlertController(title: "Cannot get city status.", message: "No internet connection available.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    ///////////////////////////////////////////////////////////////////////////////
    //MARK: - view cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
    
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleLoadCityStatusFromMtwsSuccess), name: NSNotification.Name(rawValue: loadCityStatusesFromMtwsSuccessNSKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleLoadCityStatusFromMtwsFailure), name: NSNotification.Name(rawValue: loadCityStatusesFromMtwsFailureNSKey), object: nil)
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshFromPullDown), for: UIControlEvents.valueChanged)
        self.closureTableView.addSubview(refreshControl) // not required when using UITableViewController
        
        self.addCityButton.accessibilityLabel = "Navigate to select cities"
    }      // end viewdidload
    
    override func viewDidAppear(_ animated: Bool) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.hideLoadingHUD))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        self.addCityButton.tintColor = UIColor.black    // (rgb: DOLORANGECOLOR)

        // at this point the view is created and added to the hierarchy
        if (LibraryAPI.sharedInstance.getSubscriptionCityCount() != self.NOCITYSUBSCRIPTIONS) {
            // means subsequent run (and you have saved cities)
            self.refreshFromApplicationBecomingActive()
            NotificationCenter.default.addObserver(self, selector: #selector(self.refreshFromApplicationBecomingActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
       }
        else {
            let runState = LibraryAPI.sharedInstance.getRunStatus()
            if (runState == INITIALSETTINGRUNSTATE) {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "selectCitiesNavVC") as UIViewController
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //MARK : Progress loading HUD Ops ----------------------
    private func showLoadingHUD() {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Loading..."
    }
    
    @objc private func hideLoadingHUD() {
        MBProgressHUD.hide(for: self.view, animated: true)
    }
}   // end class


///////////////////////////////////////////////////////////////////////////////
//MARK: - Datasource and delegate methods

extension ClosureViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func tableView(_ closureTableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        rows = cityStatuses.count
        return rows
    }
    
    
    func tableView(_ closureTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = closureTableView.dequeueReusableCell(withIdentifier: "closureCell")!
        
        let cityStatusCell = cityStatuses[indexPath.row]

        (cell.contentView.viewWithTag(100) as! UILabel).textColor = UIColor(rgb: DOLBLACKCOLOR)
        (cell.contentView.viewWithTag(100) as! UILabel).text = cityStatusCell.cityName + " " + cityStatusCell.state // as? String
        (cell.contentView.viewWithTag(110) as! UILabel).text = cityStatusCell.cityStatus // as? String

        (cell.contentView.viewWithTag(120) as! UIImageView).image = UIImage(named: "openGreen24.png")
        if cityStatusCell.cityStatus.lowercased().range(of:"closed") != nil {
            (cell.contentView.viewWithTag(120) as! UIImageView).image = UIImage(named: "closeRed17.png")
        }
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


extension Alamofire.SessionManager{
    @discardableResult
    open func requestWithoutCache(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)// also you can add URLRequest.CachePolicy here as parameter
        -> DataRequest
    {
        do {
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            urlRequest.cachePolicy = .reloadIgnoringCacheData // <<== Cache disabled
            let encodedURLRequest = try encoding.encode(urlRequest, with: parameters)
            return request(encodedURLRequest)
        } catch {
            // TODO: find a better way to handle error
            print(error)
            return request(URLRequest(url: URL(string: "http://example.com/wrong_request")!))
        }
    }
}






