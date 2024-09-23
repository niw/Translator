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
        case .autoDetect:
            LocalizedStringKey("Detect")
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
    @Environment(AnyTranslatorService.self)
    private var translatorService

    @Environment(\.openSettings)
    private var openSettings

    var body: some View {
        @Bindable
        var translatorService = translatorService

        VStack(spacing: 0.0) {
            HSplitView {
                TextEditor(text: $translatorService.inputString)
                TextEditor(text: .constant(translatorService.translatedString))
            }
            .font(.system(size: 16.0))

            Divider()

            HStack {
                Spacer()

                if translatorService.isTranslating {
                    HStack {
                        Text("Translating…")
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    .controlSize(.small)
                    .scenePadding(.horizontal)
                }
            }
            .frame(height: 24.0)
            .background(.windowBackground)
        }
        .toolbar {
            ToolbarItemGroup {
                if !translatorService.isAutomaticTranslationEnabled {
                    Button {
                        Task {
                            do {
                                try await translatorService.translate()
                            } catch {
                            }
                        }
                    } label: {
                        Text("Translate")
                    }
                    .disabled(translatorService.inputString.isEmpty)
                }

                Toggle(isOn: $translatorService.isAutomaticTranslationEnabled) {
                    Label {
                        Text("Automatic")
                    } icon: {
                        Image(systemName: "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36.0, height: 12.0)
                    }
                }
            }

            ToolbarItemGroup {
                Button {
                    if let string = NSPasteboard.general.string(forType: .string) {
                        translatorService.inputString = string
                    }
                } label: {
                    Label {
                        Text("Paste")
                    } icon: {
                        Image(systemName: "doc.on.clipboard")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36.0, height: 16.0)
                    }
                }

                Button {
                    translatorService.inputString = ""
                    translatorService.translatedString = ""
                } label: {
                    Label {
                        Text("Clear")
                    } icon: {
                        Image(systemName: "clear")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36.0, height: 16.0)
                    }
                }

                Button {
                    translatorService.inputString = translatorService.translatedString
                } label: {
                    Label {
                        Text("Use as input")
                    } icon: {
                        Image(systemName: "arrow.uturn.left")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36.0, height: 16.0)
                    }
                }
                .disabled(translatorService.translatedString.isEmpty)
            }

            ToolbarItemGroup {
                Picker(selection: $translatorService.mode) {
                    ForEach(Translator.Mode.allCases, id: \.rawValue) { mode in
                        Text(mode.localizedStringKey)
                            .tag(mode)
                    }
                } label: {
                    Text("Mode")
                }
                .fixedSize()

                Picker(selection: $translatorService.style) {
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
            translatorService.model.update()

            if case .unavailable = translatorService.model.state {
                // This delay is needed to take Settings over Main window
                // when it is opened by `openWindow(id:)`.
                Task {
                    openSettings()
                }
            }
        }
    }
}

#Preview {
    MainView()
        .environment(PreviewTranslatorService().eraseToAnyTranslatorService())
}
