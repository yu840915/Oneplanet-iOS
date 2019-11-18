//
//  ReportReasonPickerTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ReportReasonPickerTableViewController: UITableViewController {
    
    @IBOutlet weak var cancelButtonItem: UIBarButtonItem!
    @IBOutlet weak var headerLabel: UILabel!
    var didFinishReport: (()->())?
    var draft = ReportDraft()
    var flowController: ReportFlowController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localized.titles.report
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        cancelButtonItem.title = Localized.titles.cancel
        headerLabel.text = flowController.headerTitle
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        draft = ReportDraft()
        NavigationBarStyle.darkGray.configure(navigationController!.navigationBar)
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flowController.predefinedReasons.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ReportReasonCell
        cell.updateViews(with: flowController.predefinedReasons[indexPath.row])
        return cell
    }

    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return tableView.indexPathsForSelectedRows?.isEmpty == false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReportDescriptionInputViewController {
            let index = tableView.indexPathsForSelectedRows!.first!
            let reason = flowController.predefinedReasons[index.row]
            draft.reason = reason
            vc.flowController = flowController
            vc.draft = draft
            vc.didFinishReport = {[weak self] in
                self?.didFinishReport?()
            }
        }
    }

}

class ReportReasonCell: UITableViewCell {
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = CommonViewFactory.shared.makeSelectionBackground()
    }
    
    func updateViews(with reason: ReportDraft.Reason) {
        mainLabel.text = reason.title
        detailLabel.isHidden = reason.subtitle.isEmpty
        detailLabel.text = reason.subtitle
    }
}
