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

    @Environment(\.openSettings)
    private var openSettings

    var body: some View {
        let translatorServiceBindable = Bindable(translatorService)

        VStack(spacing: 0.0) {
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

                    Spacer()

                    Button("Use as source") {
                        translatorService.sourceString = translatorService.translatedString
                    }
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
                .controlSize(.large)
                .disabled(translatorService.sourceString.isEmpty)
            }
            .scenePadding()
        }
        .toolbar {
            ToolbarItem {
            }

            if translatorService.isTranslating {
                ToolbarItem {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                }
            }

            ToolbarItem {
                Picker(selection: translatorServiceBindable.mode) {
                    ForEach(Translator.Mode.allCases, id: \.rawValue) { mode in
                        Text(mode.localizedStringKey)
                            .tag(mode)
                    }
                } label: {
                    Text("Mode")
                }
                .fixedSize()
            }

            ToolbarItem {
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
        }
        .onAppear {
            translatorService.updateModel()

            if case .unavailable = translatorService.modelState {
                openSettings()
            }
        }
    }
}
