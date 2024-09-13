//
//  ServiceProvider.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 8/18/24.
//

import AppKit
import Foundation

@MainActor
final class ServiceProvider: NSObject {
    private let mainService: MainService

    init(mainService: MainService) {
        self.mainService = mainService
    }

    @objc
    func translate(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let string = pasteboard.string(forType: .string) else {
            return
        }
        mainService.sourceString = string
        Task {
            do {
                try await mainService.translate()
            } catch {
            }
        }
    }
}
