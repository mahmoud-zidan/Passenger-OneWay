//
//  SignIn.swift
//  Graduation Project
//
//  Created by MahmoudIsmaeilAtito on 2/14/18.
//  Copyright © 2018 MahmoudIsmaeilAtito. All rights reserved.



import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
class SignIn: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    // load From Database
    var model : Model?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
    }
    
    // MARK:- Sign IN
    @IBAction func login(_ sender: Any) {
        let rootRef = Database.database().reference()
        Auth.auth().addStateDidChangeListener({auth, user in
                if user != nil {
                    
                    Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!, completion:{ (user,error) in
                        if error != nil{
                            self.errorLabel.text = error?.localizedDescription
                            print(self.errorLabel.text!)
                        }
                        else{
                            self.errorLabel.text = ""
                            let user = Auth.auth().currentUser
                            guard let uid = user?.uid else {
                                return
                    }
                            rootRef.child("passengers").child(uid).observeSingleEvent(of: .value, with: {(snapshot: DataSnapshot) in
                                if (snapshot.exists()) {
                                    // is a passenger
                                    let data = snapshot.value as! NSDictionary
                                    let OptionalName = data["Name"] as? String
                                    let OptionalEmail = data["Email"] as? String
                                    let OptionalPhone = data["Phone_Number"] as? String
                                    let OptionalPhotoURL = data["downloadURL"] as? String
                                    guard let name = OptionalName,let email = OptionalEmail,let phone = OptionalPhone,let photoUrl=OptionalPhotoURL else {
                                        print("the name or email or phone or photoUrl is a nil value")
                                      
                                        return
                                    }
                                    self.model = Model(uid: uid, name: name, email: email, phone: phone, photoUrl: photoUrl)
                                    print("logged in as a passenger")
                                    // move to map view of a passenger
                                    self.performSegue(withIdentifier: "passengerFromSignIn", sender: self)
                                }
                                else{
                                    self.errorLabel.text = "Wrong Data"
                                }
                            })
                        } // end of else
                    })
            }
        })
    }
     // MARK: - Navigation
    
     // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
        if segue.identifier == "passengerFromSignIn"{
        let tabVC = segue.destination as? UITabBarController
        let passengerVC = tabVC?.viewControllers?.first as? PassengerMap
        passengerVC?.passenger  = self.model
       
        }
  }
}
