//
//  CrimsonViewModel.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI

enum CrimsonViewState {
    case home
    case article
    case search
    case settings
}

@Observable
class CrimsonViewModel {
    // MARK: - Data
    var entries: [CrimsonArticleEntry] = []
    var articles: [CrimsonArticle] = []
    var totalEntriesLoaded = 0

    // MARK: - Navigation
    var viewState: CrimsonViewState = .home
    var previousViewState: CrimsonViewState = .home
    var articleIndex: Int = 0

    // MARK: - UI State
    var darkTheme = false
    var showFullAnimation = true
    var isFirstOpen = true
    var isLoading = false
    var isPaginating = false

    // MARK: - Search
    var searchQuery = ""
    var searchResults: [CrimsonArticle] = []
    private var allSearchEntries: [CrimsonArticleEntry] = []

    // MARK: - Scraping Cache
    private var scrapedArticles: [String: CrimsonArticle] = [:]
    private var scrapingTasks: Set<String> = []

    // MARK: - Constants
    private let pageSize = 500
    private let searchLimit = 10000

    // MARK: - Computed Properties

    var showBackButton: Bool {
        viewState == .article || viewState == .search || viewState == .settings
    }

    var showPaginator: Bool {
        viewState == .article
    }

    var articleCountString: String {
        "\(articles.count)"
    }

    // MARK: - Initialization

    init() {
        loadInitialArticles()
    }

    // MARK: - Data Loading

    func loadInitialArticles() {
        isLoading = true
        let limit = pageSize
        Task.detached {
            let parsed = CSVParser.parseEntries(limit: limit, offset: 0)
            await MainActor.run {
                self.entries = parsed
                self.articles = parsed.map { CrimsonArticle(from: $0) }
                self.totalEntriesLoaded = parsed.count
                self.isLoading = false
            }
        }
    }

    func loadMoreArticles() {
        guard !isPaginating else { return }
        isPaginating = true
        let currentOffset = totalEntriesLoaded
        let limit = pageSize

        Task.detached {
            let parsed = CSVParser.parseEntries(limit: limit, offset: currentOffset)
            await MainActor.run {
                self.entries.append(contentsOf: parsed)
                self.articles.append(contentsOf: parsed.map { CrimsonArticle(from: $0) })
                self.totalEntriesLoaded += parsed.count
                self.isPaginating = false
            }
        }
    }

    // MARK: - Navigation

    func articleSelected(_ index: Int) {
        articleIndex = index
        withAnimation(.easeInOut(duration: 0.3)) {
            previousViewState = viewState
            viewState = .article
        }
        scrapeArticle(at: index)
        prefetchNearby(index)
    }

    func back() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if viewState == .search || viewState == .settings {
                viewState = previousViewState == .article ? .article : .home
            } else {
                viewState = .home
            }
        }
    }

    func showSearch() {
        withAnimation(.easeInOut(duration: 0.3)) {
            previousViewState = viewState
            viewState = .search
        }
        if allSearchEntries.isEmpty {
            loadSearchEntries()
        }
    }

    func showSettings() {
        withAnimation(.easeInOut(duration: 0.3)) {
            previousViewState = viewState
            viewState = .settings
        }
    }

    // MARK: - Article Scraping

    func articleAppeared(_ index: Int) {
        scrapeArticle(at: index)
        prefetchNearby(index)

        // Pagination: load more when near the end
        if index > articles.count - 20 {
            loadMoreArticles()
        }
    }

    func scrapeArticle(at index: Int) {
        guard index >= 0, index < articles.count else { return }
        let article = articles[index]
        guard !article.isFullyLoaded else { return }

        // Check cache
        if let cached = scrapedArticles[article.slug] {
            articles[index].loadFullArticle(cached)
            return
        }

        guard !scrapingTasks.contains(article.slug) else { return }
        scrapingTasks.insert(article.slug)

        let url = article.url
        let slug = article.slug

        Task {
            do {
                if let scraped = try await ArticleScraper.scrape(url: url) {
                    self.scrapedArticles[slug] = scraped
                    if let idx = self.articles.firstIndex(where: { $0.slug == slug }) {
                        self.articles[idx].loadFullArticle(scraped)
                    }
                    self.scrapingTasks.remove(slug)
                } else {
                    self.scrapingTasks.remove(slug)
                }
            } catch {
                self.scrapingTasks.remove(slug)
                print("Scraping error for \(slug): \(error)")
            }
        }
    }

    private func prefetchNearby(_ index: Int) {
        for offset in 1...2 {
            let nextIndex = index + offset
            if nextIndex < articles.count {
                scrapeArticle(at: nextIndex)
            }
        }
    }

    // MARK: - Search

    private func loadSearchEntries() {
        let limit = searchLimit
        Task.detached {
            let all = CSVParser.parseAllEntries(limit: limit)
            await MainActor.run {
                self.allSearchEntries = all
            }
        }
    }

    func performSearch() {
        let query = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        let source = allSearchEntries.isEmpty ? entries : allSearchEntries
        let filtered = source.filter { $0.title.lowercased().contains(query) }
        searchResults = filtered.prefix(50).map { CrimsonArticle(from: $0) }
    }

    func searchResultSelected(_ article: CrimsonArticle) {
        // Find the article in the main list, or add it
        if let idx = articles.firstIndex(where: { $0.slug == article.slug }) {
            articleSelected(idx)
        } else {
            articles.append(article)
            articleSelected(articles.count - 1)
        }
    }

    // MARK: - Home Feed

    func homeArticleAppeared(_ index: Int) {
        // Pagination trigger
        if index > articles.count - 20 {
            loadMoreArticles()
        }
    }
}
