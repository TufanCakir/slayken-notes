//
//  Slayken_NotesApp.swift
//  Slayken Notes
//
//  Created by Tufan Cakir on 26.10.25.
//

import SwiftUI

@main
struct Slayken_NotesApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var profileManager = ProfileManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(themeManager)
                .environmentObject(profileManager)
        }
    }
}
