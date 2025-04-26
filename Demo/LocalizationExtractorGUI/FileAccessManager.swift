//
//  FileAccessManager.swift
//  UpdateLocalizations
//
//  Created by mohammed souiden on 4/26/25.
//


import Foundation

final class FileAccessManager {
    private static let bookmarksKey = "SecurityScopedBookmarks"

    static func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            var saved = UserDefaults.standard.dictionary(forKey: bookmarksKey) as? [String: Data] ?? [:]
            saved[url.absoluteString] = bookmarkData
            UserDefaults.standard.setValue(saved, forKey: bookmarksKey)
        } catch {
            print("❌ Failed to save bookmark: \(error.localizedDescription)")
        }
    }

    static func accessAndReturnResolvedURL(_ url: URL) -> URL? {
        guard let data = (UserDefaults.standard.dictionary(forKey: bookmarksKey) as? [String: Data])?[url.absoluteString] else {
            print("⚠️ No bookmark data found for: \(url.absoluteString)")
            return nil
        }

        var stale = false
        do {
            let resolvedURL = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale)
            if resolvedURL.startAccessingSecurityScopedResource() {
                return resolvedURL
            } else {
                print("❌ Failed to start security scoped access.")
                return nil
            }
        } catch {
            print("❌ Failed to resolve bookmark: \(error.localizedDescription)")
            return nil
        }
    }
}
