//
//  ProductListTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/8.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class ProductListTableViewController: UITableViewController, DefaultInstanceFactory {
    
    @IBOutlet weak var countDownView: CountDownClockView!
    private var refreshClock: UpdateClock!
    
    class func fromDefaultStoryboard() -> ProductListTableViewController {
        return UIStoryboard(name: "Auction", bundle: nil).instantiateViewController(withIdentifier: "ProductListTableViewController") as! ProductListTableViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshClock = UpdateClock(preferredFrameRate: 15, onTick: {[weak self] in
            self?.refreshDynamicViews()
        })
    }
    
    private func refreshDynamicViews() {
        countDownView.tick()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ProductListTableViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Commodities")
    }
}

class ProductOverviewCell: UITableViewCell {
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var lockLabel: UILabel!
    var isLocked = true {
        didSet {
            if oldValue != isLocked {
                updateViewsForLockState()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateViewsForLockState()
    }
    
    private func updateViewsForLockState() {
        let appearance = isLocked ? LockAppearance.forLocked : LockAppearance.forUnlocked
        titleLabel.text = appearance.title
        titleLabel.textColor = appearance.color
        lockButton.isEnabled = isLocked
    }
}

extension ProductOverviewCell {
    class LockAppearance {
        let title: String
        let color: UIColor
        init(title: String, color: UIColor) {
            self.title = title
            self.color = color
        }
        static let forLocked = LockAppearance(title: Localized.titles.unlock, color: ColorPalette.lockRed)
        static let forUnlocked = LockAppearance(title: Localized.titles.unlocked, color: ColorPalette.lockGreen)
    }
}

class BiddingProductCell: UITableViewCell {
    @IBOutlet weak var previewImageView: UIImageView!

}

class CountDownClockView: UIView {
    @IBOutlet weak var dayValueLabel: UILabel!
    @IBOutlet weak var hourValueLabel: UILabel!
    @IBOutlet weak var minuteValueLabel: UILabel!
    @IBOutlet weak var secondValueLabel: UILabel!
    
    var deadline = Date(timeIntervalSinceNow: 1 * .minute + 1)
    private var attributes: [NSAttributedString.Key: Any] = [:]
    let extractor: TimeIntervalComponentExtractor = {
        let sec = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        let min = TimeIntervalComponentExtractor(unitInterval: .minute, next: sec)
        let hour = TimeIntervalComponentExtractor(unitInterval: .hour, next: min)
        return TimeIntervalComponentExtractor(unitInterval: .day, next: hour)
    }()
    let formatter: NumberFormatter = {
        let result = NumberFormatter()
        result.numberStyle = .decimal
        result.minimumIntegerDigits = 2
        result.maximumFractionDigits = 0
        return result
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        attributes = [.kern: 4.67]
    }
    
    func tick() {
        let comps = TimeIntervalComponents(extractor.extract(from: deadline.timeIntervalSinceNow))
        dayValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.days) ?? "00", attributes: attributes)
        hourValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.hours) ?? "00", attributes: attributes)
        minuteValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.minutes) ?? "00", attributes: attributes)
        secondValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.seconds) ?? "00", attributes: attributes)
    }
}
