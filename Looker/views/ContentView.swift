//
//  ContentView.swift
//  Looker
//
//  Created by Daniel Muck on 11/9/25.
//

import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var user: [User]

    @AppStorage("appColorScheme") private var appColorSchemeRaw: String = "system"
    @AppStorage("appAccentTint") private var appAccentTint: String = "blue"
    private var accentTintColor: Color {
        switch appAccentTint {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
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
            .padding(.horizontal, 20)
            Text("ContentView: Dan Muck 2025")
                .padding()
            
            .toolbar {
                ToolbarItem() {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(appColorSchemeRaw: $appColorSchemeRaw)
                    .presentationDetents([.medium])
            }
        }
        .preferredColorScheme(preferredScheme)
        .tint(accentTintColor)
    }

    private var preferredScheme: ColorScheme? {
        switch appColorSchemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil // system
        }
    }
}

struct SettingsView: View {
    @Binding var appColorSchemeRaw: String
    @AppStorage("appAccentTint") private var appAccentTint: String = "blue"

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Color Scheme", selection: $appColorSchemeRaw) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
                Section("Theme") {
                    Picker("Accent Tint", selection: $appAccentTint) {
                        Text("Blue").tag("blue")
                        Text("Red").tag("red")
                        Text("Orange").tag("orange")
                        Text("Yellow").tag("yellow")
                        Text("Green").tag("green")
                        Text("Mint").tag("mint")
                        Text("Teal").tag("teal")
                        Text("Cyan").tag("cyan")
                        Text("Indigo").tag("indigo")
                        Text("Purple").tag("purple")
                        Text("Pink").tag("pink")
                    }
                }
            }
            .navigationTitle("Settings")
        }
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
