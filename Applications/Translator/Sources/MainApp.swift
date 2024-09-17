//
//  MainApp.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 8/18/24.
//

import Foundation
import SwiftUI

@main
struct MainApp: App {
    @NSApplicationDelegateAdaptor
    private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(appDelegate.translatorService)
        }

        Settings {
            SettingsView()
                .environment(appDelegate.translatorService)
        }
    }
}
