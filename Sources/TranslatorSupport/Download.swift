//
//  Download.swift
//  TranslatorSupport
//
//  Created by Yoshimasa Niwa on 10/23/25.
//

import Foundation
import Observation

private extension HTTPURLResponse {
    var isSuccess: Bool {
        (200...299).contains(statusCode)
    }
}

private final class ContinuationURLSessionDownloadDelegate: NSObject, URLSessionDownloadDelegate {
    enum Error: Swift.Error {
        case noResponse
        case httpResponse(statusCode: Int)
    }

    struct BytesProgress {
        var downloaded: Int64
        var total: Int64?
    }

    typealias Continuation = CheckedContinuation<Void, any Swift.Error>
    typealias OnBytesProgress = @Sendable (BytesProgress) -> Void

    private let continuation: Continuation
    private let location: URL
    private let onBytesProgress: OnBytesProgress?

    init(_ continuation: Continuation, location: URL, onProgress: OnBytesProgress?) {
        self.continuation = continuation
        self.location = location
        self.onBytesProgress = onProgress
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let onBytesProgress else {
            return
        }
        let bytesProgress = BytesProgress(
            downloaded: totalBytesWritten,
            total: (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) ? nil : totalBytesExpectedToWrite
        )
        onBytesProgress(bytesProgress)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Swift.Error)?) {
        guard let error else {
            return
        }
        continuation.resume(throwing: error)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard downloadTask.error == nil else {
            // This is not called if download task is cancelled.
            // To handle such error cases, use `urlSession(_:task:didCompleteWithErro:)`
            // that is always called.
            return
        }

        if let response = downloadTask.response {
            // `error` is only happening on client side error, not server side error.
            // If it's HTTP response, check status code to fail if it's not success.
            if let httpResponse = response as? HTTPURLResponse, !httpResponse.isSuccess {
                continuation.resume(throwing: Error.httpResponse(statusCode: httpResponse.statusCode))
            } else {
                // This `location` is only valid while this delegate method is called.
                // Move it to given `self.location` or temporary location to preserve it.
                do {
                    try FileManager.default.moveItem(at: location, to: self.location)
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } else {
            // Must not reach here.
            continuation.resume(throwing: Error.noResponse)
        }
    }
}

public struct DownloadProgress: Sendable {
    public var downloadedBytes: Int64
    public var totalBytes: Int64?

    public init(downloadedBytes: Int64 = 0, totalBytes: Int64? = nil) {
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
    }
}

@MainActor
public protocol DownloadProtocol: AnyObject, Observable {
    var progress: DownloadProgress { get }
    func cancel()
    func result() async throws
}

@MainActor
@Observable
public final class Download: DownloadProtocol {
    @ObservationIgnored
    private var task: Task<Void, Error>!

    public var progress = DownloadProgress()

    init(_ request: URLRequest, to location: URL) {
        task = Task {
            let downloadTask = URLSession.shared.downloadTask(with: request)

            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    downloadTask.delegate = ContinuationURLSessionDownloadDelegate(continuation, location: location) { bytesProgress in
                        Task { @MainActor in
                            self.progress.downloadedBytes = bytesProgress.downloaded
                            self.progress.totalBytes = bytesProgress.total
                        }
                    }
                    downloadTask.resume()
                }
            } onCancel: {
                downloadTask.cancel()
            }
        }
    }

    public func cancel() {
        task.cancel()
    }

    public func result() async throws {
        try await task.value
    }
}

@MainActor
@Observable
public final class PreviewDownload: DownloadProtocol {
    @ObservationIgnored
    private var task: Task<Void, Error>!

    public var progress = DownloadProgress()

    public init() {
        task = Task {
            try await Task.sleep(for: .seconds(0.2))
            progress.totalBytes = 256
            for _ in (0..<256) {
                try await Task.sleep(for: .seconds(0.1))
                progress.downloadedBytes += 1
            }
        }
    }

    public func cancel() {
        task.cancel()
    }

    public func result() async throws {
        try await task.value
    }
}
