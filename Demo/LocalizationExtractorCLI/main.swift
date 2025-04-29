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

let localizationExampleInput = prompt(
    "Enter an example of your localization usage (e.g., NSLocalizedString(\"key\", comment: \"...\")) or press Enter to use default",
    defaultValue: #"NSLocalizedString("key", comment: "comment")"#
)

let localizationPattern: [String]
if localizationExampleInput.isEmpty {
    localizationPattern = [
        #"NSLocalizedString\(\s*"([^"]+)"#
    ]
} else {
    localizationPattern = LocalizationRegexGenerator.generatePatterns(from: localizationExampleInput)
}
print("🔵 Patterns: \(localizationPattern.joined(separator: "\n"))")

let localizationBasePath = prompt("Enter localization base path", defaultValue: "\(projectPath)/Resources/Localization")

let includeCommentsInput = prompt("Include comments in .strings file? (yes/no)", defaultValue: "yes")
let includeComments = includeCommentsInput.lowercased().starts(with: "y")

func main() {
    LocalizationExtractorEngine.runExtraction(
        projectPath: projectPath,
        localizationBaseURL: URL(fileURLWithPath: localizationBasePath),
        localizationFolders: localizationDirectories,
        localizationFileName: localizationFileName,
        patterns: localizationPattern,
        includeComments: includeComments,
        log: { print($0) }
    )
}

main()
