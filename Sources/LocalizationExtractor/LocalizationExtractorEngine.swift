// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// A utility engine to scan Swift files, extract localization keys, and update `.strings` localization files.
public class LocalizationExtractorEngine {

    // MARK: - Scanning Swift Files

    /// Recursively scans the given directory path for `.swift` files.
    ///
    /// - Parameters:
    ///   - path: The root directory path to start scanning.
    ///   - log: Optional logging closure for debug information.
    /// - Returns: An array of file paths for all `.swift` files found.
    public static func getSwiftFiles(at path: String, log: ((String) -> Void)? = nil) -> [String] {
        var swiftFiles: [String] = []

        func scanDirectory(_ url: URL) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                log?("📂 Scanning folder: \(url.path)")

                for fileURL in contents {
                    var isDirectory: ObjCBool = false
                    let exists = FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory)
                    log?("🔍 Found: \(fileURL.path)  | exists: \(exists), isDirectory: \(isDirectory.boolValue)")

                    if isDirectory.boolValue {
                        scanDirectory(fileURL) // Recursive
                    } else if fileURL.pathExtension == "swift" {
                        log?("🟢 Swift file detected: \(fileURL.path)")
                        swiftFiles.append(fileURL.path)
                    }
                }
            } catch {
                log?("❌ Could not access contents of: \(url.path) — Error: \(error.localizedDescription)")
            }
        }

        scanDirectory(URL(fileURLWithPath: path))
        return swiftFiles
    }

    // MARK: - Extracting Localized Keys

    /// Extracts localization keys from the given Swift file content using provided regex patterns.
    ///
    /// - Parameters:
    ///   - fileContent: The text content of a Swift file.
    ///   - patterns: An array of regular expression patterns to identify localization keys.
    ///   - log: Optional logging closure for debug information.
    /// - Returns: A set of extracted localization keys.
    public static func extractLocalizedKeys(from fileContent: String, patterns: [String], log: ((String) -> Void)? = nil) -> Set<String> {
        var results = Set<String>()
        for pattern in patterns {
            log?("🔵 Using regex pattern: \(pattern)")
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsrange = NSRange(fileContent.startIndex..<fileContent.endIndex, in: fileContent)
                let matches = regex.matches(in: fileContent, range: nsrange)
                log?("🔎 Matches found: \(matches.count)")

                for match in matches {
                    if let range = Range(match.range(at: 1), in: fileContent) {
                        let key = String(fileContent[range])
                        log?("🟢 Key extracted: \(key)")
                        results.insert(key)
                    }
                }
            } else {
                log?("❌ Invalid regex: \(pattern)")
            }
        }
        return results
    }

    // MARK: - Loading Existing Translations

    /// Loads existing key-value pairs from a `.strings` localization file.
    ///
    /// - Parameter path: The file system path to the `.strings` file.
    /// - Returns: A dictionary containing existing translation keys and values.
    public static func loadExistingTranslations(from path: String) -> [String: String] {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return [:] }
        var translations = [String: String]()
        let pattern = #"\"([^\"]+)\"\s*=\s*\"([^\"]*)\";"#

        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsrange = NSRange(content.startIndex..<content.endIndex, in: content)
            let matches = regex.matches(in: content, range: nsrange)
            for match in matches {
                if let keyRange = Range(match.range(at: 1), in: content),
                   let valueRange = Range(match.range(at: 2), in: content) {
                    let key = String(content[keyRange])
                    let value = String(content[valueRange])
                    translations[key] = value
                }
            }
        }
        return translations
    }

    // MARK: - Main Extraction Entry

    /// Executes the full localization extraction process.
    ///
    /// - Parameters:
    ///   - projectPath: The path to the Swift project source code.
    ///   - localizationBaseURL: The base URL where localization directories are located.
    ///   - localizationFolders: A list of localization subdirectories (e.g., `["en.lproj", "fr.lproj"]`).
    ///   - localizationFileName: The filename of the `.strings` file (usually `"Localizable.strings"`).
    ///   - patterns: The regex patterns used to detect localization keys.
    ///   - log: Closure to handle logging messages.
    public static func runExtraction(
        projectPath: String,
        localizationBaseURL: URL,
        localizationFolders: [String],
        localizationFileName: String,
        patterns: [String],
        log: @escaping (String) -> Void
    ) {
        guard !projectPath.isEmpty else {
            log("❗ Please select a project path first.")
            return
        }

        guard !localizationBaseURL.path.isEmpty else {
            log("❗ Please select a localization base folder first.")
            return
        }

        let swiftFiles = getSwiftFiles(at: projectPath, log: log)
        log("🔵 Found \(swiftFiles.count) Swift files to scan.")

        var keysGroupedByFile = [String: Set<String>]()
        for filePath in swiftFiles {
            if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                let keys = extractLocalizedKeys(from: content, patterns: patterns, log: log)
                keysGroupedByFile[fileName, default: []].formUnion(keys)
            }
        }

        let allKeys = keysGroupedByFile.values.flatMap { $0 }
        log("🟢 Extracted \(allKeys.count) unique localizable keys.")

        for langDir in localizationFolders {
            let langDirURL = localizationBaseURL.appendingPathComponent(langDir)
            let localizationFileURL = langDirURL.appendingPathComponent(localizationFileName)
            let existingTranslations = loadExistingTranslations(from: localizationFileURL.path)
            var lines = [String]()

            for (fileName, keys) in keysGroupedByFile.sorted(by: { $0.key < $1.key }) where !keys.isEmpty {
                lines.append("\n/* ===== \(fileName) ===== */")
                for key in keys.sorted() {
                    let value = existingTranslations[key] ?? key
                    lines.append("\"\(key)\" = \"\(value)\";")
                }
            }

            let finalContent = lines.joined(separator: "\n")
            do {
                try FileManager.default.createDirectory(at: langDirURL, withIntermediateDirectories: true, attributes: nil)
                try finalContent.write(to: localizationFileURL, atomically: true, encoding: .utf8)
                log("✅ Updated \(localizationFileURL.path)")
            } catch {
                log("❌ Failed to write to \(localizationFileURL.path): \(error.localizedDescription)")
            }
        }
        log("✅ Extraction completed at \(Date()).")
    }
}
