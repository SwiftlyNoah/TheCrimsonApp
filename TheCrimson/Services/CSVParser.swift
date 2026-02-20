//
//  CSVParser.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import Foundation

nonisolated struct CSVParser {
    /// Parse entries from the bundled CSV file, reading in chunks.
    /// - Parameters:
    ///   - limit: Maximum number of entries to return
    ///   - offset: Number of entries to skip from the start
    /// - Returns: Array of CrimsonArticleEntry parsed from the CSV
    static func parseEntries(limit: Int = 500, offset: Int = 0) -> [CrimsonArticleEntry] {
        guard let url = Bundle.main.url(forResource: "crimson_articles", withExtension: "csv") else {
            print("CSVParser: Could not find crimson_articles.csv in bundle")
            return []
        }

        guard let handle = try? FileHandle(forReadingFrom: url) else {
            print("CSVParser: Could not open file handle")
            return []
        }
        defer { handle.closeFile() }

        let chunkSize = 8192
        var entries: [CrimsonArticleEntry] = []
        var buffer = ""
        var skippedHeader = false
        var skipped = 0

        while true {
            let data = handle.readData(ofLength: chunkSize)
            if data.isEmpty { break }

            guard let chunk = String(data: data, encoding: .utf8) else { continue }
            buffer += chunk

            var lines = buffer.components(separatedBy: "\n")
            // Keep the last partial line in buffer
            buffer = lines.removeLast()

            for line in lines {
                if !skippedHeader {
                    skippedHeader = true
                    continue
                }

                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { continue }

                if let entry = parseLine(trimmed) {
                    if skipped < offset {
                        skipped += 1
                        continue
                    }
                    entries.append(entry)
                    if entries.count >= limit {
                        return entries
                    }
                }
            }
        }

        // Process remaining buffer
        if !buffer.isEmpty {
            let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, let entry = parseLine(trimmed) {
                if skipped >= offset {
                    entries.append(entry)
                }
            }
        }

        return entries
    }

    /// Parse all entries for search (reads more from the CSV)
    static func parseAllEntries(limit: Int = 10000) -> [CrimsonArticleEntry] {
        return parseEntries(limit: limit, offset: 0)
    }

    /// Parse a single CSV line handling quoted fields
    private static func parseLine(_ line: String) -> CrimsonArticleEntry? {
        let (title, url) = parseCSVFields(line)
        guard let title, let url else { return nil }
        return CrimsonArticleEntry(title: title, urlString: url)
    }

    /// Parse a CSV line into title and URL, handling quoted fields
    private static func parseCSVFields(_ line: String) -> (String?, String?) {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var prevWasQuote = false

        for char in line {
            if char == "\"" {
                if inQuotes && prevWasQuote {
                    // Escaped quote
                    current.append("\"")
                    prevWasQuote = false
                } else if inQuotes {
                    prevWasQuote = true
                } else {
                    inQuotes = true
                    prevWasQuote = false
                }
            } else if char == "," && !inQuotes {
                if prevWasQuote { inQuotes = false; prevWasQuote = false }
                fields.append(current)
                current = ""
            } else {
                if prevWasQuote { inQuotes = false; prevWasQuote = false }
                current.append(char)
            }
        }
        fields.append(current)

        guard fields.count >= 2 else { return (nil, nil) }
        return (fields[0], fields[1])
    }
}
