//
//  CrimsonArticleEntry.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import Foundation

struct CrimsonArticleEntry: Identifiable, Sendable {
    let title: String
    let url: URL
    let slug: String
    let datePublished: Date?

    var id: String { slug }

    init?(title: String, urlString: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty,
              let url = URL(string: trimmedURL) else { return nil }

        self.title = trimmedTitle
        self.url = url

        // Extract slug from URL path: /article/YYYY/M/D/slug-here/
        let pathComponents = url.pathComponents
        self.slug = pathComponents.last(where: { !$0.isEmpty && $0 != "/" }) ?? trimmedURL

        // Extract date from URL path: /article/YYYY/M/D/...
        if let articleIdx = pathComponents.firstIndex(of: "article"),
           pathComponents.count > articleIdx + 3,
           let year = Int(pathComponents[articleIdx + 1]),
           let month = Int(pathComponents[articleIdx + 2]),
           let day = Int(pathComponents[articleIdx + 3]) {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            self.datePublished = Calendar.current.date(from: components)
        } else {
            self.datePublished = nil
        }
    }
}
