import Foundation

/// A utility engine to scan Swift files, extract localization keys, and update `.strings` localization files.
public class LocalizationExtractorEngine {

    public struct KeyChangeSummary: Sendable {
        public let new: [String]
        public let missing: [String]
        public let changed: [String]
    }

    private static let keyChangeStore = KeyChangeStore()

    public static func lastKeyChanges() async -> KeyChangeSummary {
        await keyChangeStore.get()
    }

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

    /// Extracts localization keys and associated comments from Swift file content.
    ///
    /// - Parameters:
    ///   - fileContent: The text content of a Swift file.
    ///   - patterns: An array of regex patterns that capture key and comment.
    ///   - log: Optional logger.
    /// - Returns: Dictionary where keys are localization keys and values are extracted comments.
    public static func extractLocalizedKeysAndComments(from fileContent: String, patterns: [String], log: ((String) -> Void)? = nil) -> [String: String] {
        var results = [String: String]()

        for pattern in patterns {
            log?("🔵 Using regex pattern: \(pattern)")

            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsrange = NSRange(fileContent.startIndex..<fileContent.endIndex, in: fileContent)
                let matches = regex.matches(in: fileContent, range: nsrange)
                log?("🔎 Matches found: \(matches.count)")

                for match in matches {
                    if let keyRange = Range(match.range(at: 1), in: fileContent) {
                        let key = String(fileContent[keyRange])
                        var comment = key // fallback to key itself

                        if match.numberOfRanges >= 3, let commentRange = Range(match.range(at: 2), in: fileContent) {
                            let extractedComment = String(fileContent[commentRange])
                            comment = extractedComment.isEmpty ? key : extractedComment
                        } else {
                            comment = key
                        }

                        results[key] = comment
                        log?("🟢 Key extracted: \(key) with comment: \(comment)")
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

    // MARK: - Key Changes Analysis

    public static func analyzeKeyChanges(
        extractedKeys: Set<String>,
        existingTranslations: [String: String]
    ) -> KeyChangeSummary {
        let existingKeys = Set(existingTranslations.keys)
        let newKeys = extractedKeys.subtracting(existingKeys)
        let missingKeys = existingKeys.subtracting(extractedKeys)
        let changedKeys = extractedKeys.intersection(existingKeys).filter { key in
            return existingTranslations[key] != key
        }
        return KeyChangeSummary(
            new: Array(newKeys).sorted(),
            missing: Array(missingKeys).sorted(),
            changed: Array(changedKeys).sorted()
        )
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
    ///   - includeComments: Flag indicating whether to extract comments along with keys.
    ///   - log: Closure to handle logging messages.
    public static func runExtraction(
        projectPath: String,
        localizationBaseURL: URL,
        localizationFolders: [String],
        localizationFileName: String,
        patterns: [String],
        includeComments: Bool,
        log: @escaping (String) -> Void
    ) {
        var extractedComments = [String: String]()

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
                if includeComments {
                    let keyComments = extractLocalizedKeysAndComments(from: content, patterns: patterns, log: log)
                    for (key, comment) in keyComments {
                        keysGroupedByFile[fileName, default: []].insert(key)
                        extractedComments[key] = comment
                    }
                } else {
                    let keys = extractLocalizedKeys(from: content, patterns: patterns, log: log)
                    keysGroupedByFile[fileName, default: []].formUnion(keys)
                }
            }
        }

        let allKeys = keysGroupedByFile.values.flatMap { $0 }
        let allKeysSet = Set(allKeys)
        log("🟢 Extracted \(allKeys.count) unique localizable keys.")

        if let firstLangDir = localizationFolders.first {
            let langDirURL = localizationBaseURL.appendingPathComponent(firstLangDir)
            let localizationFileURL = langDirURL.appendingPathComponent(localizationFileName)
            let existingTranslations = loadExistingTranslations(from: localizationFileURL.path)
            Task {
                await keyChangeStore.set(analyzeKeyChanges(extractedKeys: allKeysSet, existingTranslations: existingTranslations))
            }
        } else {
            Task {
                await keyChangeStore.set(.init(new: [], missing: [], changed: []))
            }
        }

        for langDir in localizationFolders {
            let langDirURL = localizationBaseURL.appendingPathComponent(langDir)
            let localizationFileURL = langDirURL.appendingPathComponent(localizationFileName)
            let existingTranslations = loadExistingTranslations(from: localizationFileURL.path)
            var lines = [String]()

            for (fileName, keys) in keysGroupedByFile.sorted(by: { $0.key < $1.key }) where !keys.isEmpty {
                lines.append("\n/* ===== \(fileName) ===== */")
                for key in keys.sorted() {
                    let value = existingTranslations[key] ?? key
                    if includeComments {
                        let comment = extractedComments[key] ?? key
                        lines.append("/* \(comment) */\n\"\(key)\" = \"\(value)\";")
                    } else {
                        lines.append("\"\(key)\" = \"\(value)\";")
                    }
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

actor KeyChangeStore {
    private var value: LocalizationExtractorEngine.KeyChangeSummary = .init(new: [], missing: [], changed: [])

    func get() -> LocalizationExtractorEngine.KeyChangeSummary {
        return value
    }

    func set(_ newValue: LocalizationExtractorEngine.KeyChangeSummary) {
        value = newValue
    }
}
