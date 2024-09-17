//
//  ModelSource.swift
//  TranslatorSupport
//
//  Created by Yoshimasa Niwa on 8/30/24.
//

import Foundation

public struct ModelSource: Sendable {
    public var name: String
    public var wegpageURL: URL
    public var url: URL
}

extension ModelSource {
    public static let `default` = ModelSource(
        name: "C3TR-Adapter-Q4_k_m",
        wegpageURL: URL(string: "https://huggingface.co/webbigdata/C3TR-Adapter_gguf")!,
        url: URL(string: "https://huggingface.co/webbigdata/C3TR-Adapter_gguf/resolve/main/C3TR-Adapter-Q4_k_m.gguf")!
    )
}
