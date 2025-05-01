import Testing
import Foundation
@testable import LocalizationExtractor

struct LocalizationExtractorTests {
    @Test func testExtractLocalizedKeys() async throws {
        let sampleContent = """
    let title = "hello_world".localized
    let button = NSLocalizedString("submit_button", comment: "")
    """
        let patterns = [
            "\"([^\"]+)\"\\s*\\.localized",
            "NSLocalizedString\\(\\s*\"([^\"]+)\""
        ]

        let extracted = LocalizationExtractorEngine.extractLocalizedKeys(from: sampleContent, patterns: patterns)
        #expect(extracted.contains("hello_world"))
        #expect(extracted.contains("submit_button"))
        #expect(extracted.count == 2)
    }

    @Test func testExtractLocalizedKeysAndComments() async throws {
        let sampleContent = """
    let alertTitle = MKLocalizedString("appointment-details.appointment-cancelled.alert.title", comment: "Title of the cancel alert")
    let okButton = NSLocalizedString("ok_button", comment: "OK button title")
    let noComment = NSLocalizedString("simple_key", comment: "")
    """

        let patterns = [
            #"\"([^\"]+)\"\s*\.localized"#,
            #"NSLocalizedString\(\s*\"([^\"]+)\"\s*,\s*comment:\s*\"([^\"]*)\"\)"#,
            #"MKLocalizedString\(\s*\"([^\"]+)\"\s*,\s*comment:\s*\"([^\"]*)\"\)"#
        ]

        let extracted = LocalizationExtractorEngine.extractLocalizedKeysAndComments(from: sampleContent, patterns: patterns)

        #expect(extracted["appointment-details.appointment-cancelled.alert.title"] == "Title of the cancel alert")
        #expect(extracted["ok_button"] == "OK button title")
        #expect(extracted["simple_key"] == "simple_key") // fallback when comment is empty
        #expect(extracted.count == 3)
    }

    @Test func testLoadExistingTranslations() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Localizable.strings")

        let fileContent = """
    "greeting" = "Hello";
    "farewell" = "Goodbye";
    """
        try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)

        let translations = LocalizationExtractorEngine.loadExistingTranslations(from: fileURL.path)
        #expect(translations["greeting"] == "Hello")
        #expect(translations["farewell"] == "Goodbye")
    }


    @Test func testLocalizationRegexGenerator() async throws {
        let examplesAndExpectedPatterns: [(String, [String])] = [
            (
                #""hello".localized(comment: "Hello comment")"#,
                [#""((?:[^"\\]|\\.)+)"\s*\.localized\s*\(\s*comment:\s*"((?:[^"\\]|\\.)+)"\)"#]
            ),
            (
                #""cancel".localized("Cancel comment")"#,
                [#""((?:[^"\\]|\\.)+)"\s*\.localized\s*\(\s*"((?:[^"\\]|\\.)+)"\)"#]
            ),
            (
                #""ok".localized"#,
                [#""((?:[^"\\]|\\.)+)"\s*\.localized"#]
            ),
            (
                #"NSLocalizedString("save", comment: "Save comment")"#,
                [
                    #"[A-Za-z_][\w]*LocalizedString\(\s*"((?:[^"\\]|\\.)+)"(?:\s*,\s*comment:\s*"((?:[^"\\]|\\.)+)")?\s*\)"#,
                    #"NSLocalizedString\(\s*"((?:[^"\\]|\\.)+)"\s*,\s*comment:\s*"((?:[^"\\]|\\.)+)"\s*\)"#
                ]
            ),
            (
                #"NSLocalizedString("plain_key")"#,
                [#"NSLocalizedString\(\s*"((?:[^"\\]|\\.)+)"\s*\)"#]
            ),
            (
                #"L10n.alert.cancel"#,
                [#"L10n\.[a-zA-Z0-9_.]+"#]
            )
        ]

        for (example, expected) in examplesAndExpectedPatterns {
            let generated = LocalizationRegexGenerator.generatePatterns(from: example)
            for pattern in expected {
                #expect(generated.contains(pattern), "Missing pattern: \(pattern) for example: \(example)")
            }
        }
    }

    @Test func testAnalyzeKeyChanges() async throws {
        let existingTranslations = [
            "hello": "Hello",
            "bye": "Goodbye",
            "unused": "Unused"
        ]

        let extractedKeys: Set<String> = ["hello", "welcome", "bye", "new_key"]

        let result = LocalizationExtractorEngine.analyzeKeyChanges(
            extractedKeys: extractedKeys,
            existingTranslations: existingTranslations
        )

        #expect(result.new.sorted() == ["new_key", "welcome"])
        #expect(result.missing.sorted() == ["unused"])
        #expect(result.changed.sorted() == ["bye", "hello"])
    }

    @Test func testLoadStringsdictKeys() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)

        let fileURL = tempDir.appendingPathComponent("Localizable.stringsdict")
        let stringsdictContent = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>photo_count</key>
        <dict>
            <key>NSStringLocalizedFormatKey</key>
            <string>%#@photos@</string>
            <key>photos</key>
            <dict>
                <key>NSStringFormatSpecTypeKey</key>
                <string>NSStringPluralRuleType</string>
                <key>NSStringFormatValueTypeKey</key>
                <string>d</string>
                <key>one</key>
                <string>%d photo</string>
                <key>other</key>
                <string>%d photos</string>
            </dict>
        </dict>
    </dict>
    </plist>
    """

        try stringsdictContent.write(to: fileURL, atomically: true, encoding: .utf8)

        let keys = LocalizationExtractorEngine.loadStringsdictKeys(at: tempDir.path)
        #expect(keys.contains("photo_count"))
        #expect(keys.count == 1)
    }

    @Test func testDetectLocalizationLanguages() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)

        let langs = ["en.lproj", "fr.lproj", "ar.lproj", "Base.lproj", "nonlocalization"]
        for lang in langs {
            let subDir = tempDir.appendingPathComponent(lang)
            try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true, attributes: nil)
        }

        let detected = LocalizationExtractorEngine.detectLocalizationLanguages(at: tempDir.path)
        #expect(Set(detected) == Set(["en.lproj", "fr.lproj", "ar.lproj", "Base.lproj"]))
    }
}
