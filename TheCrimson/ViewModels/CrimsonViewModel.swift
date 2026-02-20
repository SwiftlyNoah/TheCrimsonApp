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
    var sections: [CrimsonSection] = []
    var articles: [CrimsonArticle] = []

    // MARK: - Navigation
    var viewState: CrimsonViewState = .home
    var previousViewState: CrimsonViewState = .home
    var articleIndex: Int = 0

    // MARK: - UI State
    var darkTheme = false
    var showFullAnimation = true
    var isFirstOpen = true
    var isLoading = false
    var loadError: String?

    // MARK: - Search
    var searchQuery = ""
    var searchResults: [CrimsonArticle] = []

    // MARK: - Scraping Cache
    private var scrapedArticles: [String: CrimsonArticle] = [:]
    private var scrapingTasks: Set<String> = []

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
        loadHomepage()
    }

    // MARK: - Data Loading

    func loadHomepage() {
        isLoading = true
        loadError = nil
        Task {
            await fetchHomepage()
        }
    }

    func fetchHomepage() async {
        do {
            let fetchedSections = try await HomepageScraper.fetchSections()
            self.sections = fetchedSections
            self.articles = fetchedSections.flatMap(\.articles)
            self.isLoading = false
        } catch {
            print("Failed to load homepage: \(error)")
            self.loadError = "Failed to load articles. Pull down to retry."
            self.isLoading = false
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
    }

    func showSettings() {
        withAnimation(.easeInOut(duration: 0.3)) {
            previousViewState = viewState
            viewState = .settings
        }
    }

    // MARK: - Article Scraping

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

    func performSearch() {
        let query = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        let filtered = articles.filter { $0.title.lowercased().contains(query) }
        searchResults = Array(filtered.prefix(50))
    }

    func searchResultSelected(_ article: CrimsonArticle) {
        if let idx = articles.firstIndex(where: { $0.slug == article.slug }) {
            articleSelected(idx)
        } else {
            articles.append(article)
            articleSelected(articles.count - 1)
        }
    }
}
