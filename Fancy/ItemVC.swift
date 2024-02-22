//
//  ItemVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/22/23.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import SafariServices

class ItemVC: BaseViewController {

    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemPrice: UILabel!
    @IBOutlet weak var itemNote: UITextView!
    @IBOutlet weak var itemLinkButton: UIButton!
    @IBOutlet weak var noteTitle: UILabel!
    
    var chosenItem: WishlistItem?
    var chosenWishlist: Wishlist?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // To reload data after editing item
        loadDataFromFirebase()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Round corners of item image
        itemImage.layer.cornerRadius = 15
        itemImage.layer.masksToBounds = true
        
        // Set item name, image, price
        itemName.adjustsFontSizeToFitWidth = true
        itemName.text = chosenItem?.name
        itemImage.image = chosenItem?.coverImage
        itemPrice.text = chosenItem?.price
        
        // Underline noteTitle
        noteTitle.attributedText = NSAttributedString(string: "Notes", attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        
        // Create UITextView for item note
        itemNote.text = chosenItem?.note
        itemNote.font = UIFont.systemFont(ofSize: 18)
        itemNote.isEditable = false
        itemNote.isScrollEnabled = true
        
        // Check if there's a link
        if chosenItem?.link == nil {
            // If there's no link, disable button and set alpha to indicate it's not pressable
            itemLinkButton.isEnabled = false
            itemLinkButton.alpha = 0.5
        } else {
            // If there's a link, enable button
            itemLinkButton.isEnabled = true
            itemLinkButton.alpha = 1.0
        }
    }

    @IBAction func itemLinkButton(_ sender: Any) {
        // Take user to webpage
        if let link = chosenItem?.link {
            if UserDefaults.standard.bool(forKey: "openLinksInApp") {
                // Open link in view controller within app
                let safariViewController = SFSafariViewController(url: link)
                present(safariViewController, animated: true, completion: nil)
            } else {
                // Open link directly in Safari
                UIApplication.shared.open(link, options: [:], completionHandler: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue from Edit Button to EditItemVC
        if segue.identifier == "EditItemIdentifier",
           let nextVC = segue.destination as? EditItemVC
        {
            nextVC.chosenItem = chosenItem
            nextVC.chosenWishlist = chosenWishlist
        }
    }
    
    func loadDataFromFirebase() {
        guard let userId = Auth.auth().currentUser?.uid,
              let wishlistId = chosenWishlist?.id,
              let itemId = chosenItem?.id else { return }
        
        // Reference to Firebase database
        let ref = Database.database().reference()

        // Reference to specific item
        let itemRef = ref.child("users").child(userId).child("wishlists").child(wishlistId).child("items").child(itemId)

        itemRef.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let self = self, let itemData = snapshot.value as? [String: Any] else { return }
                
            // Update item name, price, and note
            self.itemName.text = itemData["name"] as? String
            self.itemPrice.text = itemData["price"] as? String
            self.itemNote.text = itemData["note"] as? String
            
            // Update image
            if let itemImageBase64 = itemData["itemImageBase64"] as? String,
                let imageData = Data(base64Encoded: itemImageBase64) {
                self.itemImage.image = UIImage(data: imageData)
            }

            // Check if there's a link
            if itemData["link"] == nil {
                // If there's no link, disable button and set alpha to indicate it's not pressable
                self.itemLinkButton.isEnabled = false
                self.itemLinkButton.alpha = 0.5
            } else {
                // If there's a link, enable button
                self.itemLinkButton.isEnabled = true
                self.itemLinkButton.alpha = 1.0
            }
        }
    }
}
