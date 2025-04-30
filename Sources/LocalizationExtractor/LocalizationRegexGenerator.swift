//
//  LocalizationRegexGenerator.swift
//  LocalizationExtractor
//
//  Created by mohammed souiden on 4/29/25.
//

/// A utility to dynamically generate regex patterns based on a localization example input.
public struct LocalizationRegexGenerator {
    public static func generatePatterns(from example: String) -> [String] {
        var patterns: [String] = []

        // Normalize example
        let normalizedExample = example.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalizedExample.contains(".localized(comment:") {
            // Match "key".localized(comment: "comment")
            patterns.append(#""([^"]+)"\s*\.localized\s*\(\s*comment:\s*"([^"]+)"\)"#)
        }
        if normalizedExample.contains(".localized(") && normalizedExample.contains("\"") && !normalizedExample.contains("comment:") {
            // Match "key".localized("comment")
            patterns.append(#""([^"]+)"\s*\.localized\s*\(\s*"([^"]+)"\)"#)
        }
        if normalizedExample.contains(".localized") && !normalizedExample.contains("(") {
            // Match "key".localized
            patterns.append(#""([^"]+)"\s*\.localized"#)
        }
        if normalizedExample.contains("LocalizedString(") {
            // Match NSLocalizedString("key", comment: "comment")
            patterns.append(#"\w+LocalizedString\(\s*"([^"]+)"\s*,\s*comment:\s*"([^"]+)"\)"#)
        }

        if patterns.isEmpty {
            print("⚠️ Could not auto-detect localization format from example.")
        }

        return patterns
    }
}
