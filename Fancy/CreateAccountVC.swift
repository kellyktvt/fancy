//
//  CreateAccountVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/5/23.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import AVFoundation

class CreateAccountVC: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var pfp: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmField: UITextField!
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var signUpButton: UIButton!
    
    let imagePicker = UIImagePickerController()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        confirmField.delegate = self
        imagePicker.delegate = self
        
        emailField.keyboardType = .emailAddress

        // Make PFP a circle
        pfp.layer.cornerRadius = pfp.frame.size.width / 2.0
        pfp.layer.masksToBounds = true
        
        // Add drop shadows in light mode only
        if traitCollection.userInterfaceStyle == .light {
            // Add drop shadow to nameField
            nameField.layer.shadowColor = UIColor.gray.cgColor
            nameField.layer.shadowOffset = CGSize(width: 1, height: 2)
            nameField.layer.shadowOpacity = 0.5
            nameField.layer.shadowRadius = 4
            
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
            
            // Add drop shadow to confirmField
            confirmField.layer.shadowColor = UIColor.gray.cgColor
            confirmField.layer.shadowOffset = CGSize(width: 2, height: 2)
            confirmField.layer.shadowOpacity = 0.5
            confirmField.layer.shadowRadius = 4
            
            // Add drop shadow to signUpButton
            signUpButton.layer.shadowColor = UIColor.gray.cgColor
            signUpButton.layer.shadowOffset = CGSize(width: 2, height: 2)
            signUpButton.layer.shadowOpacity = 0.5
            signUpButton.layer.shadowRadius = 4
        }
        
        passwordField.isSecureTextEntry = true
        confirmField.isSecureTextEntry = true
        
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func editPFPButton(_ sender: Any) {
        // Create action sheet for pfp creation
        let controller = UIAlertController(
            title: "Add Profile Picture",
            message: "Select from photo library or use camera",
            preferredStyle: .actionSheet)
        
        // Add photo library option
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default, handler: {
            (action) in self.librarySelected()
        })
        controller.addAction(libraryAction)
        
        // Add camera option
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: {
            (action) in self.cameraSelected()
        })
        controller.addAction(cameraAction)
        
        // Add cancel option
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        
        present(controller, animated: true)
    }
    
    func librarySelected() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    func cameraSelected() {
        if UIImagePickerController.availableCaptureModes(for: .rear) != nil || UIImagePickerController.availableCaptureModes(for: .front) != nil {
            
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) {
                    (accessGranted) in
                    guard accessGranted == true else { return }
                }
            case .authorized:
                break
            default:
                print("Access denied")
                return
            }
            
            // We have camera access
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .camera
            imagePicker.cameraCaptureMode = .photo
            
            present(imagePicker, animated: true)
            
        } else {
            // no camera
            let alertVC = UIAlertController(
                title: "No Camera",
                message: "Sorry, this device has no camera",
                preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertVC.addAction(okAction)
            present(alertVC, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // Check if image selected
        if let pickedImage = info[.originalImage] as? UIImage {
            pfp.contentMode = .scaleAspectFill
            pfp.image = pickedImage
        } else {
            // Use default if no image selected
            pfp.contentMode = .scaleAspectFill
            pfp.image = UIImage(named: "PFP")
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    @IBAction func signUpButton(_ sender: Any) {
        // Check for matching passwords
        guard let password = passwordField.text, let confirmPassword = confirmField.text, password == confirmPassword else {
            self.statusMessage.text = "Passwords don't match"
            return
        }
        
        // Check for invalid input
        guard let email = emailField.text, let name = nameField.text else {
            self.statusMessage.text = "Invalid input"
            return
        }
        
        // Create user
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error as NSError? {
                self?.statusMessage.text = "\(error.localizedDescription)"
            } else {
                
                self?.statusMessage.text = ""
                
                // Convert pfp image data to base64-encoded string
                if let user = authResult?.user, let imageData = self?.pfp.image?.jpegData(compressionQuality: 0.5) {
                    let base64String = imageData.base64EncodedString()
                    
                    // Save user's name and pfp to Realtime Database
                    let ref = Database.database().reference()
                    let userRef = ref.child("users").child(user.uid)
                    userRef.child("name").setValue(name)
                    userRef.child("pfpBase64").setValue(base64String)
                    
                    // Go to tabs
                    if let tabBarController = self?.storyboard!.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
                        // Customize presentation style to full screen
                        tabBarController.modalPresentationStyle = .fullScreen
                        // Present tabBarController modally
                        self?.present(tabBarController, animated: true, completion: nil)
                    }
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
            if emailField.isFirstResponder || passwordField.isFirstResponder || confirmField.isFirstResponder {
                // Move view's frame up
                self.view.frame.origin.y = -keyboardSize.height
            }
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        // Reset view's frame when keyboard is hidden
        self.view.frame.origin.y = 0
    }
}
