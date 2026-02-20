//
//  ArticleScraper.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import Foundation
import SwiftSoup

nonisolated struct ArticleScraper {
    /// Scrape a Crimson article from its URL by extracting the Apollo GraphQL cache
    static func scrape(url: URL) async throws -> CrimsonArticle? {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else { return nil }

        // Extract __APOLLO_STATE__ JSON from the HTML
        guard let apolloJSON = extractApolloState(from: html) else {
            print("ArticleScraper: Could not extract Apollo state from \(url)")
            return nil
        }

        return parseArticle(from: apolloJSON, url: url)
    }

    // MARK: - Apollo State Extraction

    private static func extractApolloState(from html: String) -> [String: Any]? {
        // Find the window.__APOLLO_STATE__ assignment
        guard let startRange = html.range(of: "window.__APOLLO_STATE__=") else { return nil }

        let jsonStart = startRange.upperBound
        let remaining = html[jsonStart...]

        // Find the matching closing brace by counting braces
        var braceCount = 0
        var endIndex = remaining.startIndex
        var foundStart = false

        for idx in remaining.indices {
            let char = remaining[idx]
            if char == "{" {
                braceCount += 1
                foundStart = true
            } else if char == "}" {
                braceCount -= 1
                if foundStart && braceCount == 0 {
                    endIndex = remaining.index(after: idx)
                    break
                }
            }
        }

        let jsonString = String(remaining[remaining.startIndex..<endIndex])

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }

        return json
    }

    // MARK: - Article Parsing

    private static func parseArticle(from apolloJSON: [String: Any], url: URL) -> CrimsonArticle? {
        // Find the article content key (starts with "$ROOT_QUERY.content(")
        guard let (_, articleData) = apolloJSON.first(where: { key, _ in
            key.hasPrefix("$ROOT_QUERY.content(") && !key.contains(".contributors.") &&
            !key.contains(".shortcodes.") && !key.contains(".tags.") &&
            !key.contains(".section") && !key.contains(".mainContent")
        }),
        let articleDict = articleData as? [String: Any] else {
            return nil
        }

        // Title
        let title = articleDict["title"] as? String ?? ""
        let slug = articleDict["slug"] as? String ?? url.lastPathComponent

        // Authors
        let authors = parseContributors(articleDict: articleDict, apolloJSON: apolloJSON)

        // Preview image
        let previewImageURL = parsePreviewImage(articleDict: articleDict, apolloJSON: apolloJSON)

        // Date
        let datePublished = parseDate(from: articleDict)

        // Content (paragraphs + shortcodes)
        let content = parseContent(articleDict: articleDict, apolloJSON: apolloJSON)

        guard let entry = CrimsonArticleEntry(title: title, urlString: url.absoluteString) else {
            return nil
        }
        var article = CrimsonArticle(from: entry)
        article.authors = authors
        article.content = content
        article.previewImageURL = previewImageURL
        article.datePublished = datePublished
        article.isFullyLoaded = true
        return article
    }

    // MARK: - Contributors

    private static func parseContributors(articleDict: [String: Any], apolloJSON: [String: Any]) -> [CrimsonAuthor] {
        guard let contributors = articleDict["contributors"] as? [[String: Any]] else { return [] }

        return contributors.compactMap { ref -> CrimsonAuthor? in
            guard let refID = ref["id"] as? String,
                  let contributorData = apolloJSON[refID] as? [String: Any],
                  let name = contributorData["name"] as? String else { return nil }
            let authorURL = contributorData["url"] as? String ?? refID
            return CrimsonAuthor(id: authorURL, name: name)
        }
    }

    // MARK: - Preview Image

    private static func parsePreviewImage(articleDict: [String: Any], apolloJSON: [String: Any]) -> URL? {
        // Try mainContent first
        if let mainContent = articleDict["mainContent"] as? [String: Any],
           let mainContentID = mainContent["id"] as? String,
           let mainContentData = apolloJSON[mainContentID] as? [String: Any],
           let imageURL = mainContentData["url"] as? String ?? mainContentData["imageUrl"] as? String {
            return URL(string: imageURL)
        }

        // Try first shortcode image
        if let shortcodes = articleDict["shortcodes"] as? [[String: Any]],
           let first = shortcodes.first,
           let refID = first["id"] as? String,
           let shortcodeData = apolloJSON[refID] as? [String: Any],
           let imageURL = shortcodeData["imageUrl"] as? String {
            return URL(string: imageURL)
        }

        return nil
    }

    // MARK: - Date

    private static func parseDate(from articleDict: [String: Any]) -> Date? {
        guard let dateString = articleDict["createdOn"] as? String else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) { return date }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    // MARK: - Content Building

    private static func parseContent(articleDict: [String: Any], apolloJSON: [String: Any]) -> [CrimsonArticleContent] {
        // Build shortcode lookup map
        var shortcodeMap: [String: (imageURL: String, caption: String?, credit: String?)] = [:]

        if let shortcodes = articleDict["shortcodes"] as? [[String: Any]] {
            for ref in shortcodes {
                guard let refID = ref["id"] as? String,
                      let shortcodeData = apolloJSON[refID] as? [String: Any],
                      let key = shortcodeData["key"] as? String,
                      let imageURL = shortcodeData["imageUrl"] as? String else { continue }

                let caption = shortcodeData["caption"] as? String
                let credit = parseShortcodeCredit(shortcodeData: shortcodeData, apolloJSON: apolloJSON)
                shortcodeMap[key] = (imageURL, caption, credit)
            }
        }

        // Parse paragraphs
        var content: [CrimsonArticleContent] = []
        let paragraphsJSON: [String]

        if let paragraphsWrapper = articleDict["paragraphs"] as? [String: Any],
           let json = paragraphsWrapper["json"] as? [String] {
            paragraphsJSON = json
        } else if let paragraphs = articleDict["paragraphs"] as? [String] {
            paragraphsJSON = paragraphs
        } else {
            return content
        }

        for htmlParagraph in paragraphsJSON {
            let trimmed = htmlParagraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            // Check for shortcode placeholders
            let shortcodePattern = "\\{shortcode-[a-f0-9]+\\}"
            if let regex = try? NSRegularExpression(pattern: shortcodePattern),
               let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
                let shortcodeKey = String(trimmed[Range(match.range, in: trimmed)!])

                if let shortcode = shortcodeMap[shortcodeKey] {
                    content.append(.image(CrimsonImage(
                        url: URL(string: shortcode.imageURL),
                        credit: shortcode.credit,
                        caption: shortcode.caption
                    )))
                }

                // Check if there's text around the shortcode
                let textWithoutShortcode = trimmed.replacingOccurrences(of: shortcodeKey, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanedText = stripHTML(textWithoutShortcode)
                if !cleanedText.isEmpty {
                    content.append(.paragraph(CrimsonParagraph(text: cleanedText)))
                }
            } else {
                // Regular paragraph - check if it looks like a pull quote
                let cleanText = stripHTML(trimmed)
                if isPullQuote(trimmed) {
                    content.append(.pullQuote(CrimsonPullQuote(text: cleanText)))
                } else if !cleanText.isEmpty {
                    content.append(.paragraph(CrimsonParagraph(text: htmlToMarkdown(trimmed))))
                }
            }
        }

        return content
    }

    // MARK: - Shortcode Credit

    private static func parseShortcodeCredit(shortcodeData: [String: Any], apolloJSON: [String: Any]) -> String? {
        guard let contributors = shortcodeData["contributors"] as? [[String: Any]] else { return nil }

        let names = contributors.compactMap { ref -> String? in
            guard let refID = ref["id"] as? String,
                  let data = apolloJSON[refID] as? [String: Any],
                  let name = data["name"] as? String else { return nil }
            return name
        }

        return names.isEmpty ? nil : names.joined(separator: ", ")
    }

    // MARK: - HTML Processing

    private static func stripHTML(_ html: String) -> String {
        guard let doc = try? SwiftSoup.parse(html) else { return html }
        return (try? doc.text()) ?? html
    }

    private static func htmlToMarkdown(_ html: String) -> String {
        var result = html
        // Convert common HTML tags to markdown
        result = result.replacingOccurrences(of: "<strong>", with: "**")
        result = result.replacingOccurrences(of: "</strong>", with: "**")
        result = result.replacingOccurrences(of: "<b>", with: "**")
        result = result.replacingOccurrences(of: "</b>", with: "**")
        result = result.replacingOccurrences(of: "<em>", with: "*")
        result = result.replacingOccurrences(of: "</em>", with: "*")
        result = result.replacingOccurrences(of: "<i>", with: "*")
        result = result.replacingOccurrences(of: "</i>", with: "*")

        // Handle links: <a href="...">text</a> -> [text](url)
        let linkPattern = "<a[^>]*href=\"([^\"]*)\"[^>]*>(.*?)</a>"
        if let regex = try? NSRegularExpression(pattern: linkPattern, options: .dotMatchesLineSeparators) {
            let nsString = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsString.length))
            for match in matches.reversed() {
                let fullRange = match.range
                let urlRange = match.range(at: 1)
                let textRange = match.range(at: 2)
                let url = nsString.substring(with: urlRange)
                let text = nsString.substring(with: textRange)
                let markdownLink = "[\(text)](\(url))"
                result = (result as NSString).replacingCharacters(in: fullRange, with: markdownLink)
            }
        }

        // Strip remaining HTML tags
        let tagPattern = "<[^>]+>"
        result = result.replacingOccurrences(of: tagPattern, with: "", options: .regularExpression)

        // Clean up HTML entities
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#39;", with: "'")
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&mdash;", with: "\u{2014}")
        result = result.replacingOccurrences(of: "&ndash;", with: "\u{2013}")
        result = result.replacingOccurrences(of: "&rsquo;", with: "\u{2019}")
        result = result.replacingOccurrences(of: "&lsquo;", with: "\u{2018}")
        result = result.replacingOccurrences(of: "&rdquo;", with: "\u{201D}")
        result = result.replacingOccurrences(of: "&ldquo;", with: "\u{201C}")

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isPullQuote(_ html: String) -> Bool {
        // Detect pull quotes: paragraphs that are entirely bold or contain only a short quoted sentence
        let text = stripHTML(html)
        let isShort = text.count < 200
        let isQuoted = (text.hasPrefix("\"") || text.hasPrefix("\u{201C}")) &&
                       (text.hasSuffix("\"") || text.hasSuffix("\u{201D}"))
        let isAllBold = html.contains("<strong>") && !html.contains("</strong><") &&
                        html.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<p><strong>")

        return isShort && (isQuoted || isAllBold)
    }
}
