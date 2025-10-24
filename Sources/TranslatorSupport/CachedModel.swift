//
//  CachedModel.swift
//  TranslatorSupport
//
//  Created by Yoshimasa Niwa on 8/27/24.
//

import Foundation
import Observation

private enum Error: Swift.Error {
    case failed(reason: String)
}

private extension ModelSource {
    var fileName: String {
        url.lastPathComponent
    }
}

@MainActor
@Observable
final class CachedModel {
    private var download: Download?

    private var url: URL?

    enum State: Sendable {
        case unavailable
        case downloading(Download?)
        case available(URL)
    }

    var state: State {
        if let download {
            .downloading(download)
        } else if let url {
            .available(url)
        } else {
            .unavailable
        }
    }

    let modelsCacheURL: URL

    let source: ModelSource

    init(modelsCacheURL: URL, source: ModelSource) {
        self.modelsCacheURL = modelsCacheURL
        self.source = source
    }

    func update() throws {
        let fileURL = modelsCacheURL.appending(component: source.fileName)
        if FileManager.default.fileExists(at: fileURL) {
            url = fileURL
        } else {
            url = nil
        }
    }

    func download() async throws {
        if let download {
            try await download.result()
        } else {
            let request = URLRequest(url: self.source.url)

            try FileManager.default.createDirectory(at: modelsCacheURL, isExcludedFromBackup: true)
            let fileURL = modelsCacheURL.appending(component: source.fileName)

            let download = Download(request, to: fileURL)
            self.download = download
            do {
                try await download.result()
                // Reentrant
                self.download = nil
                self.url = fileURL
            } catch {
                // Reentrant
                self.download = nil
                throw error
            }
        }
    }

    func purge() throws {
        guard let url else {
            return
        }
        try FileManager.default.removeItem(at: url)
        self.url = nil
    }
}
