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
    var monologue: String {
        return race.monologue
    }
    init(race: Race, color: CharacterColor, avatar: UIImage) {
        self.race = race
        self.color = color
        self.avatar = avatar
    }
}

extension Character: Equatable {
    static func ==(lhs: Character, rhs: Character) -> Bool {
        return lhs.race == rhs.race && lhs.color == rhs.color
    }
}

enum Race: String {
    case one
    case two
    case three
    
    var frameImage: UIImage {
        switch self {
        case .one: return #imageLiteral(resourceName: "im_alien1_bg")
        case .two: return #imageLiteral(resourceName: "im_alien2_bg")
        case .three: return #imageLiteral(resourceName: "im_alien3_bg")
        }
    }
    
    var monologue: String {
        switch self {
        case .one: return Localized.messages.race1Monologue
        case .two: return Localized.messages.race2Monologue
        case .three: return Localized.messages.race3Monologue
        }
    }

}

enum CharacterColor: String {
    case green
    case pink
    case blue
    case purple
    case lightGray
    case darkGray
    
    var color: UIColor {
        switch self {
        case .green: return #colorLiteral(red: 0.6274509804, green: 1, blue: 0.3568627451, alpha: 1)
        case .pink: return #colorLiteral(red: 1, green: 0.4235294118, blue: 0.6823529412, alpha: 1)
        case .blue: return #colorLiteral(red: 0.1725490196, green: 0.7176470588, blue: 0.9333333333, alpha: 1)
        case .purple: return #colorLiteral(red: 0.6941176471, green: 0.3450980392, blue: 1, alpha: 1)
        case .lightGray: return #colorLiteral(red: 0.7647058824, green: 0.7647058824, blue: 0.7647058824, alpha: 1)
        case .darkGray: return #colorLiteral(red: 0.3098039216, green: 0.3098039216, blue: 0.3098039216, alpha: 1)
        }
    }
}

class CharacterOptions {
    static let shared = CharacterOptions()
    private init() {}
    let colors: [CharacterColor] = [.green, .pink, .blue]
    func characterOptions(for color: CharacterColor) -> [Character] {
        switch color {
        case .green:
            return [Character(race: .one, color: color, avatar: #imageLiteral(resourceName: "im_alien1_green")), Character(race: .two, color: color, avatar: #imageLiteral(resourceName: "im_alien2_green")), Character(race: .three, color: color, avatar: #imageLiteral(resourceName: "im_alien3_green"))]
        case .pink:
            return [Character(race: .one, color: color, avatar: #imageLiteral(resourceName: "im_alien1_pink")), Character(race: .two, color: color, avatar: #imageLiteral(resourceName: "im_alien2_pink")), Character(race: .three, color: color, avatar: #imageLiteral(resourceName: "im_alien3_pink"))]
        case .blue:
            return [Character(race: .one, color: color, avatar: #imageLiteral(resourceName: "im_alien1_blue")), Character(race: .two, color: color, avatar: #imageLiteral(resourceName: "im_alien2_blue")), Character(race: .three, color: color, avatar: #imageLiteral(resourceName: "im_alien3_blue"))]
        default:
            return [Character(race: .one, color: color, avatar: #imageLiteral(resourceName: "im_alien1_green")), Character(race: .two, color: color, avatar: #imageLiteral(resourceName: "im_alien2_green")), Character(race: .three, color: color, avatar: #imageLiteral(resourceName: "im_alien3_green"))]

        }
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
