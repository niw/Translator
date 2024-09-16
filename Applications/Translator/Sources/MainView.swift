//
//  MainView.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 8/19/24.
//

import Foundation
import SwiftUI
import TranslatorSupport

private extension Translator.Mode {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .automatic:
            LocalizedStringKey("Automatic")
        case .englishToJapanese:
            LocalizedStringKey("English to Japanese")
        case .japaneseToEnglish:
            LocalizedStringKey("Japanese to English")
        }
    }
}

private extension Translator.Style {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .casual:
            LocalizedStringKey("Casual")
        case .formal:
            LocalizedStringKey("Formal")
        case .technical:
            LocalizedStringKey("Technical")
        case .journalistic:
            LocalizedStringKey("Journalistic")
        case .webFiction:
            LocalizedStringKey("Web Fiction")
        case .business:
            LocalizedStringKey("Business")
        case .nsfw:
            LocalizedStringKey("NSFW")
        case .educationalCasual:
            LocalizedStringKey("Educational Casual")
        case .academicPresentation:
            LocalizedStringKey("Academic Presentation")
        case .slang:
            LocalizedStringKey("Slang")
        case .snsCasual:
            LocalizedStringKey("Social Network Casual")
        }
    }
}

struct MainView: View {
    @Environment(TranslatorService.self)
    private var translatorService

    var body: some View {
        let translatorServiceBindable = Bindable(translatorService)

        VStack {
            switch translatorService.model.state {
            case .available:
                EmptyView()
            case .unavailable:
                HStack {
                    Text("Model is not available yet.")
                    Button("Download") {
                        translatorService.downloadModel()
                    }
                }
                .scenePadding()
            case .loading(let progress):
                HStack {
                    if let progress {
                        ProgressView(progress)
                        Button("Cancel") {
                            progress.cancel()
                        }
                    } else {
                        Text("Loading…")
                    }
                }
                .scenePadding()
            }

            HStack {
                Picker(selection: translatorServiceBindable.mode) {
                    ForEach(Translator.Mode.allCases, id: \.rawValue) { mode in
                        Text(mode.localizedStringKey)
                            .tag(mode)
                    }
                } label: {
                    Text("Mode")
                }
                .fixedSize()

                Picker(selection: translatorServiceBindable.style) {
                    ForEach(Translator.Style.allCases, id: \.rawValue) { style in
                        Text(style.localizedStringKey)
                            .tag(style)
                    }
                } label: {
                    Text("Style")
                }
                .fixedSize()
            }
            .scenePadding()

            HStack {
                TextEditor(text: translatorServiceBindable.sourceString)
                TextEditor(text: .constant(translatorService.translatedString))
            }
            .font(.system(size: 16.0))

            ZStack {
                HStack {
                    Button("Paste") {
                        if let string = NSPasteboard.general.string(forType: .string) {
                            translatorService.sourceString = string
                        }
                    }

                    Button("Clear") {
                        translatorService.sourceString = ""
                        translatorService.translatedString = ""
                    }

                    Button("Translate") {
                        Task {
                            do {
                                try await translatorService.translate()
                            } catch {
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(translatorService.sourceString.isEmpty)

                    Button("Use as source text") {
                        translatorService.sourceString = translatorService.translatedString
                    }
                }

                HStack {
                    Spacer()

                    if translatorService.isTranslating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .padding(.horizontal, 4.0)
                    }
                }
            }
            .scenePadding()
        }
    }
}
