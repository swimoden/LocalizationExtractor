import SwiftUI
import LocalizationExtractor

struct ContentView: View {
    @State private var projectPath: String = ""
    @State private var localizationBasePath: String = ""
    @State private var localizationBaseURL: URL? = nil
    private let defaultLanguages: [String] = [
        "Base.lproj",
        "en.lproj",
        "fr.lproj",
        "ar.lproj"
    ]
    @State private var selectedLanguages: Set<String> = []
    @State private var localizationFileName: String = "Localizable.strings"
    @State private var logOutput: String = ""
    private let defaultPatterns: [String] = [
        #""([^\"]+)"\s*\n*\s*\.localized"#,
        #"NSLocalizedString\(\s*\"([^\"]+)"#
    ]
    @State private var selectedPatterns: Set<String> = []
    @State private var customPattern: String = ""
    @State private var customLanguage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Text("Paths")) {
                VStack(alignment: .leading, spacing: 10) {
                    Button("Select Project Folder") {
                        FilePicker.pickFolder { url in
                            if let url = url {
                                DispatchQueue.main.async {
                                    projectPath = url.path
                                }
                            }
                        }
                    }
                    Text("\u{1F4C2} Project Path: \(projectPath)")

                    Divider()

                    Button("Select Localization Base Folder") {
                        FilePicker.pickFolder { url in
                            if let url = url {
                                DispatchQueue.main.async {
                                    localizationBasePath = url.path
                                    localizationBaseURL = url
                                    FileAccessManager.saveBookmark(for: url)
                                }
                            }
                        }
                    }
                    Text("\u{1F4C2} Localization Base Path: \(localizationBasePath)")

                    Divider()

                    GroupBox(label: Text("Localization Languages")) {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(Array(selectedLanguages).sorted(), id: \.self) { lang in
                                HStack {
                                    Text(lang)
                                        .font(.system(size: 12, design: .monospaced))

                                    Spacer()

                                    Button(action: {
                                        selectedLanguages.remove(lang)
                                    }) {
                                        Image(systemName: "xmark.circle")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            Divider().padding(.vertical, 5)
                            HStack {
                                TextField("Add Custom Language (optional)", text: $customLanguage)
                                    .textFieldStyle(.roundedBorder)
                                Button(action: {
                                    let trimmed = customLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmed.isEmpty {
                                        selectedLanguages.insert(trimmed)
                                        customLanguage = ""
                                    }
                                }) {
                                    Image(systemName: "plus")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(5)
                    }

                    TextField("Localization File Name", text: $localizationFileName)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(5)
            }

            GroupBox(label: Text("Localization Patterns")) {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(selectedPatterns).sorted(), id: \.self) { pattern in
                        HStack {
                            Text(pattern)
                                .font(.system(size: 12, design: .monospaced))

                            Spacer()

                            Button(action: {
                                selectedPatterns.remove(pattern)
                            }) {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Divider().padding(.vertical, 5)
                    HStack {
                        TextField("Add Custom Pattern (optional)", text: $customPattern)
                            .textFieldStyle(.roundedBorder)
                        Button(action: {
                            let trimmed = customPattern.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                selectedPatterns.insert(trimmed)
                                customPattern = ""
                            }
                        }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(5)
            }

            Button(action: runExtraction) {
                Text("Run Extraction")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
            .disabled(projectPath.isEmpty || localizationBaseURL == nil || selectedPatterns.isEmpty)

            GroupBox(label: HStack {
                Text("Log Output")
                Spacer()
                Button(action: {
                    logOutput = ""
                }) {
                    Text("Clear Log")
                }
                .buttonStyle(.bordered)
            }) {
                VStack(alignment: .leading) {


                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(logOutput)
                                .font(.system(size: 12, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .id("BOTTOM")
                        }
                        .frame(maxHeight: 250)
                        .onChange(of: logOutput, { _, _ in
                            withAnimation {
                                proxy.scrollTo("BOTTOM", anchor: .bottom)
                            }
                        })
                    }
                }
            }
        }
        .padding()
        .onAppear {
            selectedPatterns = Set(defaultPatterns)
            selectedLanguages = Set(defaultLanguages)
        }
        .frame(width: 600, height: 850)
    }

    func runExtraction() {
        guard !projectPath.isEmpty else {
            logOutput += "\n❗ Please select a project path first."
            return
        }

        guard let baseURL = localizationBaseURL else {
            logOutput += "\n❗ Please select a localization base folder first."
            return
        }

        guard let securedBaseURL = FileAccessManager.accessAndReturnResolvedURL(baseURL) else {
            logOutput += "\n❌ Unable to access folder due to sandbox restrictions."
            return
        }

        var finalPatterns = Array(selectedPatterns)
        if !customPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            finalPatterns.append(customPattern)
        }

        DispatchQueue.main.async {
            logOutput = "" // Clear old logs
            logOutput += "\n🔵 Started extraction at \(Date())"
            logOutput += "\n📂 Project Path: \(projectPath)"
            logOutput += "\n📂 Localization Base Path: \(localizationBasePath)"
            logOutput += "\n📂 Localization Folders: \(selectedLanguages.joined(separator: ", "))"
            logOutput += "\n📂 Localization File Name: \(localizationFileName)"
        }

        DispatchQueue.global(qos: .userInitiated).async {
            LocalizationExtractorEngine.runExtraction(
                projectPath: projectPath,
                localizationBaseURL: securedBaseURL,
                localizationFolders: Array(selectedLanguages),
                localizationFileName: localizationFileName,
                patterns: finalPatterns
            ) { message in
                DispatchQueue.main.async {
                    logOutput += "\n\(message)"
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
