//
//  WishlistItem.swift
//  Fancy
//
//  Created by Kelly T. on 11/20/23.
//

import UIKit

class WishlistItem {
    var id: String?
    var coverImage: UIImage?
    var name: String
    var price: String
    var link: URL?
    var note: String?
    var claimId: String?

    init(id: String?, coverImage: UIImage?, name: String, price: String, link: URL?, note: String?, claimId: String?) {
        self.id = id
        self.coverImage = coverImage
        self.name = name
        self.price = price
        self.link = link
        self.note = note
        self.claimId = claimId
    }
}
