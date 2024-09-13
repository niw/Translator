//
//  FileManagerExtension.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 8/18/24.
//

import Foundation

private enum Error: Swift.Error {
    case failed(reason: String)
}

private extension URL {
    func appending(directory component: String) -> URL {
        appending(component: component, directoryHint: .isDirectory)
    }
}

extension FileManager {
    func fileExists(at url: URL) -> Bool {
        fileExists(atPath: url.path(percentEncoded: false))
    }

    func applicationSupportDirectory(named name: String) throws -> URL {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            throw Error.failed(reason: "No main bundle identifier found.")
        }
        let applicationSupportDirectoryURL = try url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return applicationSupportDirectoryURL.appending(directory: bundleIdentifier).appending(directory: name)
    }

    func createDirectory(at url: URL, isExcludedFromBackup: Bool = false) throws {
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            if isExcludedFromBackup {
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                var url = url
                try url.setResourceValues(values)
            }
        } else {
            guard isDirectory.boolValue else {
                throw Error.failed(reason: "File exists at \(url).")
            }
        }
    }
}
