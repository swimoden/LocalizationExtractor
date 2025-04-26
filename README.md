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

This project is licensed under the [MIT License](LICENSE).

## Contributions

Pull requests are welcome! Feel free to fork, open issues, or suggest improvements.

