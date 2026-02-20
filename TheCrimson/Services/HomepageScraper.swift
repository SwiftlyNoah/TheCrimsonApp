//
//  HomepageScraper.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/20/26.
//

import Foundation

nonisolated struct HomepageScraper {
    /// Fetches the Crimson homepage and returns articles grouped by section
    static func fetchSections() async throws -> [CrimsonSection] {
        let url = URL(string: "https://www.thecrimson.com")!
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            print("[HomepageScraper] Could not decode HTML as UTF-8")
            return []
        }

        guard let apolloJSON = extractApolloState(from: html) else {
            print("[HomepageScraper] Could not extract Apollo state from HTML")
            return []
        }

        print("[HomepageScraper] Apollo state has \(apolloJSON.count) keys")
        return parseSections(from: apolloJSON)
    }

    // MARK: - Apollo State Extraction

    private static func extractApolloState(from html: String) -> [String: Any]? {
        guard let startRange = html.range(of: "window.__APOLLO_STATE__=") else { return nil }

        let jsonStart = startRange.upperBound
        let remaining = html[jsonStart...]

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

    // MARK: - Section Parsing

    /// Maps Apollo keys to display section titles, in the order they appear on the website.
    /// TOP NEWS: the featured + primary articles at the top of the page.
    /// MORE NEWS: the secondary block below top news.
    private static let sectionMapping: [(key: String, title: String, showImages: Bool)] = [
        ("primaryFirstFeatured", "TOP NEWS", true),
        ("primarySecondFeatured", "TOP NEWS", true),
        ("primaryFirst", "TOP NEWS", false),
        ("primarySecond", "TOP NEWS", false),
        ("primaryFirstBottom", "MORE NEWS", true),
        ("primarySecondColumns", "MORE NEWS", true),
        ("opinion", "OPINION", true),
        ("fmFeatured", "FIFTEEN MINUTES", true),
        ("artsSection", "ARTS", true),
        ("sportsFeaturedSection", "SPORTS", true),
        ("sportsSecondSection", "SPORTS", true),
    ]

    private static func parseSections(from apolloJSON: [String: Any]) -> [CrimsonSection] {
        var sectionArticles: [(title: String, articles: [CrimsonArticle])] = []
        var sectionIndex: [String: Int] = [:]

        for (key, title, showImages) in sectionMapping {
            let fullKey = "$ROOT_QUERY.redHeaderIndex.\(key)"

            var articles = extractArticles(forKey: fullKey, sectionName: key, from: apolloJSON)

            if !showImages {
                for i in articles.indices {
                    articles[i].previewImageURL = nil
                }
            }

            if articles.isEmpty {
                print("[HomepageScraper] Section '\(key)' produced 0 articles")
                continue
            } else {
                print("[HomepageScraper] Section '\(key)' -> \(articles.count) articles")
            }

            if let idx = sectionIndex[title] {
                sectionArticles[idx].articles.append(contentsOf: articles)
            } else {
                sectionIndex[title] = sectionArticles.count
                sectionArticles.append((title: title, articles: articles))
            }
        }

        return sectionArticles.map { CrimsonSection(title: $0.title, articles: $0.articles) }
    }

    // MARK: - Article Extraction

    private static func extractArticles(forKey sectionKey: String, sectionName: String, from apolloJSON: [String: Any]) -> [CrimsonArticle] {
        guard let sectionData = apolloJSON[sectionKey] as? [String: Any] else {
            print("[HomepageScraper] Key '\(sectionKey)' not found in Apollo state")
            return []
        }

        // Try to get "content" array of refs
        if let contentRefs = sectionData["content"] as? [[String: Any]] {
            print("[HomepageScraper] '\(sectionName)' has \(contentRefs.count) content refs")
            return contentRefs.enumerated().compactMap { (idx, ref) -> CrimsonArticle? in
                guard let refID = ref["id"] as? String else {
                    print("[HomepageScraper] '\(sectionName)' content[\(idx)]: missing 'id' field. Keys: \(ref.keys.sorted())")
                    return nil
                }
                guard let article = parseArticleFromRef(refID, apolloJSON: apolloJSON) else {
                    print("[HomepageScraper] '\(sectionName)' content[\(idx)]: failed to decode article from ref '\(refID)'")
                    return nil
                }
                return article
            }
        }

        // The section itself might be a single article reference
        if let refID = sectionData["__ref"] as? String {
            if let article = parseArticleFromRef(refID, apolloJSON: apolloJSON) {
                return [article]
            }
            print("[HomepageScraper] '\(sectionName)': __ref '\(refID)' failed to decode")
        }

        // The section data itself might be an article
        if sectionData["title"] != nil {
            if let article = parseArticleDict(sectionData, apolloJSON: apolloJSON) {
                return [article]
            }
            print("[HomepageScraper] '\(sectionName)': inline article failed to decode. Keys: \(sectionData.keys.sorted())")
        }

        print("[HomepageScraper] '\(sectionName)': no content array, no __ref, no inline article. Keys: \(sectionData.keys.sorted())")
        return []
    }

    private static func parseArticleFromRef(_ refID: String, apolloJSON: [String: Any]) -> CrimsonArticle? {
        guard let articleData = apolloJSON[refID] as? [String: Any] else {
            print("[HomepageScraper] Ref '\(refID)' not found in Apollo state")
            return nil
        }
        return parseArticleDict(articleData, apolloJSON: apolloJSON)
    }

    // MARK: - Article Parsing

    private static func parseArticleDict(_ dict: [String: Any], apolloJSON: [String: Any]) -> CrimsonArticle? {
        guard let title = dict["title"] as? String, !title.isEmpty else {
            print("[HomepageScraper] Article decode failed: missing or empty 'title'. Keys: \(dict.keys.sorted())")
            return nil
        }

        let slug = dict["slug"] as? String ?? UUID().uuidString
        let urlPath = dict["url"] as? String ?? "/article/\(slug)/"
        let fullURL = URL(string: "https://www.thecrimson.com\(urlPath)")
            ?? URL(string: "https://www.thecrimson.com")!

        // Authors
        var authors: [CrimsonAuthor] = []
        if let contributors = dict["contributors"] as? [[String: Any]] {
            authors = contributors.compactMap { ref -> CrimsonAuthor? in
                if let refID = ref["id"] as? String,
                   let contributorData = apolloJSON[refID] as? [String: Any],
                   let name = contributorData["name"] as? String {
                    return CrimsonAuthor(id: refID, name: name)
                }
                if let name = ref["name"] as? String {
                    return CrimsonAuthor(id: UUID().uuidString, name: name)
                }
                return nil
            }
        }

        // Preview image — try parameterized imgUrl fields first (most reliable for homepage)
        let previewImageURL = extractImageURL(from: dict, apolloJSON: apolloJSON)

        // Date
        var datePublished: Date?
        if let dateString = dict["createdOn"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            datePublished = formatter.date(from: dateString)
            if datePublished == nil {
                formatter.formatOptions = [.withInternetDateTime]
                datePublished = formatter.date(from: dateString)
            }
        }

        guard let entry = CrimsonArticleEntry(title: title, urlString: fullURL.absoluteString) else {
            print("[HomepageScraper] Article '\(title)': CrimsonArticleEntry init failed for URL '\(fullURL.absoluteString)'")
            return nil
        }

        var article = CrimsonArticle(from: entry)
        article.authors = authors
        article.previewImageURL = previewImageURL
        if datePublished != nil {
            article.datePublished = datePublished
        }
        return article
    }

    // MARK: - Image Extraction

    private static func extractImageURL(from dict: [String: Any], apolloJSON: [String: Any]) -> URL? {
        // 1. Try parameterized imgUrl keys (e.g. `imgUrl({"height":356,"width":550})`)
        //    These are the thumbnail URLs directly on the article object in the Apollo cache.
        for key in dict.keys {
            if key.hasPrefix("imgUrl(") || key.hasPrefix("imgUrl({") {
                if let urlString = dict[key] as? String, let url = URL(string: urlString) {
                    return url
                }
            }
        }

        // 2. Try mainContent reference -> ImageGQL object
        if let mainContent = dict["mainContent"] as? [String: Any] {
            // Follow reference
            if let mainContentID = mainContent["id"] as? String,
               let mainContentData = apolloJSON[mainContentID] as? [String: Any] {
                // Check parameterized imgUrl on the image object too
                for key in mainContentData.keys {
                    if key.hasPrefix("imgUrl(") || key.hasPrefix("imgUrl({") {
                        if let urlString = mainContentData[key] as? String, let url = URL(string: urlString) {
                            return url
                        }
                    }
                }
                // Fallback to url/imageUrl fields
                if let imgURL = mainContentData["url"] as? String ?? mainContentData["imageUrl"] as? String {
                    return URL(string: imgURL)
                }
            }
            // Inline image data
            if let imgURL = mainContent["url"] as? String ?? mainContent["imageUrl"] as? String {
                return URL(string: imgURL)
            }
        }

        return nil
    }
}
