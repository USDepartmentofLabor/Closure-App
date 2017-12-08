//
//  StepZero.swift
//  onboardingWithUIPageViewController
//
//  Created by Robert Chen on 8/11/15.
//  Copyright (c) 2015 Thorn Technologies. All rights reserved.
//


import UIKit
import Alamofire
import MBProgressHUD



class StepZero : UIViewController {
    
    @IBOutlet weak var stepZeroImageView: UIImageView!
    
    func navigateToStepOneVC() {
        
        print("STEP ZERO: WELCOME: navigateToStepOneVC: Calling SWRevealVC ***************")
        
        let runState = LibraryAPI.sharedInstance.getRunStatus()
        print("STEP ZERO: WELCOME: navigateToStepOneVC: RUNSTATE: ", runState)
        
        var vcIdentifier = "selectCitiesNavVC"
        if ( runState != INITIALSETTINGRUNSTATE ) {
            vcIdentifier = "SWRevealVC"
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: vcIdentifier) as UIViewController

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = controller
        self.present(controller, animated: true, completion: nil)
    }
    

    override func viewDidLoad() {
        print("\n")
        print("STEP ZERO: WELCOME: viewDidLoad ***************")
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // TODO: will replace with call to server to randomly select an image
        stepZeroImageView.image = UIImage(named: "scotty.jpg")
        
        HelperLibrary.delay(3.0, completion: {
            self.navigateToStepOneVC()
        })
    }
    
}
