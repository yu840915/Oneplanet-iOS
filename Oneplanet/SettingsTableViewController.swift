//
//  SettingsTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/16.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, UserSessionDepending {
    
    @IBOutlet weak var versionLabel: UILabel!
    var sections: [Section] = [Section(type: .logout, rows: [.logOut])]
    var userSession: UserSession!
    @IBOutlet weak var dismissButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SectionHeaderView.defaultNib(), forHeaderFooterViewReuseIdentifier: ReuseID.header)
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
        versionLabel.text = String(format: Localized.messageFormats.version, ServiceConstants.appVersionString)
    }

    @IBAction func showEmailComposer(_ sender: Any) {
        UIApplication.shared.open(URL(string: "message://")!, options: [:], completionHandler: nil)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.cell, for: indexPath)
        let row = sections[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = row.displayName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let result = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseID.header) as! SectionHeaderView
        result.titleLabel.text = sections[section].displayName
        result.separator.isHidden =  section == 0
        return result
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section].rows[indexPath.row] {
        case .editProfile, .blockList: break
        case .biddingTerms:
            performSegue(withIdentifier: SegueID.showBiddingTerms, sender: nil)
        case .terms:
            performSegue(withIdentifier: SegueID.showTerms, sender: nil)
        case .logOut:
            showLogOutAlert()
        }
    }
    
    private func showLogOutAlert() {
        let alert = UIAlertController(title: Localized.warnings.logout, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.logOut, style: .default, handler: {[weak self] (_) in
            self?.userSession.deactivate()
        }))
        alert.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController, let vc = nav.viewControllers.first as? WebViewController {
            NavigationBarStyle.darkGrey.configure(nav.navigationBar)
            if segue.identifier == SegueID.showBiddingTerms {
                vc.request = URLRequest(url: ServiceURLs.biddingTerms)
                vc.title = ActionRow.biddingTerms.displayName
            } else {
                var req = URLRequest(url: ServiceURLs.terms)
                req.addValue(Localized.languageCode, forHTTPHeaderField: Localized.acceptLanguageKey)
                vc.request = req
                vc.title = ActionRow.terms.displayName
            }
        }
    }

}

extension SettingsTableViewController {
    struct ReuseID {
        static let cell = "cell"
        static let header = "header"
    }
    struct SegueID {
        static let showTerms = "showTerms"
        static let showBiddingTerms = "showBiddingTerms"
    }
    
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
        var displayName: String { return type.displayName }
    }
}
