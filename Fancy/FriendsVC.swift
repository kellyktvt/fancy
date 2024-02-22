//
//  FriendsVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/26/23.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class FriendsVC: BaseViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var ref: DatabaseReference!
    var friends = [String]()
    
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
        loadFriendsFromFirebase()
        
        // Set up collection view
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 147, height: 177)
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
        // Long press triggers action sheet for friend removal
        if gesture.state == .began {
            let touchPoint = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: touchPoint) {
                presentRemoveFriendActionSheet(for: indexPath)
            }
        }
    }
    
    func presentRemoveFriendActionSheet(for indexPath: IndexPath) {
        // Create action sheet for friend deletion
        let actionSheet = UIAlertController(
            title: "Remove Friend",
            message: nil,
            preferredStyle: .actionSheet
        )

        // Add remove option
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            // Get the selected friend
            let friendToRemove = self.friends[indexPath.item]
            
            // Remove friend from collection
            self.friends.remove(at: indexPath.item)
            self.collectionView.deleteItems(at: [indexPath])
            
            // Remove the wishlist from Firebase
            self.removeFriendFromFirebase(friendToRemove)
        }
        actionSheet.addAction(removeAction)

        // Add cancel option
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func addFriendButton(_ sender: Any) {
        // Create action sheet for adding friends
        let controller = UIAlertController(title: "Add Friend", message: "Enter their friend code", preferredStyle: .alert)

        // Add cancel option
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // Add text fields
        controller.addTextField { textField in
            textField.placeholder = "Enter friend code"
        }
        
        // Add save option
        controller.addAction(UIAlertAction(title: "Add", style: .default) { (action) in
            guard let friendId = controller.textFields?[0].text, friendId != "" else {
                // Handle the case where user ID is nil
                let errorAlert = UIAlertController(title: "Error", message: "Unable to add friend.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
                return
            }
            
            // Check if the entered friend code is the user's own ID
            if friendId == Auth.auth().currentUser?.uid {
                let errorAlert = UIAlertController(title: "Error", message: "You cannot add yourself as a friend.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
                return
            }
            
            // Check if the friend is already in the friends array
            if self.friends.contains(friendId) == true {
                let errorAlert = UIAlertController(title: "Error", message: "This friend is already in your list.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
                return
            }
            
            let userId = Auth.auth().currentUser?.uid
            let friendRef = self.ref.child("users").child(friendId)

            friendRef.observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    // Friend exists, proceed with adding friend
                    self.ref.child("users").child(userId!).child("friends").child(friendId).setValue(true)
                    
                } else {
                    // Friend does not exist
                    let errorAlert = UIAlertController(title: "Error", message: "Unable to add friend", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                }
            }
        })
        
        present(controller, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendCell", for: indexPath) as! FriendViewCell
        
        let friendId = friends[indexPath.row]
        
        // Get friend's data from Firebase
        let friendRef = ref.child("users").child(friendId)
        friendRef.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let _ = self, let friendData = snapshot.value as? [String: Any] else { return }
            
            if let friendName = friendData["name"] as? String,
               let base64String = friendData["pfpBase64"] as? String,
               let imageData = Data(base64Encoded: base64String),
               let friendPFP = UIImage(data: imageData) {
                
                // Update cell UI on main thread
                DispatchQueue.main.async {
                    cell.friendName.adjustsFontSizeToFitWidth = true
                    cell.friendName.text = friendName
                    cell.friendPFP.image = friendPFP
                    cell.friendPFP.contentMode = .scaleAspectFill
                    cell.friendPFP.layer.cornerRadius = cell.friendPFP.frame.size.width / 2.0
                    cell.friendPFP.layer.masksToBounds = true
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return friends.count
    }
    
    func saveFriendToFirebase(_ friendId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let friendRef = ref.child("users").child(userId).child("friends").child(friendId)
        friendRef.setValue(true)
    }
    
    func loadFriendsFromFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let friendRef = ref.child("users").child(userId).child("friends")

        friendRef.observe(.value) { [weak self] (snapshot) in
            guard let self = self else { return }
            var loadedFriends = [String]()
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot {
                    let friendId = snapshot.key
                    loadedFriends.append(friendId)
                }
            }
            
            self.friends = loadedFriends
            self.collectionView.reloadData()
        }
    }
    
    func removeFriendFromFirebase(_ friendId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let friendRef = ref.child("users").child(userId).child("friends").child(friendId)
        friendRef.removeValue()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue from FriendViewCell to FriendListVC
        if segue.identifier == "FriendHomeIdentifier",
            let nextVC = segue.destination as? FriendHomeVC,
            let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first
        {
            let selectedFriend = friends[selectedIndexPath.row]
            nextVC.chosenFriend = selectedFriend
        }
    }
    
}
