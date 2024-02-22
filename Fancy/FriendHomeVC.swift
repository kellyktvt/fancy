//
//  FriendHomeVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/26/23.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class FriendHomeVC: BaseViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var pfp: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var ref: DatabaseReference!
    var chosenFriend: String?
    var wishlists = [Wishlist]()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up Firebase
        ref = Database.database().reference()
        loadListsFromFirebase()
        
        // Make PFP a circle
        pfp.layer.cornerRadius = pfp.frame.size.width / 2.0
        pfp.layer.masksToBounds = true
        
        // Load PFP and name for nameLabel
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
            
            //Load name
            if let friendName = friendData["name"] as? String {
                self.nameLabel.text = "\(friendName)'s Lists"
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue from ListViewCell to MyListVC
        if segue.identifier == "FriendListIdentifier",
            let nextVC = segue.destination as? FriendListVC,
            let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first
        {
            let selectedWishlist = wishlists[selectedIndexPath.row]
            nextVC.chosenWishlist = selectedWishlist
            nextVC.chosenFriend = chosenFriend
        }
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
    
    func loadListsFromFirebase() {
        guard let friendId = chosenFriend else { return }
        let wishlistRef = ref.child("users").child(friendId).child("wishlists")

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
}
