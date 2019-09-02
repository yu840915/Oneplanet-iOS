//
//  PickerTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/17.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

protocol PickerItemDisplayable {
    var mainTitle: String {get}
    var detailTitle: String? {get}
    func isEqual(to item: PickerItemDisplayable) -> Bool
}

class PickerTableViewController: UITableViewController {
    var options: [PickerItemDisplayable] = []
    var selection: PickerItemDisplayable? {
        didSet {
            commitButton?.isEnabled = (selection != nil)
        }
    }
    var didSelectItem: ((PickerItemDisplayable)->())?
    @IBOutlet weak var exitButtonItem: UIBarButtonItem!
    weak var commitButton: UIButton?
    private var shouldPreselect = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(PickerConfirmButtonFooter.defaultNib(), forHeaderFooterViewReuseIdentifier: ReuseID.footer)
        exitButtonItem.title = Localized.titles.cancel
        shouldPreselect = selection != nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationBarStyle.darkGray.configure(navigationController!.navigationBar)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preselectIfNeeded()
    }
    
    func setNeedsPreselect() {
        shouldPreselect = true
    }
    
    @IBAction func exit(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:  ReuseID.cell, for: indexPath) as! PickerItemCell
        cell.updateViews(with: options[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseID.footer) as! PickerConfirmButtonFooter
        view.commitAction = {[weak self] in
            self?.commitSelection()
        }
        commitButton = view.commitButton
        commitButton?.isEnabled = (selection != nil)
        return view
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selection = options[indexPath.row]
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.isSelected = true
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.isSelected = false
        }
    }
}

private extension PickerTableViewController {
    func preselectIfNeeded() {
        guard shouldPreselect && tableView.numberOfSections > 0 else {
            return
        }
        shouldPreselect = false
        guard let sel = selection,
            let idx = options.firstIndex(where: {$0.isEqual(to: sel)}) else {
            return
        }
        let indexPath = IndexPath(row: idx, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.isSelected = true
        }
    }
    
    func commitSelection() {
        if let sel = selection {
            didSelectItem?(sel)
            dismiss(animated: true, completion: nil)
        }
    }
}

extension PickerTableViewController {
    struct ReuseID {
        static let cell = "itemCell"
        static let footer = "footer"
    }
}

class PickerItemCell: UITableViewCell {
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var checkmark: UIImageView!
    private var separator: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = UIView()
        let view = UIView()
        view.layer.borderWidth = 0.5
        view.layer.borderColor = ColorPalette.defaultPlaceholder.cgColor
        contentView.addSubview(view)
        separator = view
    }
    
    override func layoutSubviews() {
        var rect = bounds
        rect.origin.y = rect.height - 0.5
        rect.origin.x = 20
        rect.size.height = 0.5
        separator.frame = rect
        super.layoutSubviews()
    }
    
    override var isSelected: Bool {
        didSet {
            checkmark.isHidden = !isSelected
        }
    }
}

extension PickerItemCell {
    func updateViews(with dataSource: PickerItemDisplayable) {
        mainLabel.text = dataSource.mainTitle
        if let detail = dataSource.detailTitle {
            detailLabel.text = detail
            detailLabel.isHidden = false
        } else {
            detailLabel.isHidden = true
        }
    }
}
