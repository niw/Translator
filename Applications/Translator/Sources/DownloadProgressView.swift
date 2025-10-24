//
//  DownloadProgressView.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 10/23/25.
//

import Foundation
import SwiftUI
import TranslatorSupport

public struct DownloadProgressView<Label>: View where Label: View {
    var progress: DownloadProgress

    var label: () -> Label

    public init(_ progress: DownloadProgress, @ViewBuilder label: @escaping () -> Label) {
        self.progress = progress
        self.label = label
    }

    private var value: Double? {
        if let totalBytes = progress.totalBytes {
            Double(progress.downloadedBytes) / Double(totalBytes)
        } else {
            nil
        }
    }

    private func currentValueLabel() -> some View {
        // ByteCountFormatStyle can't control padding fraction digits.
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true

        return Group {
            if let totalBytes = progress.totalBytes {
                let downloadedBytesString = formatter.string(fromByteCount: progress.downloadedBytes)
                let totalBytesString = formatter.string(fromByteCount: totalBytes)

                Text("\(downloadedBytesString) of \(totalBytesString)")
            } else {
                Text(formatter.string(fromByteCount: progress.downloadedBytes))
            }
        }
        .monospacedDigit()
    }

    public var body: some View {
        ProgressView(value: value) {
            label()
        } currentValueLabel: {
            currentValueLabel()
        }
    }
}

extension DownloadProgressView where Label == EmptyView {
    public init(_ progress: DownloadProgress) {
        self.init(progress) {
            EmptyView()
        }
    }
}

#Preview {
    DownloadProgressView(DownloadProgress(
        downloadedBytes: 512 * 1024,
        totalBytes: 1024 * 1024
    ))
}
