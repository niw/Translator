//
//  URLSessionDownloadTaskExtension.swift
//  TranslatorSupport
//
//  Created by Yoshimasa Niwa on 9/4/24.
//

import Foundation

private extension HTTPURLResponse {
    var isSuccess: Bool {
        (200...299).contains(statusCode)
    }
}

private final class ContinuationDelegate: NSObject, URLSessionDownloadDelegate {
    private enum Error: Swift.Error {
        case noResponse
        case httpResponse(statusCode: Int)
    }

    typealias Continuation = CheckedContinuation<Void, any Swift.Error>

    private let continuation: Continuation
    private let location: URL

    init(_ continuation: Continuation, location: URL) {
        self.continuation = continuation
        self.location = location
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

extension URLSessionDownloadTask {
    func resumeDownloading(to location: URL) async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                delegate = ContinuationDelegate(continuation, location: location)
                resume()
            }
        } onCancel: {
            cancel()
        }
    }
}
