//
//  MainView.swift
//  MicroAdventure
//
//  Created by Abdelrahman Mohamed on 05.02.2026.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Explore", systemImage: "map")
                }

            SnakeGameView()
                .tabItem {
                    Label("Snake", systemImage: "gamecontroller")
                }
        }
    }
}

#Preview {
    MainView()
}
