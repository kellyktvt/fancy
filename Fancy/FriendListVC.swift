//
//  FriendListVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/26/23.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class FriendListVC: BaseViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var pfp: UIImageView!
    @IBOutlet weak var listName: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var ref: DatabaseReference!
    var chosenFriend: String?
    var chosenWishlist: Wishlist?
    var items = [WishlistItem]()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set wishlist name
        listName.adjustsFontSizeToFitWidth = true
        listName.text = chosenWishlist?.name
        
        // Set up Firebase
        ref = Database.database().reference()
        loadItemsFromFirebase()
        
        // Make PFP a circle
        pfp.layer.cornerRadius = pfp.frame.size.width / 2.0
        pfp.layer.masksToBounds = true
        
        // Load PFP
        let friendRef = ref.child("users").child(chosenFriend!)
        friendRef.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let self = self, let friendData = snapshot.value as? [String: Any] else { return }

            // Load PFP
            if let base64String = friendData["pfpBase64"] as? String,
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
        layout.itemSize = CGSize(width: 175, height: 221)
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.collectionViewLayout = layout
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue from ItemViewCell to FriendItemVC
        if segue.identifier == "FriendItemIdentifier",
            let nextVC = segue.destination as? FriendItemVC,
            let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first
        {
            let selectedItem = items[selectedIndexPath.row]
            nextVC.chosenItem = selectedItem
            nextVC.chosenFriend = chosenFriend
            nextVC.chosenWishlist = chosenWishlist
        }
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
        
        // Set claim foreground cover and label
        if item.claimId == Auth.auth().currentUser?.uid {
            cell.foregroundCover.image = UIImage(named: "LightBlueCover")
            cell.foregroundCover.alpha = 0.5
            cell.claimNote.text = "You claimed this"
        } else if item.claimId == "unclaimed" {
            cell.foregroundCover.image = nil
            cell.claimNote.text = ""
        } else {
            cell.foregroundCover.image = UIImage(named: "FancyBlueCover")
            cell.foregroundCover.alpha = 0.5
            cell.claimNote.text = "Someone else claimed this"
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func loadItemsFromFirebase() {
        guard let friendId = chosenFriend,
              let wishlistId = chosenWishlist?.id else { return }

        // Reference to friend's items
        let itemsRef = ref.child("users").child(friendId).child("wishlists").child(wishlistId).child("items")

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
}
