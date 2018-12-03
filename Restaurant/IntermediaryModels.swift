//
//  IntermediaryModels.swift
//  Restaurant
//
//  Created by Arvin Zojaji on 2018-12-02.
//  Copyright © 2018 Arvin Zojaji. All rights reserved.
//

import Foundation

struct Categories: Codable {
    let categories: [String]
}

struct PreparationTime: Codable {
    var prepTime: Int
    
    enum CodingKeys: String, CodingKey {
        case prepTime = "preparation_time"
    }
}
