//
//  Item.swift
//  DayGlyph
//
//  Created by Chinyen Zoo on 2026/6/8.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
