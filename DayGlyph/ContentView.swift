//
//  ContentView.swift
//  DayGlyph
//
//  Created by Chinyen Zoo on 2026/6/8.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        AppRootView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
