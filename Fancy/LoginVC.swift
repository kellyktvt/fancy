//
//  LoginVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/3/23.
//

import UIKit
import FirebaseAuth

class LoginVC: BaseViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var statusMessage: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        passwordField.delegate = self
        
        emailField.keyboardType = .emailAddress
        
        // Add drop shadows in light mode only
        if traitCollection.userInterfaceStyle == .light {
            // Add drop shadow to emailField
            emailField.layer.shadowColor = UIColor.gray.cgColor
            emailField.layer.shadowOffset = CGSize(width: 1, height: 2)
            emailField.layer.shadowOpacity = 0.5
            emailField.layer.shadowRadius = 4
                    
            // Add drop shadow to passwordField
            passwordField.layer.shadowColor = UIColor.gray.cgColor
            passwordField.layer.shadowOffset = CGSize(width: 2, height: 2)
            passwordField.layer.shadowOpacity = 0.5
            passwordField.layer.shadowRadius = 4
            
            // Add drop shadow to signInButton
            signInButton.layer.shadowColor = UIColor.gray.cgColor
            signInButton.layer.shadowOffset = CGSize(width: 2, height: 2)
            signInButton.layer.shadowOpacity = 0.5
            signInButton.layer.shadowRadius = 4
        }
        
        passwordField.isSecureTextEntry = true
        
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        Auth.auth().addStateDidChangeListener() {
            (auth,user) in
            if user != nil {
                self.emailField.text = nil
                self.passwordField.text = nil
            }
        }
    }
    
    @IBAction func signInButton(_ sender: Any) {
        Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) {
         (authResult,error) in
            if let error = error as NSError? {
                self.statusMessage.text = "\(error.localizedDescription)"
            } else {
                self.statusMessage.text = ""
                // Go to tabs
                if let tabBarController = self.storyboard!.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
                    // Customize the presentation style to full screen
                    tabBarController.modalPresentationStyle = .fullScreen
                    // Present the UITabBarController modally
                    self.present(tabBarController, animated: true, completion: nil)
                }
            }
        }
    }
    
    // Called when 'return' key pressed
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Called when the user clicks on the view outside of the UITextField
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            // Check if focused field is one of these
            if statusMessage.text != "" {
                // Move view's frame up
                self.view.frame.origin.y = -55
            }
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        // Reset view's frame when keyboard is hidden
        self.view.frame.origin.y = 0
    }
}
