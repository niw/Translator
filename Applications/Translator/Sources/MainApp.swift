//
//  MainApp.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 8/18/24.
//

import Foundation
import SwiftUI

enum WindowIdentifier: String {
    case main
}

@main
struct MainApp: App {
    @NSApplicationDelegateAdaptor
    private var appDelegate: AppDelegate

    var body: some Scene {
        Window(appDelegate.localizedName, id: WindowIdentifier.main.rawValue) {
            MainView()
                .environment(appDelegate.translatorService)
        }

        Settings {
            SettingsView()
                .environment(appDelegate.translatorService)
        }
    }
}
