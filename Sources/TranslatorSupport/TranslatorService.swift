//
//  TranslatorService.swift
//  TranslatorSupport
//
//  Created by Yoshimasa Niwa on 9/3/24.
//

import Foundation
import Observation

private enum Error: Swift.Error {
    case failed(reason: String)
}

private final class Box<T> {
    var value: T

    init(_ value: T) {
        self.value = value
    }
}

@MainActor
@Observable
public final class TranslatorService {
    public var mode: Translator.Mode = .automatic

    public var style: Translator.Style = .technical

    public var inputString: String = ""

    public var translatedString: String = ""

    public let model: Model

    public init() {
        let modelsCacheURL = try! FileManager.default.applicationSupportDirectory(named: "Models")
        model = Model(cached: CachedModel(modelsCacheURL: modelsCacheURL, source: .default))
    }

    private var translationTask: Box<Task<Void, any Swift.Error>>?

    public var isTranslating: Bool {
        translationTask != nil
    }

    public func translate() async throws {
        let previousTask = translationTask

        let inputString = inputString
        let mode = mode
        let style = style

        var task: Box<Task<Void, any Swift.Error>>?
        task = Box(Task { [weak self] in
            guard let self else {
                return
            }

            defer {
                // Reentrant
                if let task, translationTask === task {
                    translationTask = nil
                }
            }

            if let previousTask {
                do {
                    previousTask.value.cancel()
                    try await previousTask.value.value
                } catch {
                }
            }

            guard let llamaModel = try await model.llamaModel else {
                throw Error.failed(reason: "No model available.")
            }

            translatedString = ""

            let prompt = Translator.prompt(
                mode: mode,
                style: style,
                input: inputString
            )

            for try await output in llamaModel.complete(prompt) {
                translatedString.append(output)
            }
        })
        translationTask = task
    }
}
