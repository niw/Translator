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

@MainActor
@Observable
final class MainService {
    var mode: Translator.Mode = .automatic

    var style: Translator.Style = .technical

    var sourceString: String = ""

    var translatedString: String = ""

    private(set) var isTranslating: Bool = false

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

    @ObservationIgnored
    private var translationTask: Task<Void, any Swift.Error>?

    func translate() async throws {
        let previousTranslationTask = translationTask

        let sourceString = sourceString
        let mode = mode
        let style = style

        translationTask = Task { [weak self] in
            guard let self else {
                return
            }

            if let previousTranslationTask {
                do {
                    previousTranslationTask.cancel()
                    try await previousTranslationTask.value
                } catch {
                }
            }

            preloadModel()

            guard let translatorLoadingTask else {
                throw Error.failed(reason: "No model available.")
            }

            translatedString = ""

            isTranslating = true
            defer {
                // Reentrant
                isTranslating = false
            }

            let translator = try await translatorLoadingTask.value

            for try await output in translator.translate(sourceString, mode: mode, style: style) {
                translatedString.append(output)
            }
        }
    }
}
