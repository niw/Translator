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

    public var sourceString: String = ""

    public var translatedString: String = ""

    public let modelSource: ModelSource

    private let model: CachedModel

    public init(modelSource: ModelSource = .default) {
        self.modelSource = modelSource
        model = CachedModel(source: modelSource)
    }

    public var modelState: CachedModel.State {
        model.state
    }

    private var translatorLoadingTask: Task<Translator, any Swift.Error>?

    public func preloadModel() {
        do {
            try model.update()
        } catch {
        }

        guard case .available(let url) = model.state else {
            return
        }

        translatorLoadingTask = Task {
            try await Translator(modelURL: url)
        }
    }

    public func downloadModel() {
        do {
            try model.update()
        } catch {
        }

        guard case .unavailable = model.state else {
            return
        }

        Task {
            do {
                try await model.download()
                preloadModel()
            } catch {
            }
        }
    }

    public func purgeModel() {
        do {
            try model.update()
        } catch {
        }

        do {
            try model.purge()
        } catch {
        }
    }

    private var translationTask: Box<Task<Void, any Swift.Error>>?

    public var isTranslating: Bool {
        translationTask != nil
    }

    public func translate() async throws {
        let previousTask = translationTask

        let sourceString = sourceString
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

            preloadModel()

            guard let translatorLoadingTask else {
                throw Error.failed(reason: "No model available.")
            }

            translatedString = ""

            let translator = try await translatorLoadingTask.value

            for try await output in translator.translate(sourceString, mode: mode, style: style) {
                translatedString.append(output)
            }
        })
        translationTask = task
    }
}
