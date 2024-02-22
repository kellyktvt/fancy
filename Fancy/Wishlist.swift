//
//  Wishlist.swift
//  Fancy
//
//  Created by Kelly T. on 11/15/23.
//

import UIKit

class Wishlist {
    var id: String?
    var coverImage: UIImage?
    var name: String
    var items: [WishlistItem]
    
    init(id: String? = nil, coverImage: UIImage?, name: String, items: [WishlistItem] = []) {
        self.id = id
        self.coverImage = coverImage
        self.name = name
        self.items = items
    }
}
