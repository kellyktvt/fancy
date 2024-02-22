//
//  BaseViewController.swift
//  Fancy
//
//  Created by Kelly T. on 11/26/23.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        applyDarkModeAppearance()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyDarkModeAppearance()
    }
    
    @IBAction func darkModeSwitchChanged(_ sender: UISwitch) {
        // Save dark mode setting to UserDefaults
        UserDefaults.standard.set(sender.isOn, forKey: "darkMode")

        // Apply dark mode
        applyDarkModeAppearance()
    }

    func applyDarkModeAppearance() {
        let isDarkModeEnabled = UserDefaults.standard.bool(forKey: "darkMode")
        overrideUserInterfaceStyle = isDarkModeEnabled ? .dark : .light
    }
}
