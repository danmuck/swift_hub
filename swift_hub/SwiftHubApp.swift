//
//  LookerApp.swift
//  Looker
//
//  Created by Daniel Muck on 10/24/25.
//

import SwiftUI
import SwiftData

@main
struct SwiftHubApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Job.self,
            JobNote.self,
            JobTask.self,
            JobLink.self,
            JobDocument.self,
            User.self,
            Txn.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
