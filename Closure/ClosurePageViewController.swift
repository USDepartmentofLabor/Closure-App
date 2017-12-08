//
//  ClosurePageViewController.swift
//  Closure
//
//  Created by liu-george-p on 10/26/17.
//  Copyright © 2017 oasam. All rights reserved.
//

import UIKit

// Navigation instructions

let NAVIGATEPAGEFORWARD = "NAVIGATEPAGEFORWARD"
let NAVIGATEPAGEBACKWARD = "NAVIGATEPAGEBACKWARD"
var userInfo = [String: String]()

class ClosurePageViewController: UIPageViewController {


        
    override func viewDidLoad() {
            
        print("CLOSUREPAGEVC: viewDidLoad")
            
        // Set the dataSource and delegate in code.
        // I can't figure out how to do this in the Storyboard!
        dataSource = self
        delegate = self
        
        // this sets the background color of the built-in paging dots
        view.backgroundColor = UIColor.darkGray
            
        // This is the starting point.  Start with step zero.
        setViewControllers([getStepZero()], direction: .forward, animated: false, completion: nil)
            
            
            
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(goToNextPage),
                                                name: NSNotification.Name(rawValue: NAVIGATEPAGEFORWARD),
                                                object: nil)
            
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(goToPreviousPage),
                                                name: NSNotification.Name(rawValue: NAVIGATEPAGEBACKWARD),
                                                object: nil)
            
    }
        
    func getStepZero() -> StepZero {
        return storyboard!.instantiateViewController(withIdentifier: "StepZero") as! StepZero
    }
        
    func getStepOne() -> StepOne {
        return storyboard!.instantiateViewController(withIdentifier: "StepOne") as! StepOne
    }
        
    func goToNextPage(){
            
        guard let currentViewController = self.viewControllers?.first else { return }
        
        guard let nextViewController = dataSource?.pageViewController( self, viewControllerAfter: currentViewController ) else { return }
            
        setViewControllers([nextViewController], direction: .forward, animated: false, completion: nil)
            
    }
        
    func goToPreviousPage(){
            
        guard let currentViewController = self.viewControllers?.first else { return }
            
        guard let previousViewController = dataSource?.pageViewController( self, viewControllerBefore: currentViewController ) else { return }
            
        setViewControllers([previousViewController], direction: .reverse, animated: false, completion: nil)
            
    }
        
}
    
    
    
// MARK: - UIPageViewControllerDataSource methods
extension ClosurePageViewController : UIPageViewControllerDataSource {
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            
        print("CLOSUREPAGEVC: viewControllerBefore")
            
        if viewController.isKind(of: StepOne.self) {
            // 1 -> 0
            return getStepZero()
        } else {
            // 0 -> end of the road
            return nil
        }
    }
        
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            
        print("CLOSUREPAGEVC: viewControllerAfter")
            
        if viewController.isKind(of: StepZero.self) {
            // 0 -> 1
            return getStepOne()
        }
        else {
            return nil
        }
    }
}

// MARK: - UIPageViewControllerDelegate methods
extension ClosurePageViewController : UIPageViewControllerDelegate {
        
}
