//
//  AppDelegate.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 8/18/24.
//

import AppKit
import Foundation
import TranslatorSupport
import SwiftUI

@MainActor
final class AppDelegate: NSObject {
    var openWindow: OpenWindowAction? = nil

    func openWindow(id: WindowIdentifier) {
        openWindow?(id: id.rawValue)
    }

    var translatorService: TranslatorService = TranslatorService()

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
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.servicesProvider = ServiceProvider(translatorService: translatorService)
        NSUpdateDynamicServices()

        translatorService.model.load()

        // TODO: Find a better solution.
        // When the app is launched by, for example, by service, SwiftUI doesn't open any `Window`
        // thus even `NSApplication.shared.windows` is blank.
        // Therefore, service provider has no way to open any app `Window` from the its context.
        // To workaround this issue, and this app always wants to open the main window,
        // use SwiftUI `openWindow(id:)` API to open the main window always.
        if let userInfo = notification.userInfo,
           let number = userInfo[NSApplication.launchIsDefaultUserInfoKey] as? NSNumber,
           number.boolValue == false
        {
            openWindow(id: .main)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
