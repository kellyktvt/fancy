//
//  CreateItemVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/20/23.
//

import UIKit

class CreateItemVC: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemPrice: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    var delegate: UIViewController!
    var linkURL: URL!
    var itemNote: String!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        
        // Round corners of item image
        itemImage.layer.cornerRadius = 15
        itemImage.layer.masksToBounds = true
        
        // Set default name and price
        itemName.adjustsFontSizeToFitWidth = true
        itemName.text = "New Item"
        itemPrice.text = "$0.00"
    }
    
    @IBAction func addImageButton(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(self.imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // Check if image selected
        if let pickedImage = info[.originalImage] as? UIImage {
            itemImage.contentMode = .scaleAspectFill
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
    
    @IBAction func editNameButton(_ sender: Any) {
        // Create action sheet for item name editing
        let controller = UIAlertController(
            title: "Edit Item Name",
            message: nil,
            preferredStyle: .alert)
        
        // Add cancel option
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Add text field
        controller.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Enter name"
            textField.text = self.itemName.text
        } )
        
        // Add save option
        controller.addAction(UIAlertAction(title: "Save", style: .default, handler: {
            (action) in self.itemName.text = controller.textFields![0].text
        } ))
        
        present(controller, animated: true)
    }
    
    @IBAction func editPriceButton(_ sender: Any) {
        // Create action sheet for item price editing
        let controller = UIAlertController(
            title: "Edit Item Price",
            message: nil,
            preferredStyle: .alert)
        
        // Add cancel option
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Add text field
        controller.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Enter price"
            textField.text = self.itemPrice.text
        } )
        
        // Add save option
        controller.addAction(UIAlertAction(title: "Save", style: .default, handler: {
            (action) in self.itemPrice.text = controller.textFields![0].text
        } ))
        
        present(controller, animated: true)
    }
    
    @IBAction func addLinkButton(_ sender: Any) {
        // Create action sheet for item link editing
        let controller = UIAlertController(
            title: "Add Item Link",
            message: nil,
            preferredStyle: .alert)
        
        // Add cancel option
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Add text field
        controller.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Enter link"
            textField.text = self.linkURL?.absoluteString
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
    
    @IBAction func addNoteButton(_ sender: Any) {
        // Create action sheet for item link editing
        let controller = UIAlertController(
            title: "Add Item Note",
            message: nil,
            preferredStyle: .alert)
        
        // Add cancel option
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Add text field
        controller.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Enter note"
            textField.text = self.itemNote
        } )
        
        // Add save option
        controller.addAction(UIAlertAction(title: "Save", style: .default, handler: {
            (action) in self.itemNote = controller.textFields![0].text!
        } ))
        
        present(controller, animated: true)
    }
    
    @IBAction func createButton(_ sender: Any) {
        let item = WishlistItem(id: nil, coverImage: itemImage.image, name: itemName.text ?? "New Item", price: itemPrice.text ?? "", link: linkURL, note: itemNote, claimId: "unclaimed")
        let otherVC = delegate as! ItemAdder
        otherVC.addCreatedItem(newItem: item)
        
        // Navigate back to MyListVC
        navigationController?.popViewController(animated: true)
    }
}
    
