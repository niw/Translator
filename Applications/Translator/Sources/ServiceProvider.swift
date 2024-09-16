//
//  ServiceProvider.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 8/18/24.
//

import AppKit
import Foundation
import TranslatorSupport

@MainActor
final class ServiceProvider: NSObject {
    private let translatorService: TranslatorService

    init(translatorService: TranslatorService) {
        self.translatorService = translatorService
    }

    @objc
    func translate(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let string = pasteboard.string(forType: .string) else {
            return
        }
        translatorService.sourceString = string
        Task {
            do {
                try await translatorService.translate()
            } catch {
            }
        }
    }
}
