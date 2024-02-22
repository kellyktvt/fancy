//
//  FriendItemVC.swift
//  Fancy
//
//  Created by Kelly T. on 11/26/23.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SafariServices

class FriendItemVC: BaseViewController {
    
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemPrice: UILabel!
    @IBOutlet weak var noteTitle: UILabel!
    @IBOutlet weak var itemNote: UITextView!
    @IBOutlet weak var itemLinkButton: UIButton!
    @IBOutlet weak var claimButton: UIButton!
    
    let userId = Auth.auth().currentUser?.uid
    
    var chosenFriend: String?
    var chosenWishlist: Wishlist?
    var chosenItem: WishlistItem?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
            // If no link, disable button and set alpha to indicate it's not pressable
            itemLinkButton.isEnabled = false
            itemLinkButton.alpha = 0.5
        } else {
            // If link, enable button
            itemLinkButton.isEnabled = true
            itemLinkButton.alpha = 1.0
        }
        
        // Set claimButton image
        if chosenItem?.claimId == "unclaimed" {
            claimButton.setImage(UIImage(named: "OpenGift"), for: .normal)
        } else if chosenItem?.claimId == userId {
            claimButton.setImage(UIImage(named: "YourGift"), for: .normal)
        } else {
            claimButton.setImage(UIImage(named: "OtherGift"), for: .normal)
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
    
    @IBAction func claimButton(_ sender: Any) {
        guard let friendId = chosenFriend,
              let wishlistId = chosenWishlist?.id,
              let itemId = chosenItem?.id else { return }
        
        // Reference to friend's items
        let itemRef = Database.database().reference().child("users").child(friendId).child("wishlists").child(wishlistId).child("items").child(itemId)
          
        // claim the gift
        if chosenItem?.claimId == "unclaimed" {
            chosenItem?.claimId = userId
            claimButton.setImage(UIImage(named: "YourGift"), for: .normal)
            
            // Update claimId in Firebase
            itemRef.child("claimId").setValue(userId)
            
            // Show alert for claiming
            showAlert(title: "Gift Claimed", message: "You have claimed this gift.")
            return
        }
        
        // unclaim the gift
        if chosenItem?.claimId == userId {
            chosenItem?.claimId = "unclaimed"
            claimButton.setImage(UIImage(named: "OpenGift"), for: .normal)
            
            // Update claimId in Firebase
            itemRef.child("claimId").setValue("unclaimed")
            
            // Show alert for unclaiming
            showAlert(title: "Gift Unclaimed", message: "You have unclaimed this gift.")
            return
        }
        
        // Show alert for inability to claim
        showAlert(title: "Cannot Claim Gift", message: "This gift has been claimed by another user.")
    }
    
    func showAlert(title: String, message: String) {
        // Create alert for pressing claim button
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add OK option
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(controller, animated: true, completion: nil)
    }
}
