//
//  SWAPI.swift
//  Animations
//
//  Created by Joshua Fisher on 4/15/18.
//  Copyright © 2018 Joshua Fisher. All rights reserved.
//

import Foundation

struct SWAPI {
    static let peopleUrl = URL(string: "https://swapi.co/api/people")!
    
    static func peopleSeachUrl(query: String) -> URL {
        var comps = URLComponents(url: peopleUrl, resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "search", value: query)]
        return comps.url!
    }
    
    typealias Error = Int
    
    struct Planet: Codable {
        var url: URL
        var name: String
        var rotationPeriod: Float
        var surfaceWater: Float
        var climate: String
        var population: Float
        var orbitalPeriod: String
        var edited: Date
        var created: Date
        var films: [URL]
        var gravity: Float
        var diameter: Float
        var residents: [URL]
        var terrain: String
    }
    
    struct Starship: Codable {
        var url: URL
        var name: String
        var passengers: Float
        var maxAtmospheringSpeed: Float?
        var costInCredits: Float
        var model: String
        var edited: Date
        var created: Date
        var films: [URL]
        var length: Float
        var cargoCapacity: Float
        var crew: Float
        var pilots: [URL]
        var consumables: Float
        var starshipClass: String
        var manufacturer: String
        var hyperdriveRating: String
        var MGLT: Float
    }
    
    struct Vehicle: Codable {
        var url: URL
        var name: String
        var passengers: Float
        var maxAtmospheringSpeed: Float?
        var costInCredits: Float
        var model: String
        var edited: Date
        var created: Date
        var films: [URL]
        var length: Float
        var cargoCapacity: Float
        var crew: Float
        var pilots: [URL]
        var consumables: Float
        var vehicleClass: String
        var manufacturer: String
    }
    
    struct Person: URLResource, Codable {
        enum CodingKeys: String, CodingKey {
            case birthYear = "birth_year"
            case hairColor = "hair_color"
            case skinColor = "skin_color"
            case eyeColor = "eye_color"
            case editedRaw = "edited"
            case createdRaw = "created"
            case starships, name, vehicles, url, species, homeworld, height, films, gender, mass
        }
        
        private var editedRaw, createdRaw: String
        
        var birthYear: String
        var starships: [URL]
        var name: String
        var vehicles: [URL]
        var hairColor: String
        var skinColor: String
        var url: URL
        var species: [URL]
        lazy var edited: Date = { dateFormatter.date(from: self.editedRaw)! }()
        lazy var created: Date = { dateFormatter.date(from: self.createdRaw)! }()
        var eyeColor: String
        var homeworld: URL
        var height: String
        var films: [URL]
        var gender: String?
        var mass: String
    }
    
    struct Film: Codable {
        var episodeId: Int
        var starships: [URL]
        var edited: Date
        var director: String
        var vehicles: [URL]
        var characters: [URL]
        var planets: [URL]
        var producer: String
        var title: String
        var created: Date
        var url: URL
        var releaseDate: Date
        var species: [URL]
        var openingCrawl: String
    }
    
    struct Species: Codable {
        var skinColors: String?
        var language: String
        var name: String
        var homeworld: URL
        var hairColors: String?
        var url: URL
        var classification: String
        var eyeColors: String?
        var edited: Date
        var created: Date
        var people: [URL]
        var averageHeight: Float
        var averageLifespan: Float
        var designation: String
        var films: [URL]
    }
    
    struct Results<Type: Codable>: Codable {
        let count: Int
        let next: URL?
        let previous: URL?
        let results: [Type]
    }
}

protocol URLResource: Equatable {
    var url: URL { get }
}

extension URLResource {
    static func==(_ lhs: Self, _ rhs: Self) -> Bool {
        return lhs.url == rhs.url
    }
}

private let dateFormatter = ISO8601DateFormatter()

extension SWAPI.Error: Error {}
