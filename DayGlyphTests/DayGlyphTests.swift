//
//  DayGlyphTests.swift
//  DayGlyphTests
//
//  Created by Chinyen Zoo on 2026/6/8.
//

import Testing
@testable import DayGlyph

@MainActor
struct DayGlyphTests {

    @Test func projectLoads() async throws {
        #expect(DayEmotion.calm.title == "平静")
    }

}
