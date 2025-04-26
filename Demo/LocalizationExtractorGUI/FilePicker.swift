//
//  FilePicker.swift
//  UpdateLocalizations
//
//  Created by mohammed souiden on 4/26/25.
//
import Foundation
import AppKit

struct FilePicker {
    static func pickFolder(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "Choose a Folder"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false

        panel.begin { response in
            if response == .OK {
                completion(panel.url)
            } else {
                completion(nil)
            }
        }
    }
}
