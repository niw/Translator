//
//  Model.swift
//  TranslatorSupport
//
//  Created by Yoshimasa Niwa on 9/17/24.
//

import Foundation
import Observation
import LlamaModel

@MainActor
@Observable
public final class Model {
    public enum State {
        case unavailable
        case downloading(Progress?)
        case available(URL)
    }

    public var state: State {
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
