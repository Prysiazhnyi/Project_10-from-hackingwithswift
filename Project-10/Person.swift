//
//  Person.swift
//  Project-10
//
//  Created by Serhii Prysiazhnyi on 08.11.2024.
//

import UIKit
import Foundation

class Person: NSObject, Codable {
    
    var name: String
    var image: String
    
    // Инициализатор для класса Person
    init(name: String, image: String) {
        self.name = name
        self.image = image
    }

    // Реализация Decodable вручную
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.image = try container.decode(String.self, forKey: .image)
    }

    // CodingKeys для кодирования/декодирования
    enum CodingKeys: String, CodingKey {
        case name, image
    }
}
