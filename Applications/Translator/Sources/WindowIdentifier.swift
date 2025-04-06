//
//  WindowIdentifier.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 9/22/24.
//

import Foundation

enum WindowIdentifier: String {
    case main

    var localizedName: String {
        switch self {
        case .main:
            Bundle.main.localizedName
        }
    }
}
