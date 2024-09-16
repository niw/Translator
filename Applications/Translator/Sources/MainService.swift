//
//  MainService.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 9/3/24.
//

import Foundation
import Observation
import TranslatorSupport

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
final class MainService {
    var mode: Translator.Mode = .automatic

    var style: Translator.Style = .technical

    var sourceString: String = ""

    var translatedString: String = ""

    let cachedTranslatorModel = CachedModel(source: ModelSource.default)

    private var translatorLoadingTask: Task<Translator, any Swift.Error>?

    func preloadModel() {
        do {
            try cachedTranslatorModel.update()
        } catch {
        }

        guard case .available(let url) = cachedTranslatorModel.state else {
            return
        }

        translatorLoadingTask = Task {
            try await Translator(modelURL: url)
        }
    }

    func downloadModel() {
        do {
            try cachedTranslatorModel.update()
        } catch {
        }

        guard case .unavailable = cachedTranslatorModel.state else {
            return
        }

        Task {
            do {
                try await cachedTranslatorModel.download()
                preloadModel()
            } catch {
            }
        }
    }

    private var translationTask: Box<Task<Void, any Swift.Error>>?

    public var isTranslating: Bool {
        translationTask != nil
    }

    func translate() async throws {
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
