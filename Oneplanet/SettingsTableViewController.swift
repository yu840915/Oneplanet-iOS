//
//  SettingsTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/16.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, UserSessionDepending {
    
    var sections: [Section] = [Section(type: .logout, rows: [.logOut])]
    var userSession: UserSession!
    @IBOutlet weak var dismissButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
        prepareSections()
    }
    
    private func prepareSections() {
        if userSession.isGuest {
            sections = [
                Section(type: .privacyAndSecurity, rows: [.terms, .biddingTerms]),
                Section(type: .logout, rows: [.logOut])
            ]
        } else {
            sections = [
                Section(type: .account, rows: [.editProfile]),
                Section(type: .privacyAndSecurity, rows: [.blockList, .terms, .biddingTerms]),
                Section(type: .logout, rows: [.logOut])
            ]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationBarStyle.darkGrey.configure(navigationController!.navigationBar)
    }
    
    private func localizeTitles() {
        title = Localized.titles.more
        dismissButtonItem.title = Localized.titles.cancel
    }

    @IBAction func exit(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let row = sections[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = row.displayName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section].rows[indexPath.row] {
        case .editProfile, .blockList, .terms, .biddingTerms: break
        case .logOut:
            showLogOutAlert()
        }
    }
    
    private func showLogOutAlert() {
        let alert = UIAlertController(title: "Log Out?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: .default, handler: {[weak self] (_) in
            self?.userSession.deactivate()
        }))
        alert.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}

extension SettingsTableViewController {
    enum ActionRow {
        case logOut
        case editProfile
        case blockList
        case terms
        case biddingTerms
        var displayName: String {
            switch self {
            case .logOut: return Localized.titles.logOut
            case .editProfile: return Localized.phrases.editProfile
            case .blockList: return Localized.phrases.blockList
            case .terms: return Localized.titles.tos
            case .biddingTerms: return Localized.titles.biddingTerms
            }
        }
    }
    
    enum SectionType {
        case account
        case privacyAndSecurity
        case logout
        
        var displayName: String {
            switch self {
            case .account: return Localized.titles.account
            case .privacyAndSecurity: return Localized.phrases.privacyAndSecurity
            case .logout: return Localized.titles.logOut
            }
        }
    }
    
    class Section {
        let type: SectionType
        let rows: [ActionRow]
        init(type: SectionType, rows: [ActionRow]) {
            self.type = type
            self.rows = rows
        }
    }
}
