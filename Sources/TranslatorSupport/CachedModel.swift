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
    private struct Download {
        var task: Task<Void, any Swift.Error>
        var progress: Progress
    }

    private var download: Download?

    private var url: URL?

    enum State: Sendable, Equatable {
        case unavailable
        case downloading(Progress?)
        case available(URL)
    }

    var state: State {
        if let download {
            .downloading(download.progress)
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
            try await download.task.value
        } else {
            let download = resumeDownload()
            self.download = download
            do {
                try await download.task.value
                // Reentrant
                self.download = nil
            } catch {
                // Reentrant
                self.download = nil
                throw error
            }
        }
    }

    private func resumeDownload() -> Download {
        let request = URLRequest(url: self.source.url)
        let downloadTask = URLSession.shared.downloadTask(with: request)
        let task = Task {
            try FileManager.default.createDirectory(at: modelsCacheURL, isExcludedFromBackup: true)
            let fileURL = modelsCacheURL.appending(component: source.fileName)
            try await downloadTask.resumeDownloading(to: fileURL)
            url = fileURL
        }
        return Download(task: task, progress: downloadTask.progress)
    }

    func purge() throws {
        guard let url else {
            return
        }
        try FileManager.default.removeItem(at: url)
        self.url = nil
    }
}
