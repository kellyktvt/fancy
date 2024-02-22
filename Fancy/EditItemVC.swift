//
//  EditItemVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/28/23.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import AVFoundation

class EditItemVC: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var priceField: UITextField!
    @IBOutlet weak var noteTitle: UILabel!
    @IBOutlet weak var notesView: UITextView!
    
    let imagePicker = UIImagePickerController()
    
    var chosenItem: WishlistItem?
    var chosenWishlist: Wishlist?
    var linkURL: URL!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        nameField.delegate = self
        priceField.delegate = self
        
        // Round corners of item image
        itemImage.layer.cornerRadius = 15
        itemImage.layer.masksToBounds = true
        
        // Set item name, image, price, note
        nameField.text = chosenItem?.name
        itemImage.image = chosenItem?.coverImage
        priceField.text = chosenItem?.price
        notesView.text = chosenItem?.note
        notesView.font = UIFont.systemFont(ofSize: 18)
        notesView.isEditable = true
        notesView.isScrollEnabled = true
        
        // Underline noteTitle
        noteTitle.attributedText = NSAttributedString(string: "Notes", attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // Check if image selected
        if let pickedImage = info[.originalImage] as? UIImage {
            // Size image to fill imageView
            itemImage.contentMode = .scaleAspectFill
            
            // Put image into imageView
            itemImage.image = pickedImage
        } else {
            // Use default if no image selected
            itemImage.contentMode = .scaleAspectFill
            itemImage.image = UIImage(named: "DefaultCover")
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    @IBAction func editImageButton(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(self.imagePicker, animated: true)
    }
    
    @IBAction func editLinkButton(_ sender: Any) {
        // Create action sheet for item link editing
        let controller = UIAlertController(
            title: "Edit Item Link",
            message: nil,
            preferredStyle: .alert)
        
        // Add cancel option
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Add text field
        controller.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Enter link"
            textField.text = self.chosenItem?.link?.absoluteString
        } )
        
        // Add save option
        controller.addAction(UIAlertAction(title: "Save", style: .default, handler: {
            (action) in
            if let urlString = controller.textFields![0].text, let url = URL(string: urlString) {
                // Check if the URL is valid
                if UIApplication.shared.canOpenURL(url) {
                    self.linkURL = url
                } else {
                    // Display an alert for invalid URL
                    let alert = UIAlertController(title: "Invalid URL", message: "Please enter a valid URL", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } ))
        
        present(controller, animated: true)
    }
    
    @IBAction func doneButton(_ sender: Any) {
        // Update item in Firebase
        updateItemInFirebase()
        
        // Navigate back to ItemVC
        navigationController?.popViewController(animated: true)
    }
    
    func updateItemInFirebase() {
        guard let userId = Auth.auth().currentUser?.uid,
              let wishlistId = chosenWishlist?.id,
              let itemId = chosenItem?.id else { return }
        
        // Reference to Firebase database
        let ref = Database.database().reference()
        
        // Reference to specific item
        let itemRef = ref.child("users").child(userId).child("wishlists").child(wishlistId).child("items").child(itemId)
        
        // Update item data in database
        itemRef.child("name").setValue(nameField.text ?? "")
        itemRef.child("price").setValue(priceField.text ?? "")
        itemRef.child("note").setValue(notesView.text ?? "")
        
        // Convert UIImage to base64-encoded string
        if let imageData = itemImage.image?.jpegData(compressionQuality: 0.5) {
            let base64String = imageData.base64EncodedString()
            itemRef.child("itemImageBase64").setValue(base64String)
        }
        
        // Update linkURL if it's not nil
        if let linkURL = linkURL {
            itemRef.child("link").setValue(linkURL.absoluteString)
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
            // Check if notesView is first responder
            if notesView.isFirstResponder {
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
