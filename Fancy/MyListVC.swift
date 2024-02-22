//
//  MyListVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/18/23.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class MyListVC: BaseViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, ItemAdder {
    
    @IBOutlet weak var listName: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var ref: DatabaseReference!
    var chosenWishlist: Wishlist?
    var items = [WishlistItem]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadItemsFromFirebase()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set wishlist name
        listName.adjustsFontSizeToFitWidth = true
        listName.text = chosenWishlist?.name
        
        // Set up Firebase
        ref = Database.database().reference()
        loadItemsFromFirebase()
        
        // Set up collection view
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 175, height: 221)
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
        // Long press triggers action sheet for item deletion
        if gesture.state == .began {
            let touchPoint = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: touchPoint) {
                presentDeleteItemActionSheet(for: indexPath)
            }
        }
    }
    
    func presentDeleteItemActionSheet(for indexPath: IndexPath) {
        // Create action sheet for item deletion
        let actionSheet = UIAlertController(title: "Delete item", message: nil, preferredStyle: .actionSheet)

        // Add delete option
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            // Get the selected item
            let itemToDelete = self.items[indexPath.item]
            
            // Remove item from collection
            self.items.remove(at: indexPath.item)
            self.collectionView.deleteItems(at: [indexPath])
            
            // Remove the item from Firebase
            self.deleteItemFromFirebase(itemToDelete)
        }
        actionSheet.addAction(deleteAction)

        // Add cancel option
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue from Add Button to CreateItemVC
        if segue.identifier == "CreateItemIdentifier",
           let nextVC = segue.destination as? CreateItemVC
        {
            nextVC.delegate = self
        }
        // Segue from ItemViewCell to ItemVC
        else if segue.identifier == "ItemIdentifier",
            let nextVC = segue.destination as? ItemVC,
            let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first
        {
            let selectedItem = items[selectedIndexPath.row]
            nextVC.chosenItem = selectedItem
            nextVC.chosenWishlist = chosenWishlist
        }
    }
    
    func addCreatedItem(newItem: WishlistItem) {
        self.items.append(newItem)
        self.saveItemToFirebase(newItem)
        self.collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as! ItemViewCell
        
        let item = items[indexPath.row]
        cell.itemName.adjustsFontSizeToFitWidth = true
        cell.itemName.text = item.name
        cell.itemPrice.text = item.price
        cell.itemCover.image = item.coverImage
        cell.itemCover.contentMode = .scaleAspectFill
        cell.itemCover.layer.cornerRadius = 15
        cell.itemCover.layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func saveItemToFirebase(_ wishlistItem: WishlistItem) {
        guard let userId = Auth.auth().currentUser?.uid,
              let wishlistId = chosenWishlist?.id else { return }

        let itemsRef = ref.child("users").child(userId).child("wishlists").child(wishlistId).child("items").childByAutoId()
        
        // Set item ID
        wishlistItem.id = itemsRef.key

        var itemData: [String: Any] = [
            "id": wishlistItem.id!,
            "name": wishlistItem.name,
            "price": wishlistItem.price,
            "note": wishlistItem.note ?? "",
            "claimId": wishlistItem.claimId!
        ]

        if let itemImage = wishlistItem.coverImage {
            if let imageData = itemImage.jpegData(compressionQuality: 0.5) {
                let base64String = imageData.base64EncodedString()
                itemData["itemImageBase64"] = base64String
            }
        }

        if let itemLink = wishlistItem.link {
            itemData["link"] = itemLink.absoluteString
        }

        itemsRef.setValue(itemData)
    }

    
    func loadItemsFromFirebase() {
        guard let userId = Auth.auth().currentUser?.uid,
              let wishlistId = chosenWishlist?.id else { return }
            
        
        // Reference to items
        let itemsRef = ref.child("users").child(userId).child("wishlists").child(wishlistId).child("items")

        itemsRef.observe(.value) { [weak self] (snapshot)  in
            guard let self = self else { return }
            var loadedItems = [WishlistItem]()

            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let itemData = snapshot.value as? [String: Any],
                   let itemId = itemData["id"] as? String,
                   let itemName = itemData["name"] as? String,
                   let itemPrice = itemData["price"] as? String,
                   let itemNote = itemData["note"] as? String,
                   let claimId = itemData["claimId"] as? String {
                    
                    var itemImage: UIImage?
                    if let itemImageBase64 = itemData["itemImageBase64"] as? String,
                        let imageData = Data(base64Encoded: itemImageBase64) {
                        itemImage = UIImage(data: imageData)
                    }

                    var itemLink: URL?
                    if let itemLinkString = itemData["link"] as? String {
                        itemLink = URL(string: itemLinkString)
                    }

                    let wishlistItem = WishlistItem(id: itemId, coverImage: itemImage, name: itemName, price: itemPrice, link: itemLink, note: itemNote, claimId: claimId)
                    loadedItems.append(wishlistItem)
                }
            }

            self.items = loadedItems
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func deleteItemFromFirebase(_ wishlistItem: WishlistItem) {
        guard let userId = Auth.auth().currentUser?.uid,
              let wishlistId = chosenWishlist?.id,
              let itemId = wishlistItem.id else {
            return
        }

        let itemsRef = ref.child("users").child(userId).child("wishlists").child(wishlistId).child("items").child(itemId)

        itemsRef.removeValue()
    }
}
