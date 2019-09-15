//
//  User.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/15.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class User: Decodable, UserProfileDisplayable {
    let nickname: String
    let username: String
    let avatar: WebImageInfo? = nil
    let alien: Alien?
    let id: String
    init(id: String, username: String, nickname: String, character: Alien?) {
        self.username = username
        self.id = id
        self.nickname = nickname
        self.alien = character
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case nickname = "display_name"
        case username
        case alien
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        alien = try container.decodeIfPresent(Alien.self, forKey: .alien)
    }
}

class UserFetcherRepository {
    private var fetchers: [String: UserFetcher] = [:]
    
    func fetcher(for userID: String, user: User? = nil) -> UserFetcher {
        if let fetcher = fetchers[userID] {
            return fetcher
        }
        let fetcher = UserFetcher(id: userID, user: user)
        fetchers[userID] = fetcher
        return fetcher
    }
}

class UserFetcher {
    let id: String
    private(set) var user: User?
    private var getUserOperation: GetUserOperation?
    
    init(id: String, user: User?) {
        self.id = id
        self.user = user
    }
    
    func initializeIfNeeded() {
        guard user == nil else { return }
        fetchIfAllows()
    }
    
    func fetchIfAllows() {
        guard getUserOperation == nil else { return }
        let op = GetUserOperation(userID: id)
        op.completionBlock = {[weak self] in
            self?.didFetchUser()
        }
        getUserOperation = op
        op.start()
    }
    
    private func didFetchUser() {
        let op = getUserOperation!
        getUserOperation = nil
        if let user = op.user {
            self.user = user
        } else {
            logger.error("Cannot fetch user of \(id)", context: op.error)
        }
    }
}

class GetUserOperation: AlamofireAPIAccessOperation {
    private(set) var user: User?
    let userID: String
    init(userID: String) {
        self.userID = userID
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return URLRequest(url: ServiceURLs.base.appendingPathComponent("users/\(userID)"))
    }
    
    override func processData(with data: Data) throws {
        user = try JSONDecoder.default.decode(User.self, from: data)
    }
}

class Alien: Decodable {
    let race: Race
    let color: AlienColor
    var frameImage: UIImage {
        return race.frameImage
    }
    var avatar: UIImage {
        return AlienAvatars.shared.avatar(for: race, color: color)
    }
    var monologue: String {
        return race.monologue
    }
    init(race: Race, color: AlienColor) {
        self.race = race
        self.color = color
    }
    enum CodingKeys: String, CodingKey {
        case race = "avatar"
        case color
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        race = Race(rawValue: try container.decode(String.self, forKey: .race)) ?? .one
        color = AlienColor(rawValue: try container.decode(String.self, forKey: .color)) ?? .green
    }
}

extension Alien: Equatable {
    static func ==(lhs: Alien, rhs: Alien) -> Bool {
        return lhs.race == rhs.race && lhs.color == rhs.color
    }
}

enum Race: String {
    case one = "alien-1"
    case two = "alien-2"
    case three = "alien-3"
    
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

enum AlienColor: String {
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

class AlienAvatars {
    static let shared = AlienAvatars()
    private let lookupTable: [AlienColor: [Race: UIImage]] =
        [.green: [.one: #imageLiteral(resourceName: "im_alien1_green"), .two: #imageLiteral(resourceName: "im_alien2_green"), .three: #imageLiteral(resourceName: "im_alien3_green")],
         .pink: [.one: #imageLiteral(resourceName: "im_alien1_pink"), .two: #imageLiteral(resourceName: "im_alien2_pink"), .three: #imageLiteral(resourceName: "im_alien3_pink")],
         .blue: [.one: #imageLiteral(resourceName: "im_alien1_blue"), .two: #imageLiteral(resourceName: "im_alien2_blue"), .three: #imageLiteral(resourceName: "im_alien3_blue")]]
    
    func avatar(for race: Race, color: AlienColor) -> UIImage {
        if let image = lookupTable[color]?[race] {
            return image
        } else {
            switch race {
            case .one: return #imageLiteral(resourceName: "im_alien1_green")
            case .two: return #imageLiteral(resourceName: "im_alien2_green")
            case .three: return #imageLiteral(resourceName: "im_alien3_green")
            }
        }
    }
}

class AlienOptions {
    static let shared = AlienOptions()
    private init() {}
    let colors: [AlienColor] = [.green, .pink, .blue]
    func alien(for race: Race, color: AlienColor) -> Alien? {
        return alienOptions(for: color).first(where: {
            return $0.race == race
        })
    }
    func alienOptions(for color: AlienColor) -> [Alien] {
        switch color {
        case .green:
            return [Alien(race: .one, color: color), Alien(race: .two, color: color), Alien(race: .three, color: color)]
        case .pink:
            return [Alien(race: .one, color: color), Alien(race: .two, color: color), Alien(race: .three, color: color)]
        case .blue:
            return [Alien(race: .one, color: color), Alien(race: .two, color: color), Alien(race: .three, color: color)]
        default:
            return [Alien(race: .one, color: color), Alien(race: .two, color: color), Alien(race: .three, color: color)]
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
