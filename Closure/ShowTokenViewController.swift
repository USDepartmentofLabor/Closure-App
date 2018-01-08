//
//  ShowTokenViewController.swift
//  Closure
//
//  Created by liu-george-p on 1/5/18.
//  Copyright © 2018 oasam. All rights reserved.
//

import UIKit

class ShowTokenViewController: UIViewController {

    @IBOutlet weak var tokenLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        

        
//        let alert = UIAlertController(title: deviceToken, message: deviceToken, preferredStyle: UIAlertControllerStyle.alert)
//        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
//        self.present(alert, animated: true, completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        let deviceToken = LibraryAPI.sharedInstance.getDeviceToken()
        
        self.tokenLabel.text = deviceToken
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
