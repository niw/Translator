//
//  LlamaModel.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 9/13/24.
//

import Foundation

public struct LlamaModel: Sendable {
    private var context: LlamaContext

    public init(url: URL) async throws {
        context = try await Task {
            try LlamaContext.create_context(path: url.path(percentEncoded: false))
        }.value
    }

    public func complete(_ prompt: String, suffix: String? = nil) -> AsyncThrowingStream<String, any Swift.Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try Task.checkCancellation()

                    try await context.completion_init(text: prompt, suffix: suffix)

                    try Task.checkCancellation()

                    while await !context.is_done {
                        let result = try await context.completion_loop()

                        try Task.checkCancellation()

                        continuation.yield(result)
                    }

                    await context.clear()

                    continuation.finish()
                } catch {
                    await context.clear()

                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
