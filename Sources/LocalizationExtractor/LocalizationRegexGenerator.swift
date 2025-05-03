//
//  LocalizationRegexGenerator.swift
//  LocalizationExtractor
//
//  Created by mohammed souiden on 4/29/25.
//

/// A utility to dynamically generate regex patterns based on a localization example input.
public struct LocalizationRegexGenerator {
    /// Generates a list of regular expression patterns that match the structure of a given localization usage example.
    /// This method tries to recognize common Swift localization formats such as `.localized`, `NSLocalizedString`, and SwiftGen-style keys.
    ///
    /// - Parameter example: A sample string showing how localization is used in the codebase.
    /// - Returns: An array of regex patterns suitable for extracting localization keys and comments.
    public static func generatePatterns(from example: String) -> [String] {
        var patterns: [String] = []

        let normalizedExample = example.trimmingCharacters(in: .whitespacesAndNewlines)

        // Matches: "key".localized(comment: "comment")
        if normalizedExample.contains(".localized(comment:") {
            patterns.append(#""((?:[^"\\]|\\.)+)"\s*\.localized\s*\(\s*comment:\s*"((?:[^"\\]|\\.)+)"\)"#)
        }
        // Matches: "key".localized("comment")
        if normalizedExample.contains(".localized(") && normalizedExample.contains("\"") && !normalizedExample.contains("comment:") {
            patterns.append(#""((?:[^"\\]|\\.)+)"\s*\.localized\s*\(\s*"((?:[^"\\]|\\.)+)"\)"#)
        }
        // Matches: "key".localized
        if normalizedExample.contains(".localized") && !normalizedExample.contains("(") {
            patterns.append(#""((?:[^"\\]|\\.)+)"\s*\.localized"#)
        }

        // Matches: MKLocalizedString("key", comment: "comment")
        if normalizedExample.contains("LocalizedString(") {
            patterns.append(#"[A-Za-z_][\w]*LocalizedString\(\s*"((?:[^"\\]|\\.)+)"(?:\s*,\s*defaultValue:\s*\".*?\")?\s*,\s*comment:\s*\"([\s\S]*?)\"\s*\)"#)
        }

        // Matches: NSLocalizedString("key")
        if normalizedExample.contains("NSLocalizedString") && !normalizedExample.contains("comment:") {
            patterns.append(#"NSLocalizedString\(\s*"((?:[^"\\]|\\.)+)"\s*\)"#)
        }

        // Matches: NSLocalizedString("key", comment: "comment")
        if normalizedExample.contains("NSLocalizedString") && normalizedExample.contains("comment:") {
            patterns.append(#"NSLocalizedString\(\s*"((?:[^"\\]|\\.)+)"\s*,\s*comment:\s*"((?:[^"\\]|\\.)+)"\s*\)"#)
        }

        // Matches SwiftGen-style keys like L10n.some.section.key
        if normalizedExample.contains("L10n.") {
            patterns.append(#"L10n\.[a-zA-Z0-9_.]+"#)
        }

        if patterns.isEmpty {
            print("⚠️ Could not auto-detect localization format from example.")
        }

        return patterns
    }
}
