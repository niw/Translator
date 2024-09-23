//
//  SettingsView.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 9/16/24.
//

import AppKit
import Foundation
import SwiftUI
import TranslatorSupport

struct ModelSettingsView: View {
    @Environment(AnyTranslatorService.self)
    private var translatorService

    var body: some View {
        // FIXME: This layout is not preferred.
        Grid(alignment: .leading, verticalSpacing: 10.0) {
            GridRow {
                Text("Name:")
                    .gridColumnAlignment(.trailing)

                Text(translatorService.model.source.name)
            }

            GridRow {
                Text("Details:")
                    .gridColumnAlignment(.trailing)

                Link(destination: translatorService.model.source.wegpageURL) {
                    Text("Show details")
                }
            }

            GridRow(alignment: .top) {
                Text("File:")
                    .gridColumnAlignment(.trailing)

                switch translatorService.model.state {
                case .unavailable:
                    Button("Download") {
                        translatorService.model.download()
                    }

                case .downloading(let progress):
                    if let progress {
                        HStack(alignment: .center) {
                            ProgressView(progress)
                                .frame(width: 200.0)

                            Button("Cancel", systemImage: "xmark", role: .cancel) {
                                progress.cancel()
                            }
                            .symbolVariant(.circle)
                            .symbolVariant(.fill)
                            .buttonStyle(.borderless)
                            .labelStyle(.iconOnly)
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                    }

                case .available(let url):
                    VStack(alignment: .leading) {
                        Link(destination: url.deletingLastPathComponent()) {
                            Text("\(url.lastPathComponent)")
                        }
                        .environment(\.openURL, OpenURLAction { url in
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                            return .handled
                        })

                        Button(role: .destructive) {
                            translatorService.model.purge()
                        } label: {
                            Text("Delete")
                        }
                    }
                }
            }
        }
        .frame(width: 500.0)
        .onAppear {
            translatorService.model.update()
        }
    }
}

struct SettingsView: View {
    enum Tab {
        case Model
    }

    var body: some View {
        TabView {
            ModelSettingsView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Model")
                }
                .tag(Tab.Model)
        }
        .scenePadding()
    }
}

#Preview {
    SettingsView()
        .environment(AnyTranslatorService.preview)
}
