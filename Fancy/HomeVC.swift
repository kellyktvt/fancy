//
//  ViewController.swift
//  Fancy
//
//  Created by Kelly T. on 11/3/23.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class HomeVC: BaseViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, ListAdder, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var pfp: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var ref: DatabaseReference!
    var wishlists = [Wishlist]()
    var imagePickerWishlist: Wishlist?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar to let user tap Add Button
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show navigation bar when view is about to disappear so it shows for other VCs
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up Firebase
        ref = Database.database().reference()
        loadListsFromFirebase()
        
        // Make PFP a circle
        pfp.layer.cornerRadius = pfp.frame.size.width / 2.0
        pfp.layer.masksToBounds = true
        
        // Load PFP
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let userRef = ref.child("users").child(userId)
        userRef.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let self = self, let userData = snapshot.value as? [String: Any] else { return }

            if let base64String = userData["pfpBase64"] as? String,
               let imageData = Data(base64Encoded: base64String),
               let profilePicture = UIImage(data: imageData) {
                self.pfp.contentMode = .scaleAspectFill
                self.pfp.image = profilePicture
            }
        }
        
        // Set up collection view
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 175, height: 200)
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.collectionViewLayout = layout
        
        // Add long press gesture recognizer to collection view
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.delegate = self
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        // Long press triggers action sheet for wishlist editing and deletion
        if gesture.state == .began {
            let touchPoint = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: touchPoint) {
                presentListActionSheet(for: indexPath)
            }
        }
    }
    
    func presentListActionSheet(for indexPath: IndexPath) {
        // Create action sheet for wishlist editing and deletion
        let actionSheet = UIAlertController(title: "Edit or Delete Wishlist", message: nil, preferredStyle: .actionSheet)
        
        // Get the selected wishlist
        let wishlist = wishlists[indexPath.item]
        
        // Add edit name option
        let editNameAction = UIAlertAction(title: "Edit Name", style: .default) { [weak self] _ in
            self?.presentEditFieldAlert(for: wishlist, fieldType: "name")
        }
        actionSheet.addAction(editNameAction)

        // Add edit photo option
        let editPhotoAction = UIAlertAction(title: "Edit Photo", style: .default) { [weak self] _ in
            self?.presentEditFieldAlert(for: wishlist, fieldType: "photo")
        }
        actionSheet.addAction(editPhotoAction)

        // Add delete option
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Remove wishlist from collection
            self.wishlists.remove(at: indexPath.item)
            self.collectionView.deleteItems(at: [indexPath])
            
            // Remove the wishlist from Firebase
            self.deleteWishlistFromFirebase(wishlist)
        }
        actionSheet.addAction(deleteAction)

        // Add cancel option
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true, completion: nil)
    }
    
    func presentEditFieldAlert(for wishlist: Wishlist, fieldType: String) {
        let controller: UIAlertController

        switch fieldType {
        case "name":
            controller = UIAlertController(title: "Edit name", message: nil, preferredStyle: .alert)
            controller.addTextField { textField in
                textField.placeholder = "Enter new name"
                textField.text = wishlist.name
            }
        case "photo":
            controller = UIAlertController(title: "Edit Photo", message: nil, preferredStyle: .actionSheet)
            // Add library option
            let chooseFromLibraryAction = UIAlertAction(title: "Choose from library", style: .default) { [weak self] _ in
                self?.imagePickerWishlist = wishlist
                self?.presentImagePicker(for: wishlist)
            }
            controller.addAction(chooseFromLibraryAction)
            // Add remove option
            let removePhotoAction = UIAlertAction(title: "Remove photo", style: .destructive) { [weak self] _ in
                wishlist.coverImage = nil
                self?.updateWishlistInFirebase(wishlist, fieldType: "photo")
            }
            controller.addAction(removePhotoAction)
        default:
            print("Unexpected field type: \(fieldType)")
            return
        }

        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if fieldType == "name" {
            controller.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak wishlist] _ in
                guard let newName = controller.textFields?.first?.text,
                      let wishlist = wishlist else { return }

                wishlist.name = newName
                self?.updateWishlistInFirebase(wishlist, fieldType: "name")
            })
        }

        present(controller, animated: true, completion: nil)
    }
    
    func presentImagePicker(for wishlist: Wishlist) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true )
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let wishlist = imagePickerWishlist,
              let pickedImage = info[.originalImage] as? UIImage else {
            dismiss(animated: true)
            return
        }

        wishlist.coverImage = pickedImage
        updateWishlistInFirebase(wishlist, fieldType: "photo")

        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePickerWishlist = nil
        dismiss(animated: true)
    }

    func updateWishlistInFirebase(_ wishlist: Wishlist, fieldType: String) {
        guard let userId = Auth.auth().currentUser?.uid, let wishlistId = wishlist.id else { return }
        let wishlistRef = ref.child("users").child(userId).child("wishlists").child(wishlistId)

        switch fieldType {
        case "name":
            wishlistRef.child("name").setValue(wishlist.name)
        case "photo":
            if let listCover = wishlist.coverImage {
                if let imageData = listCover.jpegData(compressionQuality: 0.5) {
                    let base64String = imageData.base64EncodedString()
                    wishlistRef.child("listCoverBase64").setValue(base64String)
                }
            } else {
                let defaultCover = UIImage(named: "DefaultCover")
                if let imageData = defaultCover?.jpegData(compressionQuality: 0.5) {
                    let base64String = imageData.base64EncodedString()
                    wishlistRef.child("listCoverBase64").setValue(base64String)
                }
            }
        default:
            print("Unexpected field type: \(fieldType)")
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue from Add Button to CreateListVC
        if segue.identifier == "CreateListIdentifier",
           let nextVC = segue.destination as? CreateListVC
        {
            nextVC.delegate = self
        }
        // Segue from ListViewCell to MyListVC
        else if segue.identifier == "MyListIdentifier",
            let nextVC = segue.destination as? MyListVC,
            let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first
        {
            let selectedWishlist = wishlists[selectedIndexPath.row]
            nextVC.chosenWishlist = selectedWishlist
        }
    }
    
    func addCreatedList(newList: Wishlist) {
        self.wishlists.append(newList)
        self.collectionView.reloadData()
        self.saveListToFirebase(newList)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListCell", for: indexPath) as! ListViewCell
        
        let wishlist = wishlists[indexPath.row]
        cell.listName.adjustsFontSizeToFitWidth = true
        cell.listName.text = wishlist.name
        cell.listCover.image = wishlist.coverImage
        cell.listCover.contentMode = .scaleAspectFill
        cell.listCover.layer.cornerRadius = 15
        cell.listCover.layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return wishlists.count
    }
    
    func saveListToFirebase(_ wishlist: Wishlist) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let wishlistRef = ref.child("users").child(userId).child("wishlists").childByAutoId()
        
        // Set wishlist ID
        wishlist.id = wishlistRef.key
        
        var wishlistData: [String: Any] = ["id": wishlist.id!, "name": wishlist.name]
        if let listCover = wishlist.coverImage {
            // Convert image data to base64-encoded string
            if let imageData = listCover.jpegData(compressionQuality: 0.5) {
                let base64String = imageData.base64EncodedString()
                wishlistData["listCoverBase64"] = base64String
            }
        }
        wishlistRef.setValue(wishlistData)
    }
    
    func loadListsFromFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let wishlistRef = ref.child("users").child(userId).child("wishlists")

        wishlistRef.observe(.value) { [weak self] (snapshot) in
            guard let self = self else { return }
            var loadedWishlists = [Wishlist]()
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                    let wishlistData = snapshot.value as? [String: Any],
                    let id = wishlistData["id"] as? String,
                    let name = wishlistData["name"] as? String,
                    let base64String = wishlistData["listCoverBase64"] as? String,
                    let imageData = Data(base64Encoded: base64String),
                    let coverImage = UIImage(data: imageData) {
    
                    let wishlist = Wishlist(id: id, coverImage: coverImage, name: name)
                    loadedWishlists.append(wishlist)
                }
            }
            
            self.wishlists = loadedWishlists
            self.collectionView.reloadData()
        }
    }
    
    func deleteWishlistFromFirebase(_ wishlist: Wishlist) {
        guard let userId = Auth.auth().currentUser?.uid, let wishlistId = wishlist.id else { return }
        let wishlistRef = ref.child("users").child(userId).child("wishlists").child(wishlistId)

        wishlistRef.removeValue()
    }
}

