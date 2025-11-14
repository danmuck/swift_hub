//
//  ContentView.swift
//  Looker
//
//  Created by Daniel Muck on 11/9/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var user: [User]
    
    var body: some View {
        VStack {
            TabView {
                Tab("Jobs", systemImage: "tray.and.arrow.down.fill") {
                    LookerView()
                }
                Tab("Docs", systemImage: "person") {
                    ColorDetail(color: .blue, text: "Coming Soon ...")
                }
                Tab("Finance", systemImage: "person") {
                    FinanceView()
                }
                Tab("Tasks", systemImage: "person") {
                    ColorDetail(color: .red, text: "Coming Soon ...")
                }
            }
        }
        Text("ContentView: Dan Muck 2025")
            .padding()
    }
}

struct ColorDetail: View {
    var color: Color
    var text: String


    var body: some View {
        VStack {
            Text(text)
            color
         }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
}
