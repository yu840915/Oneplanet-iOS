//
//  User.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/15.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class Character {
    let race: Race
    let color: CharacterColor
    let avatar: UIImage
    init(race: Race, color: CharacterColor, avatar: UIImage) {
        self.race = race
        self.color = color
        self.avatar = avatar
    }
}

enum Race: String {
    case a
    case b
    case c
    var color: UIColor {
        switch self {
        case .a: return #colorLiteral(red: 0.6274509804, green: 1, blue: 0.3568627451, alpha: 1)
        case .b: return #colorLiteral(red: 1, green: 0.4235294118, blue: 0.6823529412, alpha: 1)
        case .c: return #colorLiteral(red: 0.3568627451, green: 0.6549019608, blue: 1, alpha: 1)
        }
    }
}

enum CharacterColor: String {
    case green
    case pink
    case malibu
    case purple
    case lightGray
    case darkGray
    
    var color: UIColor {
        switch self {
        case .green: return #colorLiteral(red: 0.6274509804, green: 1, blue: 0.3568627451, alpha: 1)
        case .pink: return #colorLiteral(red: 1, green: 0.4235294118, blue: 0.6823529412, alpha: 1)
        case .malibu: return #colorLiteral(red: 0.3568627451, green: 0.6549019608, blue: 1, alpha: 1)
        case .purple: return #colorLiteral(red: 0.6941176471, green: 0.3450980392, blue: 1, alpha: 1)
        case .lightGray: return #colorLiteral(red: 0.7647058824, green: 0.7647058824, blue: 0.7647058824, alpha: 1)
        case .darkGray: return #colorLiteral(red: 0.3098039216, green: 0.3098039216, blue: 0.3098039216, alpha: 1)
        }
    }
}

class CharacterOptions {
    static let shared = CharacterOptions()
    private init() {}
    let colors: [CharacterColor] = [.green, .pink, .malibu, .purple, .lightGray, .darkGray]
    func characterOptions(for color: CharacterColor) -> [Character] {
        return [Character(race: .a, color: color, avatar: #imageLiteral(resourceName: "im_alien_c0")), Character(race: .b, color: color, avatar: #imageLiteral(resourceName: "im_alien_b0")), Character(race: .c, color: color, avatar: #imageLiteral(resourceName: "im_alien_a0"))]
    }
}

class WebImageInfo {
    let url: URL
    let accessToken: String?
    init(url: URL, accessToken: String? = nil) {
        self.url = url
        self.accessToken = accessToken
    }
}

extension WebImageInfo: Equatable {
    static func ==(lhs: WebImageInfo, rhs: WebImageInfo) -> Bool {
        return lhs.url == rhs.url && lhs.accessToken == rhs.accessToken
    }
}
