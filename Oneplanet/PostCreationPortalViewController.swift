//
//  PostCreationPortalViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/4.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PostCreationPortalViewController: UIViewController {

    @IBOutlet weak var valuedPhotoLabel: UILabel!
    @IBOutlet weak var valuedPhotoCapacityLabel: UILabel!
    @IBOutlet weak var freePhotoLabel: UILabel!
    private var capacity: PhotoUploadCapacity? = PhotoUploadCapacity()
    private var refreshClock: UpdateClock!
    let extractor: TimeIntervalComponentExtractor = {
        let sec = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        let min = TimeIntervalComponentExtractor(unitInterval: .minute, next: sec)
        return TimeIntervalComponentExtractor(unitInterval: .hour, next: min)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        valuedPhotoLabel.text = Localized.phrases.uploadValuedPhoto
        freePhotoLabel.text = Localized.phrases.uploadFreePhoto
        refreshClock = UpdateClock(onTick: {[weak self] in
            self?.updatePhotoCapacityLabel()
        })
    }
    
    func updatePhotoCapacityLabel() {
        guard let cap = capacity else {
            valuedPhotoCapacityLabel.text = "–"
            return
        }
        let formatter = SharedNumberFormatters.integer
        let time: String
        if let date = cap.nextRefillTime {
            let comp = TimeIntervalComponents(extractor.extract(from: date.timeIntervalSinceNow))
            var val = ""
            if comp.hours > 0 {
                val += SharedNumberFormatters.clockComponent.string(for: comp.hours)!
                val += ":"
            }
            val += SharedNumberFormatters.clockComponent.string(for: comp.minutes)!
            val += ":"
            val += SharedNumberFormatters.clockComponent.string(for: comp.seconds)!
            time = val
        } else {
            time = Localized.phrases.noRoomForPhoto
        }
        valuedPhotoCapacityLabel.text = String(format: Localized.phraseFormats.remainingUploads, formatter.string(for: cap.available)!, formatter.string(for: cap.total)!, time)
    }
    

    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}

class PhotoUploadCapacity {
    let available: Int = 9
    let total: Int = 10
    let nextRefillTime: Date? = Date(timeIntervalSinceNow: .hour)
}
