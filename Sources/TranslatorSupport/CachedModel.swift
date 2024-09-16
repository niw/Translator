//
//  CachedModel.swift
//  Translator
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
public final class CachedModel {
    private struct Download {
        var task: Task<Void, any Swift.Error>
        var progress: Progress
    }

    private var download: Download?

    private var url: URL?

    public enum State: Sendable, Equatable {
        case loading(Progress?)
        case available(URL)
        case unavailable
    }

    public var state: State {
        if let download {
            .loading(download.progress)
        } else if let url {
            .available(url)
        } else {
            .unavailable
        }
    }

    private var modelsDirectory: URL {
        get throws {
            try FileManager.default.applicationSupportDirectory(named: "Models")
        }
    }

    public let source: ModelSource

    init(source: ModelSource) {
        self.source = source
    }

    public func update() throws {
        let modelsDirectory = try modelsDirectory
        let fileURL = modelsDirectory.appending(component: source.fileName)
        if FileManager.default.fileExists(at: fileURL) {
            url = fileURL
        } else {
            url = nil
        }
    }

    public func download() async throws {
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
            let modelsDirectory = try modelsDirectory
            try FileManager.default.createDirectory(at: modelsDirectory, isExcludedFromBackup: true)
            let fileURL = modelsDirectory.appending(component: source.fileName)
            try await downloadTask.resumeDownloading(to: fileURL)
            url = fileURL
        }
        return Download(task: task, progress: downloadTask.progress)
    }
}
