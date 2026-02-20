//
//  CrimsonArticle.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI
import SDWebImageSwiftUI

// MARK: - Author

struct CrimsonAuthor: Identifiable, Sendable {
    let id: String
    let name: String
}

// MARK: - Article Content Types

enum CrimsonArticleContent: Identifiable, Sendable {
    case paragraph(CrimsonParagraph)
    case image(CrimsonImage)
    case pullQuote(CrimsonPullQuote)

    var id: String {
        switch self {
        case .paragraph(let p): return p.id
        case .image(let i): return i.id
        case .pullQuote(let q): return q.id
        }
    }

    func toView(props: AppProperties) -> AnyView {
        switch self {
        case .paragraph(let p): return p.toView(props: props)
        case .image(let i): return i.toView(props: props)
        case .pullQuote(let q): return q.toView(props: props)
        }
    }
}

struct CrimsonParagraph: Identifiable, Sendable {
    let id = UUID().uuidString
    let text: String

    func toView(props: AppProperties) -> AnyView {
        let attributedString = try? AttributedString(markdown: text)
        let safeString = attributedString ?? AttributedString(text)
        return Text(safeString)
            .font(.crimsonBody)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .eraseToAnyView()
    }
}

struct CrimsonImage: Identifiable, Sendable {
    let id = UUID().uuidString
    let url: URL?
    let credit: String?
    let caption: String?

    func toView(props: AppProperties) -> AnyView {
        Group {
            if let url {
                VStack(spacing: 6) {
                    ZStack(alignment: .bottomTrailing) {
                        WebImage(url: url)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .overlay(
                                Group {
                                    if let credit {
                                        Text(credit)
                                            .font(.crimsonCaption)
                                            .foregroundStyle(.white)
                                            .frame(height: 26)
                                            .padding(.horizontal, 8)
                                            .background(Color.black.opacity(0.25))
                                            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft]))
                                    }
                                }
                                , alignment: .bottomTrailing
                            )
                            .cornerRadius(10)
                            .frame(maxWidth: min(props.width - 46, 500), maxHeight: 300)
                    }

                    if let caption {
                        Text(caption)
                            .font(.crimsonCaption)
                            .foregroundStyle(Color.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .eraseToAnyView()
    }
}

struct CrimsonPullQuote: Identifiable, Sendable {
    let id = UUID().uuidString
    let text: String

    func toView(props: AppProperties) -> AnyView {
        Text(sanitizedText)
            .font(.crimsonQuote)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.crimson)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .eraseToAnyView()
    }

    private var sanitizedText: String {
        var s = text
        // Normalize quotes
        if s.hasPrefix("\"") || s.hasPrefix("\u{201C}") || s.hasPrefix("\u{201D}") {
            s.removeFirst()
        }
        if s.hasSuffix("\"") || s.hasSuffix("\u{201C}") || s.hasSuffix("\u{201D}") {
            s.removeLast()
        }
        s.insert("\u{201C}", at: s.startIndex)
        s.append("\u{201D}")
        return s
    }
}

// MARK: - Article

struct CrimsonArticle: Identifiable, Sendable {
    let slug: String
    let title: String
    let url: URL
    var authors: [CrimsonAuthor]
    var content: [CrimsonArticleContent]
    var previewImageURL: URL?
    var datePublished: Date?
    var isFullyLoaded: Bool

    var id: String { slug }

    var dateString: String? {
        guard let date = datePublished else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    /// Create from a CSV entry (lightweight, not fully loaded)
    init(from entry: CrimsonArticleEntry) {
        self.slug = entry.slug
        self.title = entry.title
        self.url = entry.url
        self.authors = []
        self.content = []
        self.previewImageURL = nil
        self.datePublished = entry.datePublished
        self.isFullyLoaded = false
    }

    /// Load full article data from scraping
    mutating func loadFullArticle(_ scraped: CrimsonArticle) {
        self.authors = scraped.authors
        self.content = scraped.content
        self.previewImageURL = scraped.previewImageURL
        if scraped.datePublished != nil {
            self.datePublished = scraped.datePublished
        }
        self.isFullyLoaded = true
    }
}
