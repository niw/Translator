//
//  Bundle.swift
//  Translator
//
//  Created by Yoshimasa Niwa on 4/7/25.
//

import Foundation

extension Bundle {
    var localizedName: String {
        for case let infoDictionary? in [
            localizedInfoDictionary,
            infoDictionary
        ] {
            for key in [
                "CFBundleDisplayName",
                "CFBundleName"
            ] {
                if let localizedName = infoDictionary[key] as? String {
                    return localizedName
                }
            }
        }

        // Should not reach here.
        return ""
    }
}
