//
//  ViewController.swift
//  Uber Clone
//
//  Created by Andranik Karapetyan on 11/27/20.
//  Copyright © 2020 Andranik Karapetyan. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleMobileAds

class ViewController: UIViewController, GADFullScreenContentDelegate
{

    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var topButton: UIButton!
    @IBOutlet weak var buttomButton: UIButton!
    @IBOutlet weak var riderDriverSwitch: UISwitch!
    
    var signUpMode = true
    var interstitial: GADInterstitialAd!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        interstitial = GADInterstitialAd(adUnitID: "ca-app-pub-3940256099942544/4411468910")
//        let request = GADRequest()
//        interstitial.load(request)
        
        let request = GADRequest()
            GADInterstitialAd.load(withAdUnitID:"ca-app-pub-3940256099942544/4411468910",
                                        request: request,
                              completionHandler: { (ad, error) in
                                if let error = error {
                                  print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                                  return
                                }
                                self.interstitial = ad
                                self.interstitial.fullScreenContentDelegate = self
                              })
    }

    @IBAction func RiderDriverSwitch(_ sender: Any)
    {
    }
    
    @IBAction func TopButton(_ sender: Any)
    {
        if emailTextField.text == "" || passwordTextField.text == ""
        {
            displayAlert(title: "Missing Information", message: "You must provide both an email and password")
        }
        else
        {
            if let email = emailTextField.text
            {
                if let password = passwordTextField.text
                {
                    if signUpMode
                    {
                        //-/ Create/SignUp a user into Firebase
                        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                            if error != nil
                            {
                                self.displayAlert(title: "Error", message: error!.localizedDescription)
                            }
                            else
                            {
                                if self.riderDriverSwitch.isOn
                                {
                                    let req = Auth.auth().currentUser?.createProfileChangeRequest()
                                    req?.displayName = "Driver"
                                    req?.commitChanges(completion: nil)
                                    
                                    self.performSegue(withIdentifier: "DriverSegue", sender: nil)
                                }
                                else
                                {
                                    let req = Auth.auth().currentUser?.createProfileChangeRequest()
                                    req?.displayName = "Rider"
                                    req?.commitChanges(completion: nil)

                                    self.performSegue(withIdentifier: "RiderSegue", sender: nil)
                                }
                            }
                        }
                    }
                    else
                    {
                        //-/ Sign In user with Firebase
                        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                            if error != nil
                            {
                                self.displayAlert(title: "Error", message: error!.localizedDescription)
                            }
                            else
                            {
                                if let currentUser = Auth.auth().currentUser
                                {
                                    if currentUser.displayName == "Driver"
                                    {
                                        print("Driver")
                                        self.performSegue(withIdentifier: "DriverSegue", sender: nil)
                                    }
                                    else
                                    {
                                        self.performSegue(withIdentifier: "RiderSegue", sender: nil)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func displayAlert(title:String, message:String)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func ButtomButton(_ sender: Any)
    {
        if interstitial != nil
        {
          interstitial.present(fromRootViewController: self)
        }
        else
        {
          print("Ad wasn't ready")
        }
        
        if signUpMode
        {
            topButton.setTitle("Log In", for: .normal)
            buttomButton.setTitle("Switch to Sign Up", for: .normal)
            riderLabel.isHidden = true
            driverLabel.isHidden = true
            riderDriverSwitch.isHidden = true
            signUpMode = false
        }
        else
        {
            topButton.setTitle("Sign Up", for: .normal)
            buttomButton.setTitle("Switch to Sign Up", for: .normal)
            riderLabel.isHidden = false
            driverLabel.isHidden = false
            riderDriverSwitch.isHidden = false
            signUpMode = true
        }
    }
}

