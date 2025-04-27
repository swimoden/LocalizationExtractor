# LocalizationExtractorCLI

LocalizationExtractorCLI is a Swift command-line tool to scan Swift project files, extract localization keys, and update `.strings` localization files automatically. It helps keep localization keys organized, avoids missing translations, and integrates easily into any project workflow.

## Features

- Recursively scans `.swift` files
- Extracts localization keys using customizable regex patterns
- Updates multiple `.lproj` localization directories
- Preserves existing translations
- Fully interactive CLI prompts
- Lightweight and fast

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

## Usage

Run the CLI:

```bash
.build/release/LocalizationExtractorCLI
```

You will be interactively prompted for:

- Project path
- Localization directories (comma-separated)
- Localization file name (`Localizable.strings` by default)
- Regex patterns for extraction
- Localization base path

Example session:

```
Enter project path (default: /Users/you/Projects/MyApp):
Enter localization directories (default: en.lproj,fr.lproj,ar.lproj):
Enter localization file name (default: Localizable.strings):
Enter localization regex patterns (or press Enter to use defaults):
Enter localization base path (default: /Users/you/Projects/MyApp/Resources/Localization):
```

## Default Regex Patterns

If you press Enter without customizing, these patterns are used:

```
"([^\"]+)"\s*\n*\s*\.localized
NSLocalizedString\(\s*"([^\"]+)"
```

These cover Swift `.localized` extensions and `NSLocalizedString` API calls.

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
