import Foundation
import LocalizationExtractor

// MARK: - Config (interactive)
func prompt(_ message: String, defaultValue: String) -> String {
    print("\(message) (default: \(defaultValue)):", terminator: " ")
    if let input = readLine(), !input.isEmpty {
        return input
    }
    return defaultValue
}

let projectPath = prompt("Enter project path", defaultValue: FileManager.default.currentDirectoryPath)
print("🔵 Project path: \(projectPath)")

let localizationDirectoriesInput = prompt("Enter localization directories (comma-separated)", defaultValue: "en.lproj,fr.lproj,ar.lproj")
let localizationDirectories = localizationDirectoriesInput.components(separatedBy: ",")

let localizationFileName = prompt("Enter localization file name", defaultValue: "Localizable.strings")

let defaultPatterns = [
    #""([^"]+)"\s*\n*\s*\.localized"#,
    #"NSLocalizedString\(\s*"([^"]+)"#,
]

let localizationPatternsInput = prompt(
    "Enter localization regex patterns (comma-separated or press Enter to use default patterns)",
    defaultValue: defaultPatterns.joined(separator: ",")
)
let localizationPattern = localizationPatternsInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

let localizationBasePath = prompt("Enter localization base path", defaultValue: "\(projectPath)/Resources/Localization")

func main() {
    LocalizationExtractorEngine.runExtraction(
        projectPath: projectPath,
        localizationBaseURL: URL(fileURLWithPath: localizationBasePath),
        localizationFolders: localizationDirectories,
        localizationFileName: localizationFileName,
        patterns: localizationPattern,
        log: { print($0) }
    )
}

main()
