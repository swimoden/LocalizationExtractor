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
