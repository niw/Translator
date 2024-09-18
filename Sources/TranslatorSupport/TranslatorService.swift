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

private extension Double {
    var seconds: UInt64 {
        UInt64(self * 1_000_000_000)
    }
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
    public var isAutomaticTranslationEnabled: Bool = true {
        didSet {
            guard oldValue != isAutomaticTranslationEnabled else {
                return
            }
            inputDidChange()
        }
    }

    public var mode: Translator.Mode = .autoDetect {
        didSet {
            guard oldValue != mode else {
                return
            }
            inputDidChange()
        }
    }

    public var style: Translator.Style = .technical {
        didSet {
            guard oldValue != style else {
                return
            }
            inputDidChange()
        }
    }

    public var inputString: String = "" {
        didSet {
            guard oldValue != inputString else {
                return
            }
            inputDidChange()
        }
    }

    private func inputDidChange() {
        guard isAutomaticTranslationEnabled else {
            return
        }

        Task {
            do {
                try await translate(debounce: true)
            } catch {
            }
        }
    }

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
        guard !isAutomaticTranslationEnabled else {
            return
        }

        try await translate(debounce: false)
    }

    private func translate(debounce: Bool) async throws {
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

            let trimmedInputString = inputString.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedInputString.isEmpty else {
                translatedString = ""
                return
            }

            if debounce {
                try await Task.sleep(nanoseconds: 1.0.seconds)
            }

            guard let llamaModel = try await model.llamaModel else {
                throw Error.failed(reason: "No model available.")
            }

            let prompt = Translator.prompt(
                mode: mode,
                style: style,
                input: trimmedInputString
            )

            translatedString = ""

            for try await output in llamaModel.complete(prompt) {
                translatedString.append(output)
            }
        })
        translationTask = task
    }
}
