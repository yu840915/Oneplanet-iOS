//
//  ColorPickerCollectionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

private let reuseIdentifier = "cell"

class ColorPickerCollectionViewController: UICollectionViewController {
    
    var colors: [AlienColor] = []
    var selectedColor: AlienColor?
    var didChangeSelection: ((AlienColor)->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selectItemIfNeeded()
    }
    
    private func selectItemIfNeeded() {
        if let selection = selectedColor,
            let idx = colors.index(of: selection) {
            collectionView.selectItem(at: IndexPath(row: idx, section: 0), animated: false, scrollPosition: .centeredVertically)
        }
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ColorCell
        cell.colorView.backgroundColor = colors[indexPath.row].color
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let color = colors[indexPath.row]
        selectedColor = color
        didChangeSelection?(color)
    }
}

class ColorCell: UICollectionViewCell {
    @IBOutlet weak var selectionIndicator: UIView!
    @IBOutlet weak var colorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionIndicator.layer.borderColor = UIColor.white.cgColor
        selectionIndicator.layer.borderWidth = 2
        updateRoundCorners()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateRoundCorners()
    }
    
    private func updateRoundCorners() {
        selectionIndicator.layer.cornerRadius = selectionIndicator.frame.width / 2
        colorView.layer.cornerRadius = 16
    }
    
    override var isSelected: Bool {
        didSet {
            updateForSelection()
        }
    }
    
    private func updateForSelection() {
        selectionIndicator.isHidden = !isSelected
    }
}
