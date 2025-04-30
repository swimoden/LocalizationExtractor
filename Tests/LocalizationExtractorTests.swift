import Testing
import Foundation
@testable import LocalizationExtractor

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
            [#""([^"]+)"\s*\.localized\s*\(\s*comment:\s*"([^"]+)"\)"#]
        ),
        (
            #""cancel".localized("Cancel comment")"#,
            [#""([^"]+)"\s*\.localized\s*\(\s*"([^"]+)"\)"#]
        ),
        (
            #""ok".localized"#,
            [#""([^"]+)"\s*\.localized"#]
        ),
        (
            #"NSLocalizedString("save", comment: "Save comment")"#,
            [#"\w+LocalizedString\(\s*"([^"]+)"\s*,\s*comment:\s*"([^"]+)"\)"#]
        )
    ]

    for (example, expected) in examplesAndExpectedPatterns {
        let generated = LocalizationRegexGenerator.generatePatterns(from: example)
        #expect(generated == expected, "Failed for example: \(example)")
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
