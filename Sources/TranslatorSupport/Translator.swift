//
//  Translator.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 8/30/24.
//

import Foundation
import LlamaModel

public struct Translator: Sendable {
    fileprivate enum Direction: String {
        case englishToJapanese = "English to Japanese"
        case japaneseToEnglish = "Japanese to English"
    }

    public enum Mode: String, CaseIterable {
        case automatic
        case englishToJapanese
        case japaneseToEnglish

        fileprivate func direction(for string: String) -> Direction {
            switch self {
            case .automatic:
                let totalCount = string.unicodeScalars.count
                let asciiCount = string.unicodeScalars.count { $0.isASCII }
                if asciiCount < totalCount * 3 / 4 {
                    return .japaneseToEnglish
                } else {
                    return .englishToJapanese
                }
            case .englishToJapanese:
                return .englishToJapanese
            case .japaneseToEnglish:
                return .japaneseToEnglish
            }
        }
    }

    // See <https://huggingface.co/webbigdata/C3TR-Adapter/discussions/1#669e6ef419d0f96d8a77128b>
    public enum Style: String, CaseIterable {
        case casual
        case formal
        case technical
        case journalistic
        case webFiction = "web-fiction"
        case business
        case nsfw
        case educationalCasual = "educational-casual"
        case academicPresentation = "academic-presentation"
        case slang
        case snsCasual = "sns-casual"
    }

    // See <https://huggingface.co/webbigdata/C3TR-Adapter_gguf>
    private static let template =
        """
        You are a highly skilled professional Japanese-English and English-Japanese translator. Translate the given text accurately, taking into account the context and specific instructions provided. Steps may include hints enclosed in square brackets [] with the key and value separated by a colon:. Only when the subject is specified in the Japanese sentence, the subject will be added when translating into English. If no additional instructions or context are provided, use your expertise to consider what the most appropriate context is and provide a natural translation that aligns with that context. When translating, strive to faithfully reflect the meaning and tone of the original text, pay attention to cultural nuances and differences in language usage, and ensure that the translation is grammatically correct and easy to read. After completing the translation, review it once more to check for errors or unnatural expressions. For technical terms and proper nouns, either leave them in the original language or use appropriate translations as necessary. Take a deep breath, calm down, and start translating.

        <start_of_turn>### Instruction:
        Translate %@.
        When translating, please use the following hints:
        [writing_style: %@]

        ### Input:
        %@
        <end_of_turn>
        <start_of_turn>### Response:

        """

    var model: LlamaModel

    public init(modelURL: URL) async throws {
        model = try await LlamaModel(url: modelURL)
    }

    public func translate(_ string: String, mode: Mode = .automatic, style: Style = .technical) -> AsyncThrowingStream<String, any Swift.Error> {
        let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let direction = mode.direction(for: string)
        let text = String(format: Self.template, direction.rawValue, style.rawValue, string)
        return model.complete(text: text)
    }
}
