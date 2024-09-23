//
//  Model.swift
//  TranslatorSupport
//
//  Created by Yoshimasa Niwa on 9/17/24.
//

import Foundation
import Observation
import LlamaModel

public enum ModelState {
    case unavailable
    case downloading(Progress?)
    case available(URL)
}

@MainActor
public protocol ModelProtocol: ObservableObject {
    var state: ModelState { get }

    var source: ModelSource { get }

    func update() -> Void

    func load() -> Void

    func download() -> Void

    func purge() -> Void
}

@MainActor
@Observable
public final class AnyModel: ModelProtocol {
    private let model: any ModelProtocol

    init(_ model: some ModelProtocol) {
        self.model = model
    }

    public var state: ModelState {
        model.state
    }

    public var source: ModelSource {
        model.source
    }

    public func update() {
        model.update()
    }

    public func load() {
        model.load()
    }

    public func download() {
        model.download()
    }

    public func purge() {
        model.purge()
    }
}

extension ModelProtocol {
    public func eraseToAnyModel() -> AnyModel {
        AnyModel(self)
    }
}

@MainActor
@Observable
public final class Model: ModelProtocol {
    public var state: ModelState {
        switch cachedModel.state {
        case .unavailable:
            return .unavailable
        case .downloading(let progress):
            return .downloading(progress)
        case .available(let url):
            return .available(url)
        }
    }

    let cachedModel: CachedModel

    public var source: ModelSource {
        cachedModel.source
    }

    init(cached cachedModel: CachedModel) {
        self.cachedModel = cachedModel
    }

    public func update() {
        do {
            try cachedModel.update()
        } catch {
        }
    }

    private var loadingTask: Task<LlamaModel, any Swift.Error>?

    var llamaModel: LlamaModel? {
        get async throws {
            try await loadingTask?.value
        }
    }

    public func load() {
        update()

        guard case .available(let url) = cachedModel.state else {
            return
        }

        loadingTask = Task {
            try await LlamaModel(url: url)
        }
    }

    public func download() {
        update()

        guard case .unavailable = cachedModel.state else {
            return
        }

        Task {
            do {
                try await cachedModel.download()
                load()
            } catch {
            }
        }
    }

    public func purge() {
        update()

        do {
            try cachedModel.purge()
            loadingTask = nil
        } catch {
        }
    }
}

@MainActor
@Observable
final class PreviewModel: ModelProtocol {
    private(set) var state: ModelState = .unavailable

    let source: ModelSource

    init() {
        source = ModelSource(
            name: "Preview",
            wegpageURL: URL(string: "http://example.com")!,
            url: URL(filePath: "http://example.com")!
        )
    }

    func update() {
        state = .available(URL(filePath: "/tmp"))
    }

    func load() {
    }

    func download() {
        Task {
            do {
                state = .downloading(nil)

                try await Task.sleep(nanoseconds: 300_000_000)
                let progress = Progress(totalUnitCount: 2)
                state = .downloading(progress)

                try await Task.sleep(nanoseconds: 500_000_000)
                progress.completedUnitCount = 1

                try await Task.sleep(nanoseconds: 500_000_000)
                progress.completedUnitCount = 2

                state = .available(URL(filePath: "/tmp"))
            } catch {
            }
        }
    }

    func purge() {
        state = .unavailable
    }
}

extension AnyModel {
    public static var preview: AnyModel {
        PreviewModel().eraseToAnyModel()
    }
}
