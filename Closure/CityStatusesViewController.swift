//
//  CityStatusesViewController.swift
//  Closure
//
//  Created by liu-george-p on 11/2/17.
//  Copyright © 2017 oasam. All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD


class CityStatusesViewController: UIViewController {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("CITYSTATUSESVC: viewDidLoad")
        
        if self.revealViewController() != nil {
            print("CITYSTATUSESVC: viewDidLoad: revealViewController() != nil")
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        
        // Do any additional setup after loading the view.
        HelperLibrary.delay(0.5, completion: {
            self.loadCityStatusesFromMtws()
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
