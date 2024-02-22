//
//  SettingsVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/3/23.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import AVFoundation

class SettingsVC: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var pfp: UIImageView!
    @IBOutlet weak var copyCodeButton: UIButton!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var linksSegCtrl: UISegmentedControl!
    
    let imagePicker = UIImagePickerController()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self

        // Make PFP a circle
        pfp.layer.cornerRadius = pfp.frame.size.width / 2.0
        pfp.layer.masksToBounds = true
        
        // Load PFP
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let self = self, let userData = snapshot.value as? [String: Any] else { return }

            if let base64String = userData["pfpBase64"] as? String,
               let imageData = Data(base64Encoded: base64String),
               let profilePicture = UIImage(data: imageData) {
                self.pfp.contentMode = .scaleAspectFill
                self.pfp.image = profilePicture
            }
        }
        
        // Load friend code
        guard let userId = Auth.auth().currentUser?.uid else { return }
        copyCodeButton.setTitle("\(userId)", for: .normal)
        
        // Set initial state of dark mode switch
        darkModeSwitch.isOn = UserDefaults.standard.bool(forKey: "darkMode")
        
        // Set initial state of links seg ctrl
        linksSegCtrl.selectedSegmentIndex = UserDefaults.standard.bool(forKey: "openLinksInApp") ? 0 : 1
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
            // Save updated pfp
            guard let userId = Auth.auth().currentUser?.uid else { return }
            if let imageData = pickedImage.jpegData(compressionQuality: 0.5) {
                let base64String = imageData.base64EncodedString()
                let ref = Database.database().reference().child("users").child(userId)
                ref.child("pfpBase64").setValue(base64String)
            }
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    @IBAction func copyCodeButton(_ sender: Any) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Copy friend code to clipboard
        UIPasteboard.general.string = userId

        // Show alert to indicate friend code has been copied
        let controller = UIAlertController(
            title: "Friend code copied",
            message: "Your friend code has been copied to the clipboard.",
            preferredStyle: .alert
        )
        
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func editNameButton(_ sender: Any) {
        // Create action sheet for name editing
        let controller = UIAlertController(title: "Edit Name", message: nil, preferredStyle: .alert)
        
        // Add cancel option
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Add text field
        controller.addTextField { (textField) in
            textField.placeholder = "Enter new name"
            // Fetch the user's name from the Realtime Database
            if let userID = Auth.auth().currentUser?.uid {
                let userRef = Database.database().reference().child("users").child(userID)
                userRef.observeSingleEvent(of: .value) { (snapshot) in
                    if let userData = snapshot.value as? [String: Any],
                       let userName = userData["name"] as? String {
                        textField.text = userName
                    }
                }
            }
        }
        
        // Add save option
        controller.addAction(UIAlertAction(title: "Save", style: .default) { (action) in
            guard let newName = controller.textFields?[0].text,
                  let userID = Auth.auth().currentUser?.uid else { return }
            
            // Update the name in the Realtime Database
            let userRef = Database.database().reference().child("users").child(userID)
            userRef.child("name").setValue(newName)
        })
        
        present(controller, animated: true)
    }
    
    @IBAction func editEmailButton(_ sender: Any) {
        // Create action sheet for email editing
        let controller = UIAlertController(title: "Edit Email", message: nil, preferredStyle: .alert)

        // Add cancel option
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // Add text field
        controller.addTextField { (textField) in
            textField.placeholder = "Enter new email"
            textField.text = Auth.auth().currentUser?.email
            textField.keyboardType = .emailAddress
        }

        // Add save option
        controller.addAction(UIAlertAction(title: "Save", style: .default) { (action) in
            guard let newEmail = controller.textFields?[0].text else { return }
            Auth.auth().currentUser?.updateEmail(to: newEmail)
        })

        present(controller, animated: true)
    }
    
    @IBAction func changePasswordButton(_ sender: Any) {
        // Create action sheet for password editing
        let controller = UIAlertController(title: "Change Password", message: nil, preferredStyle: .alert)

        // Add cancel option
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // Add text fields
        controller.addTextField { textField in
            textField.placeholder = "Enter new password"
            textField.isSecureTextEntry = true
        }
        
        // Add save option
        controller.addAction(UIAlertAction(title: "Save", style: .default) { (action) in
            guard let newPassword = controller.textFields?[0].text,
                  let user = Auth.auth().currentUser else { return }
            user.updatePassword(to: newPassword)
        })
        
        present(controller, animated: true)
    }
    
    @IBAction func onLinksSegmentChanged(_ sender: Any) {
        switch linksSegCtrl.selectedSegmentIndex {
        case 0:
            UserDefaults.standard.set(true, forKey: "openLinksInApp")
        case 1:
            UserDefaults.standard.set(false, forKey: "openLinksInApp")
        default:
            UserDefaults.standard.set(true, forKey: "openLinksInApp")
        }
    }
    
    @IBAction func logOutButton(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            
            if let loginNavC = self.storyboard?.instantiateViewController(withIdentifier: "LoginNavC") as? UINavigationController {
                // Customize presentation style to full screen
                loginNavC.modalPresentationStyle = .fullScreen
                // Present LoginNavC modally
                present(loginNavC, animated: true, completion: nil)
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
