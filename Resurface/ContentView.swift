//
//  ContentView.swift
//  Resurface
//
//  Created by Keenan Meyer on 3/26/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(ResurfaceTheme.Colors.accent)
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BookmarkItem.self, Category.self, Tag.self], inMemory: true)
}
