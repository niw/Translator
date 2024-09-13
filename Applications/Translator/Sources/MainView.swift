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
    @Environment(MainService.self)
    private var mainService

    var body: some View {
        let mainServiceBindable = Bindable(mainService)

        VStack {
            switch mainService.cachedTranslatorModel.state {
            case .available:
                EmptyView()
            case .unavailable:
                HStack {
                    Text("Model is not available yet.")
                    Button("Download") {
                        mainService.downloadModel()
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
                Picker(selection: mainServiceBindable.mode) {
                    ForEach(Translator.Mode.allCases, id: \.rawValue) { mode in
                        Text(mode.localizedStringKey)
                            .tag(mode)
                    }
                } label: {
                    Text("Mode")
                }
                .fixedSize()

                Picker(selection: mainServiceBindable.style) {
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
                TextEditor(text: mainServiceBindable.sourceString)
                TextEditor(text: .constant(mainService.translatedString))
            }
            .font(.system(size: 16.0))

            ZStack {
                HStack {
                    Button("Paste") {
                        if let string = NSPasteboard.general.string(forType: .string) {
                            mainService.sourceString = string
                        }
                    }

                    Button("Clear") {
                        mainService.sourceString = ""
                        mainService.translatedString = ""
                    }

                    Button("Translate") {
                        Task {
                            do {
                                try await mainService.translate()
                            } catch {
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(mainService.sourceString.isEmpty)

                    Button("Use as source text") {
                        mainService.sourceString = mainService.translatedString
                    }
                }

                HStack {
                    Spacer()

                    if mainService.isTranslating {
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
