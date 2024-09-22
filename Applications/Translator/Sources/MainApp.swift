//
//  MainApp.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 8/18/24.
//

import Foundation
import SwiftUI

private struct Nothing: Equatable {
}

@main
struct MainApp: App {
    @NSApplicationDelegateAdaptor
    private var appDelegate: AppDelegate

    @Environment(\.openWindow)
    private var openWindow

    var body: some Scene {
        Window(appDelegate.localizedName, id: WindowIdentifier.main.rawValue) {
            MainView()
                .environment(appDelegate.translatorService)
        }
        // This is a hack to take SwiftUI API in `AppDelegate`. This `action` is called
        // before `applicationDidFinishLaunching(_:)`.
        // See `applicationDidFinishLaunching(_:)` for details.
        .onChange(of: Nothing(), initial: true) {
            appDelegate.openWindow = openWindow
        }

        Settings {
            SettingsView()
                .environment(appDelegate.translatorService)
        }
    }
}
