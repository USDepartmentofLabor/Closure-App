
//  LibraryAPI.swift
//
//  Created by George Liu on 6/9/17.
//  Copyright © 2017 OASAM All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration


let INITIALSETTINGRUNSTATE = "INITIALSETTINGRUNSTATE"
let NORMALRUNSTATE = "NORMALRUNSTATE"
let CLOSUREVCRUNSTATE = "CLOSUREVCRUNSTATE"


class LibraryAPI: NSObject {
    
    private let defaults = UserDefaults.standard
    
    private var subscriptionCityPersistencyManager = Set<String>()
    private var deviceToken = String()
    private var masterCityNamesHash = [String: String]()
    private var masterCityNamesIdHash = [String: String]()
    
    private var runState = String()   // either initial or subsequent run
    
    private var originatingNavVC = String()
    
    private var selectedCityStatus = CityStatus(region: "", state: "", cityName: "", cityStatus: "", cityNotes: "", updatedOn: "")
    
    let EMPTY_STRING = ""
        
    /* use this or similar ip addr when the phone is connected to the mac */
    private let baseDoLUrl = "http://10.49.37.100:3000/" as String
    
    /************* URLs FOR NICK'S SERVER
     
 CreateSubscriptionList:
     https://staging.dol.gov/api/v1/CreateSubscriptionList
     Parameters: device token, comma separated city IDs
     Example:    https://staging.dol.gov/api/v1/CreateSubscriptionList/old-asdfasdf/7767,77675
     
 GetSubscriptinList:
     https://staging.dol.gov/api/v1/GetSubscriptionList
     Parameters: deviceToken
     Example:    https://staging.dol.gov/api/v1/GetSubscriptionList/test-device
     
 GetListOfCities:
     https://staging.dol.gov/api/v1/GetListOfCities
     Parameters: none
     Example:    https://staging.dol.gov/api/v1/GetListOfCities
 
 GetCityStatuses:
     https://staging.dol.gov/api/v1/GetCityStatuses
     Parameters: device token
     Example:
 
 CreateDeviceToken:
     https://staging.dol.gov/api/v1/CreateDeviceToken
     Parameters: old device token, new device token (optional)
     Example:    https://staging.dol.gov/api/v1/CreateDeviceToken/old-asdfasdf/new-asdfasdf
     
     ************************************/
    

    
    private let dolStagingCreateSubscriptionListBase = "https://staging.dol.gov/api/v1/CreateSubscriptionList/"
    
    private let dolStagingGetListOfCitiesBase = "https://staging.dol.gov/api/v1/GetListOfCities/"
    
    private let dolStagingGetCityStatusesBase = "https://staging.dol.gov/api/v1/GetCityStatuses/"
    
    private let dolStagingCreateDeviceTokenBase = "https://staging.dol.gov/api/v1/CreateDeviceToken/"
    
    private let dolStagingGetSubscriptionListBase = "https://staging.dol.gov/api/v1/GetSubscriptionList/"
    
    
    
    private let dolCreateDeviceTokenOnMtws = "https://staging.dol.gov/api/v1/CreateDeviceToken/?token="
    
    private let dolCityListFromBAHUrl = "https://staging.dol.gov/api/v1/emc-status-update/GetListOfCities/35.json"
    
    private let doLSubscriptionListSuffix = "SubscriptionList/?token="  as String
    private let doLSubscriptionListNoTokenAvailable = "NoTokenAvailable"  as String
    
    private let dolCityListUrlSuffix = "CityList"
    private let dolCreateCitySubscriptionUrlSuffix = "CreateCitySubscription"
 
    private let doLSubscriptionCityStatusSuffix = "CityStatuses/?token="  as String

    private let doLSubscriptionCityStatusWithCityListSuffix = "CityStatuses/?cityIDs="  as String

    
    private let dolCreateDeviceTokenOnMTWSUrl = "CityStatuses/?jsonObject="  as String
    private let dolUpdateDeviceTokenOnMTWSUrl = "CityStatuses/?jsonObject="  as String
    
    
    class var sharedInstance: LibraryAPI {
        
        struct Singleton {
            static let instance = LibraryAPI()
        }
        return Singleton.instance
    }
    
    override init() {
        super.init()
        deviceToken = EMPTY_STRING
        runState = INITIALSETTINGRUNSTATE
    }
    
    
    // MARK: Run Status Ops
    func setRunStatus(myRunState: String) {
        runState = myRunState
    }
    
    func getRunStatus() -> String {
        return runState
    }
  
    
    
    // MARK: SubscriptionSet Ops ---------------------
    func setSubscriptionCitySetWith(citySubscriptionSet: Set<String>) {
        var cityNamesArray = [String]()
                
        if (citySubscriptionSet.count == 0) {
            subscriptionCityPersistencyManager.removeAll()
        }
        else {
            subscriptionCityPersistencyManager = citySubscriptionSet
            for item in subscriptionCityPersistencyManager {
                cityNamesArray.append(item)
            }
        }
        defaults.set(cityNamesArray, forKey: "subscriptionSetKey")
    }
    
    func cityNamesArrayIsEMPTY() -> Bool {
        var rc: Bool = false
        let cityNamesArray = defaults.array(forKey: "subscriptionSetKey")
        
        if ( (cityNamesArray == nil) || (cityNamesArray?.count == 0) ) {
            rc = true
        }
        
        return rc
    }
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    func getSubscriptionCitySet() -> Set<String> {
        var cityNamesArray = [String]()
        cityNamesArray = defaults.object(forKey: "subscriptionSetKey") as? [String] ?? [String]()
        
        for item in cityNamesArray {
            subscriptionCityPersistencyManager.insert(item)
        }
        
        return subscriptionCityPersistencyManager     
    }
    
