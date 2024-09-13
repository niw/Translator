//
//  AppDelegate.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 8/18/24.
//

import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject {
    let mainService: MainService = MainService()

    var localizedName: String {
        for case let infoDictionary? in [
            Bundle.main.localizedInfoDictionary,
            Bundle.main.infoDictionary
        ] {
            for key in [
                "CFBundleDisplayName",
                "CFBundleName"
            ] {
                if let localizedName = infoDictionary[key] as? String {
                    return localizedName
                }
            }
        }

        // Should not reach here.
        return ""
    }

    func presentAboutPanel() {
        if NSApp.activationPolicy() == .accessory {
            NSApp.activate(ignoringOtherApps: true)
        }
        NSApp.orderFrontStandardAboutPanel()
    }

    func terminate() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.servicesProvider = ServiceProvider(mainService: mainService)
        NSUpdateDynamicServices()

        mainService.preloadModel()
    }
}
