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
public protocol TranslatorServiceProtocol: ObservableObject {
    associatedtype SomeModel: ModelProtocol

    var model: SomeModel { get }

    var isAutomaticTranslationEnabled: Bool { get set }

    var mode: Translator.Mode { get set }

    var style: Translator.Style { get set }

    var inputString: String { set get }

    var translatedString: String { set get }

    var isTranslating: Bool { get }

    func translate() async throws -> Void
}

@MainActor
@Observable
public final class AnyTranslatorService: TranslatorServiceProtocol {
    private let translatorService: any TranslatorServiceProtocol

    init(_ translatorService: some TranslatorServiceProtocol) {
        self.translatorService = translatorService
    }

    public var model: AnyModel {
        translatorService.model.eraseToAnyModel()
    }

    public var isAutomaticTranslationEnabled: Bool {
        get {
            translatorService.isAutomaticTranslationEnabled
        }
        set {
            translatorService.isAutomaticTranslationEnabled = newValue
        }
    }

    public var mode: Translator.Mode {
        get {
            translatorService.mode
        }
        set {
            translatorService.mode = newValue
        }
    }

    public var style: Translator.Style {
        get {
            translatorService.style
        }
        set {
            translatorService.style = newValue
        }
    }

    public var inputString: String {
        get {
            translatorService.inputString
        }
        set {
            translatorService.inputString = newValue
        }
    }

    public var translatedString: String {
        get {
            translatorService.translatedString
        }
        set {
            translatorService.translatedString = newValue
        }
    }

    public var isTranslating: Bool {
        translatorService.isTranslating
    }

    public func translate() async throws {
        try await translatorService.translate()
    }
}

extension TranslatorServiceProtocol {
    public func eraseToAnyTranslatorService() -> AnyTranslatorService {
        AnyTranslatorService(self)
    }
}

@MainActor
@Observable
public final class TranslatorService: TranslatorServiceProtocol {
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

            for try await output in llamaModel.complete(prompt.text, suffix: prompt.suffix) {
                translatedString.append(output)
            }
        })
        translationTask = task
    }
}

@MainActor
@Observable
public final class PreviewTranslatorService: TranslatorServiceProtocol {
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
        if isAutomaticTranslationEnabled {
            Task {
                do {
                    try await translate()
                } catch {
                }
            }
        }
    }

    public var translatedString: String = ""

    public let model: PreviewModel

    public init() {
        model = PreviewModel()
    }

    public var isTranslating: Bool = false

    public func translate() async throws {
        do {
            isTranslating = true
            translatedString = ""
            try await Task.sleep(nanoseconds: 1.seconds)
            translatedString = "Translated from \(inputString)"
        } catch {
        }
        isTranslating = false
    }
}
