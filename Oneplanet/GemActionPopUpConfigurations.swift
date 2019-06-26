//
//  GemActionPopUpConfigurations.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class GemActionPopUpConfiguration {
    let titleAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: ColorPalette.defaultText, .font: UIFont.systemFont(ofSize: 17)]
    let subtitleAttributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return [.foregroundColor: ColorPalette.defaultText,
                .font: UIFont.systemFont(ofSize: 17),
                NSAttributedString.Key.paragraphStyle: paragraphStyle]
    }()
    let boldTitleAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: ColorPalette.defaultText, .font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
    var icon: UIImage {
        return #imageLiteral(resourceName: "ic_key80_nor")
    }
    var attributedTitle: NSAttributedString {
        return NSAttributedString(string: "")
    }
    var attributedSubtitle: NSAttributedString {
        return NSAttributedString(string: "")
    }
    var actionTitle: String {
        return Localized.titles.ok
    }
    var cancelTitle: String {
        return Localized.titles.cancel
    }
    var shouldShowCancel: Bool {
        return true
    }
}

class UnlockPopUpConfiguration: GemActionPopUpConfiguration {
    let productName: String
    init(productName: String) {
        self.productName = productName
    }
    override var attributedTitle: NSAttributedString {
        let text = String(format: Localized.messageFormats.unlockWithGem, productName)
        let range = (text as NSString).range(of: productName)
        let result = NSMutableAttributedString(string: text, attributes: titleAttributes)
        result.addAttributes(boldTitleAttributes, range: range)
        return result
    }
}

class UnlockWithGreenGemPopUpConfiguration: UnlockPopUpConfiguration {
    override var icon: UIImage {
        return #imageLiteral(resourceName: "ic_key80_nor")
    }
    override var attributedSubtitle: NSAttributedString {
        return NSAttributedString(
            string: String(format: Localized.messageFormats.unlockWithGem, Localized.titles.greenGem),
            attributes: subtitleAttributes)
    }
}

class UnlockWithPurpleGemPopUpConfiguration: UnlockPopUpConfiguration {
    override var icon: UIImage {
        return #imageLiteral(resourceName: "ic_coin80_nor")
    }
    override var attributedSubtitle: NSAttributedString {
        return NSAttributedString(
            string: String(format: Localized.messageFormats.unlockWithGem, Localized.titles.purpleGem),
            attributes: subtitleAttributes)
    }
}

class UnlockWithBlueGemPopUpConfiguration: UnlockPopUpConfiguration {
    let formattedPrice: String
    init(productName: String, formattedPrice: String) {
        self.formattedPrice = formattedPrice
        super.init(productName: productName)
    }
    override var icon: UIImage {
        return #imageLiteral(resourceName: "ic_gem80_nor")
    }
    override var attributedSubtitle: NSAttributedString {
        return NSAttributedString(
            string: String(format: Localized.messageFormats.unlockWithGemAndIAP, Localized.titles.purpleGem, formattedPrice),
            attributes: subtitleAttributes)
    }
}

class BidPopUpConfiguration: GemActionPopUpConfiguration {
    let productName: String
    init(productName: String) {
        self.productName = productName
    }
    override var attributedTitle: NSAttributedString {
        let text = String(format: Localized.messageFormats.bidPrompt, productName)
        let range = (text as NSString).range(of: productName)
        let result = NSMutableAttributedString(string: text, attributes: titleAttributes)
        result.addAttributes(boldTitleAttributes, range: range)
        return result
    }
}

class BidWithPurpleGemPopUpConfiguration: UnlockPopUpConfiguration {
    override var icon: UIImage {
        return #imageLiteral(resourceName: "ic_coin80_nor")
    }
    override var attributedSubtitle: NSAttributedString {
        return NSAttributedString(
            string: String(format: Localized.messageFormats.bidWithGem, Localized.titles.purpleGem),
            attributes: subtitleAttributes)
    }
}

class BidWithBlueGemPopUpConfiguration: UnlockPopUpConfiguration {
    let formattedPrice: String
    init(productName: String, formattedPrice: String) {
        self.formattedPrice = formattedPrice
        super.init(productName: productName)
    }
    override var icon: UIImage {
        return #imageLiteral(resourceName: "ic_gem80_nor")
    }
    override var attributedSubtitle: NSAttributedString {
        return NSAttributedString(
            string: String(format: Localized.messageFormats.bidWithGemAndIAP, Localized.titles.purpleGem, formattedPrice),
            attributes: subtitleAttributes)
    }
}

class InsufficientBlueGemToUnlockPopUpConfiguration: GemActionPopUpConfiguration {
    let formattedPrice: String
    init(formattedPrice: String) {
        self.formattedPrice = formattedPrice
    }

    override var icon: UIImage {
        return #imageLiteral(resourceName: "ic_gem80_nor")
    }
    
    override var attributedTitle: NSAttributedString {
        return NSAttributedString(string: String(format: Localized.messageFormats.insufficientGem, Localized.titles.blueGem), attributes: titleAttributes)
    }
    
    override var attributedSubtitle: NSAttributedString {
        let result = NSMutableAttributedString(attributedString: descriptionPart)
        result.append(instructionPart)
        return result
    }
    
    private var descriptionPart: NSAttributedString {
        let text = String(format: Localized.messageFormats.insufficientGemToUnlockDescription, Localized.titles.blueGem, formattedPrice)
        let range = (text as NSString).range(of: Localized.titles.blueGem)
        let result = NSMutableAttributedString(string: text, attributes: subtitleAttributes)
        result.addAttributes([.link : DeepLinks.blueGemPopUp], range: range)
        return result
    }
    
    private var instructionPart: NSAttributedString {
        let text = String(format: Localized.messageFormats.earnBlueGemInstruction, Localized.titles.blueGem)
        let range = (text as NSString).range(of: Localized.titles.blueGem)
        let result = NSMutableAttributedString(string: text, attributes: subtitleAttributes)
        result.addAttributes([.link : DeepLinks.blueGemPopUp], range: range)
        return result
    }
}

class InsufficientBlueGemToBidPopUpConfiguration: GemActionPopUpConfiguration {
    let formattedPrice: String
    init(formattedPrice: String) {
        self.formattedPrice = formattedPrice
    }
    override var icon: UIImage {
        return #imageLiteral(resourceName: "ic_gem80_nor")
    }
    override var attributedTitle: NSAttributedString {
        return NSAttributedString(string: String(format: Localized.messageFormats.insufficientGem, Localized.titles.blueGem), attributes: titleAttributes)
    }

    override var attributedSubtitle: NSAttributedString {
        let result = NSMutableAttributedString(attributedString: descriptionPart)
        result.append(instructionPart)
        return result
    }

    private var descriptionPart: NSAttributedString {
        let text = String(format: Localized.messageFormats.insufficientGemToBidDescription, Localized.titles.blueGem, formattedPrice)
        let range = (text as NSString).range(of: Localized.titles.blueGem)
        let result = NSMutableAttributedString(string: text, attributes: subtitleAttributes)
        result.addAttributes([.link : DeepLinks.blueGemPopUp], range: range)
        return result
    }
    
    private var instructionPart: NSAttributedString {
        let text = String(format: Localized.messageFormats.earnBlueGemInstruction, Localized.titles.blueGem)
        let range = (text as NSString).range(of: Localized.titles.blueGem)
        let result = NSMutableAttributedString(string: text, attributes: subtitleAttributes)
        result.addAttributes([.link : DeepLinks.blueGemPopUp], range: range)
        return result
    }
}
