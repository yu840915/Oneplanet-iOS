//
//  UserSearchTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/3.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class UserSearchTableViewController: UITableViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var userList: UserList?
    var users: [User] = []
    var sections: [Section] = []
    var inputCoalescer: InputCoalescer!
    private var query: String = ""
    private var listUpdateHandles: [Any]?
    
    private var searchBar: UISearchBar!
    @IBOutlet weak var cancelButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        prepareSearchBar()
        inputCoalescer = InputCoalescer(task: {[weak self] in
            self?.beginSearchIfNeeded()
        })
    }
    
    private func prepareSearchBar() {
        let bar = UISearchBar()
        bar.showsCancelButton = false
        bar.searchBarStyle = .minimal
        bar.barStyle = .black
        bar.tintColor = ColorPalette.buttonGreen
        if let field = bar.value(forKey: "searchField") as? UITextField {
            field.textColor = ColorPalette.defaultText
        }
        bar.setImage(UIImage(named: "ic_search_nor"), for: .search, state: .normal)
        bar.delegate = self
        searchBar = bar
        navigationItem.titleView = bar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationBarStyle.darkGray.configure(navigationController!.navigationBar)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.endEditing(false)
    }

    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        inputCoalescer.cancel()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .content: return users.count
        case .loading: return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: section.reuseID, for: indexPath)
        switch section {
        case .content:
            prepareContentCell(cell as! UserOverviewCell, at: indexPath)
        case .loading: break
        }
        return cell
    }
    
    private func prepareContentCell(_ cell: UserOverviewCell, at indexPath: IndexPath) {
        let user = users[indexPath.row]
        cell.updateViews(with: FriendshipOverviewModel(profile: user))
        cell.actionButton.isHidden = true
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .content:
            let isLastRow = indexPath.row == (users.count - 1)
            if isLastRow && userList?.hasMore == true {
                userList?.loadMoreIfAllowed()
            }
        case .loading:
            (cell as! LoadingCell).activityIndicator.startAnimating()
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section] == .content
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: SegueID.showProfile, sender: users[indexPath.row])
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserProfileViewController {
            vc.userSession = userSession
            vc.profile = (sender as! User)
        }
    }

}

extension UserSearchTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        inputCoalescer.reschedule()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        beginSearchIfNeeded()
    }
}

private extension UserSearchTableViewController {
    func beginSearchIfNeeded() {
        updatePostLists(with: searchBar.text)
    }
    
    func updatePostLists(with query: String?) {
        if let q = query, !q.isEmpty {
            self.query = q
            userList = UserList.searchList(with: userSession, query: q)
            prepareForList()
        } else {
            clearList()
        }
    }

    func clearList() {
        query = ""
        userList = nil
        listUpdateHandles = nil
        users = []
        prepareSections()
        updateBackground()
    }
    
    func prepareForList() {
        guard let list = userList else {return}
        var handles = [Any]()
        handles.append(list.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleListUpdate()
            }
        })
        handles.append(list.addFetchingFailureHandler({[weak self] (error) in
            OperationQueue.main.addOperation {
                self?.handleFetchFailure(with: error)
            }
        }))
        listUpdateHandles = handles
        list.reload()
    }
    
    func handleFetchFailure(with error: Error?) {
        updateBackground(with: error)
    }
    
    func handleListUpdate() {
        users = userList?.items ?? []
        prepareSections()
        updateBackground()
    }
    
    func prepareSections() {
        let hasContent = !users.isEmpty
        let hasMore = userList?.hasMore ?? false
        var val: [Section] = [.content]
        if hasContent && hasMore {
            val.append(.loading)
        }
        sections = val
        tableView.reloadData()
    }
    
    func updateBackground(with error: Error? = nil) {
        if !users.isEmpty || userList == nil {
            tableView.backgroundView = nil
        } else {
            let view = CommonViewFactory.shared.makeSimpleEmptyView()
            view.titleLabel.text = String(format: Localized.messageFormats.noSearchResults, query)
            if let error = error {
                view.detailLabel.text = error.localizedDescription
            }
            tableView.backgroundView = view
        }
    }

}

extension UserSearchTableViewController {
    enum Section: String {
        case content = "cell"
        case loading = "loadingCell"
        var reuseID: String {
            return rawValue
        }
    }
    
    struct SegueID {
        static let showProfile = "showProfile"
    }
}

class InputCoalescer {
    let task: ()->()
    let delay: TimeInterval = 0.3
    private weak var timer: Timer?
    
    init(task: @escaping ()->()) {
        self.task = task
    }
    
    deinit {
        cancel()
    }
    
    func reschedule() {
        cancel()
        OperationQueue.main.addOperation {[weak self] in
            self?.prepareTimer()
        }
    }
    
    private func prepareTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) {[weak self] (_) in
            self?.fire()
        }
    }
    
    private func fire() {
        self.task()
    }
    
    func cancel() {
        timer?.invalidate()
    }
}
