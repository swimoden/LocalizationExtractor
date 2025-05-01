# LocalizationExtractorCLI

LocalizationExtractorCLI is a Swift command-line tool to scan Swift project files, extract localization keys, and update `.strings` localization files automatically. It helps keep localization keys organized, avoids missing translations, detects changes to developer comments, excludes `.stringsdict` keys, and integrates easily into any project workflow.

## Features

- Recursively scans `.swift` files
- Extracts localization keys using customizable regex patterns
- Updates multiple `.lproj` localization directories
- Preserves existing translations
- Fully interactive CLI prompts
- Lightweight and fast
- Dynamically generates regex patterns from a sample localization call
- Option to include comments in the generated `.strings` file
- Detects and excludes `.stringsdict` keys
- Detects changes to developer comments

## Installation

Clone this repository and build the CLI tool:

```bash
git clone https://github.com/YOUR_USERNAME/LocalizationExtractor-Demo.git
cd LocalizationExtractor-Demo
swift build -c release
```

The compiled executable will be located at:

```bash
.build/release/LocalizationExtractorCLI
```

## Using as a Swift Package

You can also use the core `LocalizationExtractor` engine as a Swift Package in your own projects.

Add the dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/LocalizationExtractor.git", from: "1.0.0")
]
```

And add it as a dependency to your target:

```swift
.target(
    name: "YourAppOrTool",
    dependencies: [
        .product(name: "LocalizationExtractor", package: "LocalizationExtractor")
    ]
)
```

Then simply import and use it in your Swift files:

```swift
import LocalizationExtractor

let keys = LocalizationExtractorEngine.extractLocalizedKeys(from: fileContent, patterns: ["\"([^\"]+)\"\\s*\\.localized"])
```

## Pattern Generation

The CLI supports advanced pattern detection. You can enter one or more examples of how your project performs localization, and it will generate the appropriate regex patterns. Examples:

```
"submit_button".localized(comment: "Submit")
NSLocalizedString("cancel", comment: "Cancel button")
L10n.alert.title
```

The engine supports:
- `.localized(comment:)`, `.localized("comment")`, `.localized`
- `NSLocalizedString(...)` with and without comments
- `MKLocalizedString(...)`, or any variant ending in `LocalizedString(...)`
- SwiftGen-style `L10n.key.path`

If no example is entered, the following fallback default is used:

```
NSLocalizedString\(\s*"([^\"]+)"
```

## Usage

Run the CLI:

```bash
.build/release/LocalizationExtractorCLI
```

You will be prompted for:

- Project path
- Localization directories (comma-separated, or auto-detected)
- Localization file name (`Localizable.strings` by default)
- Example(s) of your localization usage (auto-generates regex patterns)
- Whether to include developer comments in the `.strings` file
- Whether to auto-detect localization folders (from `.lproj` suffixes)
- Localization base path

Example session:

```
Enter project path (default: /Users/you/Projects/MyApp):
Enter localization directories (default: en.lproj,fr.lproj,ar.lproj):
Enter localization file name (default: Localizable.strings):
Enter an example of your localization usage (e.g., NSLocalizedString("key", comment: "comment")) or press Enter to use defaults:
Include comments in .strings file? (yes/no) (default: yes):
Auto-detect localization folders? (yes/no) (default: yes):
Enter localization base path (default: /Users/you/Projects/MyApp/Resources/Localization):
```

## .stringsdict Support

The extractor automatically detects and excludes keys already defined in `.stringsdict` files to avoid duplicating pluralized or formatted keys.

It also supports detection of `.stringsdict` files and analyzes localization coverage cleanly.

## Example

Extract strings using default settings:

```bash
.build/release/LocalizationExtractorCLI
```

It will automatically generate or update localization files such as:

- `en.lproj/Localizable.strings`
- `fr.lproj/Localizable.strings`
- `ar.lproj/Localizable.strings`

## Project Structure

```
LocalizationExtractorCLI/
 ├── Sources/
 │    └── LocalizationExtractorCLI/
 │         └── main.swift
 ├── Package.swift
 └── README.md
```

## License

This project is licensed under the [MIT License](https://github.com/swimoden/LocalizationExtractor/blob/main/MIT%20License).

## Contributions

Pull requests are welcome! Feel free to fork, open issues, or suggest improvements.