    func getSubscriptionCitySetX() -> Set<String> {
        var cityNamesArray = [String]()
        
        if (isKeyPresentInUserDefaults(key: "subscriptionSetKey") == true) {
            cityNamesArray = (defaults.array(forKey: "subscriptionSetKey") as? [String])!
            
            for item in cityNamesArray {
                subscriptionCityPersistencyManager.insert(item)
            }
        }
        return subscriptionCityPersistencyManager
    }

    func getSubscriptionCityCount() -> Int {
        let gscc =  defaults.object(forKey: "subscriptionSetKey") as? [String] ?? [String]()
        return gscc.count
    }
    
    func retrieveSubscriptionCitySet() -> Set<String> {
        return subscriptionCityPersistencyManager
    }
    
    // MARK: Device Token Ops -------------------------
    func setDeviceTokenWith(myDeviceToken: String) {
        deviceToken = myDeviceToken        
        defaults.set(myDeviceToken, forKey: "deviceTokenKey")
    }
    
    func getDeviceToken() -> String {
        deviceToken = (defaults.object(forKey: "deviceTokenKey")  as? String)!
        return deviceToken
    }

    
    // MARK: masterCityNamesHash Ops ---------------------
    func setMasterCityNameHashWith(cityNameHash: Dictionary<String, String>) {
        masterCityNamesHash = cityNameHash
    }
    
    func getMasterCityNameHash() -> Dictionary<String, String> {
        return masterCityNamesHash
    }
    
    func masterCityNameHashIsEMPTY() -> Bool {
        var rc: Bool = false
        if (masterCityNamesHash.count == 0) {
            rc = true
        }
        return rc
    }
    
    
    // MARK: masterCityNamesIdHash Ops ---------------------
    func setMasterCityNameIdHashWith(cityNameIdHash: Dictionary<String, String>) {
        if (cityNameIdHash.count == 0) {
            masterCityNamesIdHash.removeAll()
        }
        else {
            masterCityNamesIdHash = cityNameIdHash
            defaults.set(cityNameIdHash, forKey: "masterCityNameIdHashKey")
        }
    }
    
    func getMasterCityNameIdHash() -> Dictionary<String, String> {
        masterCityNamesIdHash = defaults.dictionary(forKey: "masterCityNameIdHashKey") as! [String : String]
        return masterCityNamesIdHash
    }
    
    func masterCityNameIdHashIsEMPTY() -> Bool {
        var rc: Bool = false
        if (masterCityNamesIdHash.count == 0) {
            rc = true
        }
        return rc
    }
    
    // MARK: URL Ops
    func getDolSubscriptionListUrl() -> String {
        var url = String()
        
        // No device token -> no subscription list to get from URL
        if (deviceToken == "") {
            url = (doLSubscriptionListNoTokenAvailable)
        }
        else {
            url = (baseDoLUrl + doLSubscriptionListSuffix + deviceToken)
        }
        return url
    }
    
    func getDolCityListUrl() -> String {
        var url = String()
        url = baseDoLUrl + dolCityListUrlSuffix
        return url
    }
    
    func getCreateCitySubscriptionUrl() -> String {
        var url = String()
        url = baseDoLUrl + dolCreateCitySubscriptionUrlSuffix
        return url
    }
    
    func getCityStatusesUrl() -> String {
        var url = String()
        
        if (deviceToken == "") {
            url = (doLSubscriptionListNoTokenAvailable)
        }
        else {
            url = (baseDoLUrl + doLSubscriptionCityStatusSuffix + deviceToken)
        }
        return url
    }
    
    
    func getSelectedCityStatus() -> CityStatus {
        return selectedCityStatus
    }
    
    func setSelectedCityStatus(mySelectedCityStatus: CityStatus){
        selectedCityStatus = mySelectedCityStatus
    }
    
    func getCreateDeviceTokenOnMTWSUrl() -> String {
        return dolCreateDeviceTokenOnMTWSUrl
    }
    
    func getUpdateDeviceTokenOnMTWSUrl() -> String {
        return dolCreateDeviceTokenOnMTWSUrl
    }
    
    
    // MARK: Nick's URLS
    func getcreateDeviceTokenOnMTWSUrl() -> String {
        return dolCreateDeviceTokenOnMtws
    }
    
    func getDolStagingListOfCitiesBase() -> String {
        return dolStagingGetListOfCitiesBase
    }

    func getDolStagingGetSubscriptionListBase() -> String {
        return dolStagingGetSubscriptionListBase
    }

    func getDolStagingCreateSubscriptionListBase() -> String {
        return dolStagingCreateSubscriptionListBase
    }
    
    func getDolStagingGetCityStatusesBase() -> String {
        return dolStagingGetCityStatusesBase
    }
    

    
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }

    
    
    struct cityFullIdentifierStruct {
        var cityName = String()
        var stateCode = String()
        var stateName = String()
        var regionName = String()
    }
    
    typealias CFI = cityFullIdentifierStruct
    func parseCityState(cityState: String) -> CFI {
        var cfi = CFI()
        
        let formattedArray = cityState.components(separatedBy: " ")
        // handle multi named city
        let count = formattedArray.count
        var cntr = 1
        var bigCity = String()
        for dot in formattedArray {
            bigCity += dot
            cntr += 1
            if (cntr == count) {
                break
            }
            else {
                bigCity += " "
            }
        }
        let state = formattedArray[count-1]
        cfi.stateCode = state
        cfi.cityName = bigCity
        return cfi
    }
    
    func setOriginatingNavVC(originatingNavVC: String) {
        self.originatingNavVC = originatingNavVC
    }
    
    func getOriginatingNavVC() -> String {
        return self.originatingNavVC
    }
}
