//
//  CreateListVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/17/23.
//

import UIKit

class CreateListVC: BaseViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var listImage: UIImageView!
    @IBOutlet weak var listName: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    var delegate: UIViewController!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        
        // Round corners of list image
        listImage.layer.cornerRadius = 15
        listImage.layer.masksToBounds = true
        
        // Set default name
        listName.adjustsFontSizeToFitWidth = true
        listName.text = "New List"
    }
    
    @IBAction func addImageButton(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(self.imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // Check if image selected
        if let pickedImage = info[.originalImage] as? UIImage {
            listImage.contentMode = .scaleAspectFill
            listImage.image = pickedImage
        } else {
            // Use default if no image selected
            listImage.contentMode = .scaleAspectFill
            listImage.image = UIImage(named: "DefaultCover")
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    @IBAction func editNameButton(_ sender: Any) {
        // Create action sheet for list name editing
        let controller = UIAlertController(
            title: "Edit List Name",
            message: nil,
            preferredStyle: .alert)
        
        // Add cancel option
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Add text field
        controller.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Enter new list name"
            textField.text = self.listName.text
        } )
        
        // Add save option
        controller.addAction(UIAlertAction(title: "Save", style: .default, handler: {
            (action) in self.listName.text = controller.textFields![0].text
        } ))
        
        present(controller, animated: true)
    }
    
    @IBAction func createButton(_ sender: Any) {
        let wishlist = Wishlist(coverImage: listImage.image, name: listName.text!)
        let otherVC = delegate as! ListAdder
        otherVC.addCreatedList(newList: wishlist)
        
        // Navigate back to HomeVC
        navigationController?.popViewController(animated: true)
    }
}
