//
//  DayGlyphApp.swift
//  DayGlyph
//
//  Created by Chinyen Zoo on 2026/6/8.
//

import SwiftUI
import SwiftData

@main
struct DayGlyphApp: App {
    let sharedModelContainer: ModelContainer

    init() {
        let container = Self.makeModelContainer()
        let launchOptions = DemoLaunchOptions(arguments: CommandLine.arguments)

        if launchOptions.skipsOnboarding {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }

        if launchOptions.seedsDemoData {
            let context = ModelContext(container)
            DemoDataSeeder.seed(into: context)
            DemoDataSeeder.seedSupportData(into: context)
        }

        sharedModelContainer = container
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            DayEntry.self,
            ActionInstance.self,
            TimeLetter.self,
            EmpathyCopy.self,
            ActionResponse.self,
            AIGenerationRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
