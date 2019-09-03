//
//  ProductFilterPickerTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ProductFilterPickerTableViewController: PickerTableViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var currentCategoryName: String?
    private var needsCheckPreselection = false
    private var categoryNameList: CategoryNameList!
    private var handles: [Any]?
    private var getCountsOperation: ConcurrentTaskOperation<GetCategoryCountOperation>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localized.titles.filter
        categoryNameList = CategoryNameList(session: userSession)
        var handles = [Any]()
        handles.append(categoryNameList.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleListUpdate()
            }
        })
        handles.append(categoryNameList.addFetchingFailureHandler({[weak self] (error) in
            OperationQueue.main.addOperation {
                self?.handleUpdateFailure(error)
            }
        }))
        self.handles = handles
        needsCheckPreselection = currentCategoryName != nil
        categoryNameList.reload()
    }
    
    private func handleListUpdate() {
        options = categoryNameList.items.map{CategoryNameViewModel($0)}
        if needsCheckPreselection,
            let name = currentCategoryName,
            let index = categoryNameList.items.firstIndex(where: {$0.name.lowercased() == name.lowercased()}) {
            needsCheckPreselection = false
            selection = options[index]
            setNeedsPreselect()
        }
        if options.isEmpty {
            updateViewsForListUpdate()
        } else {
            getCounts()
        }
    }
    
    private func updateViewsForListUpdate() {
        tableView.reloadData()
        updateBackground()
    }
    
    private func getCounts() {
        getCountsOperation?.cancel()
        let ops = categoryNameList.items.map{GetCategoryCountOperation(categoryName: $0, userSession: userSession)}
        let op = ConcurrentTaskOperation<GetCategoryCountOperation>(operations: ops)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetCounts()
            }
        }
        options = categoryNameList.items.map{CategoryNameViewModel($0)}
        getCountsOperation = op
        op.start()
    }
    
    private func didGetCounts() {
        getCountsOperation = nil
        updateViewsForListUpdate()
    }
    
    private func handleUpdateFailure(_ error: Error?) {
        if options.isEmpty { return }
        updateBackground(with: error)
    }
    
    private func updateBackground(with error: Error? = nil) {
        if options.isEmpty {
            tableView.tableFooterView = nil
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return options.isEmpty ? 0 : 1
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isLast = indexPath.row == (options.count - 1)
        if isLast {
            categoryNameList.loadMoreIfAllowed()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 116
    }
}

class CategoryNameViewModel: PickerItemDisplayable {
    let categoryName: CategoryName
    var mainTitle: String {
        return categoryName.name
    }
    var detailTitle: String? {
        return SharedNumberFormatters.integer.string(for: categoryName.count)
    }
    
    func isEqual(to item: PickerItemDisplayable) -> Bool {
        guard let item = item as? CategoryNameViewModel else {
            return false
        }
        return categoryName.name == item.categoryName.name
    }
    
    init(_ category: CategoryName) {
        self.categoryName = category
    }
}
