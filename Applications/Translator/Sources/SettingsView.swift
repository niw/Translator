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
    @Environment(TranslatorService.self)
    private var translatorService

    var body: some View {
        // FIXME: This layout is not preferred.
        Grid(alignment: .leading, horizontalSpacing: 20.0, verticalSpacing: 10.0) {
            GridRow {
                Text("Name:")
                    .gridColumnAlignment(.trailing)

                Text(translatorService.modelSource.name)
            }

            GridRow {
                Text("Details:")
                    .gridColumnAlignment(.trailing)

                Link(destination: translatorService.modelSource.wegpageURL) {
                    Text("Show details")
                }
            }

            GridRow(alignment: .top) {
                Text("File:")
                    .gridColumnAlignment(.trailing)

                switch translatorService.modelState {
                case .unavailable:
                    Button("Download") {
                        translatorService.downloadModel()
                    }

                case .loading(let progress):
                    if let progress {
                        VStack(alignment: .leading) {
                            ProgressView(progress)
                                .frame(width: 200.0)

                            Button("Cancel") {
                                progress.cancel()
                            }
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
                            translatorService.purgeModel()
                        } label: {
                            Text("Delete")
                        }
                    }
                }
            }
        }
        .frame(width: 500.0)
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
