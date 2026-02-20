//
//  CrimsonHomeView.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI
import SDWebImageSwiftUI

struct CrimsonHomeView: View {
    @Environment(\.props) var props
    var viewModel: CrimsonViewModel

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 60)
            } else if let error = viewModel.loadError {
                VStack(spacing: 12) {
                    Text(error)
                        .font(.crimsonBody)
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)

                    Button("Retry") {
                        viewModel.loadHomepage()
                    }
                    .font(.georgia(16, weight: .bold))
                    .foregroundStyle(Color.crimson)
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.sections) { section in
                        sectionView(section)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, props.safeAreaBottom + 30)
            }
        }
        .background(Color.pageBackground)
        .edgesIgnoringSafeArea(.bottom)
        .refreshable {
            await viewModel.fetchHomepage()
        }
    }

    // MARK: - Section View

    @ViewBuilder
    private func sectionView(_ section: CrimsonSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: 6) {
                Rectangle()
                    .fill(Color.crimson)
                    .frame(width: 4, height: 20)

                Text(section.title)
                    .font(.system(size: 14, weight: .heavy))
                    .kerning(1.2)
                    .foregroundStyle(Color.crimson)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 10)

            // Articles in this section
            ForEach(section.articles) { article in
                articleCard(article)
                    .onTapGesture {
                        if let idx = viewModel.articles.firstIndex(where: { $0.slug == article.slug }) {
                            viewModel.articleSelected(idx)
                        }
                    }
            }
        }
    }

    // MARK: - Article Card

    private func articleCard(_ article: CrimsonArticle) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.georgia(18, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(3)

                    if !article.authors.isEmpty {
                        Text(article.authors.map(\.name).joined(separator: ", "))
                            .font(.crimsonCaption)
                            .foregroundStyle(Color.secondaryText)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let url = article.previewImageURL {
                    WebImage(url: url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Divider()
                .padding(.top, 10)
                .padding(.bottom, 6)

            HStack {
                if let dateString = article.dateString {
                    Text(dateString)
                        .foregroundStyle(Color.secondaryText)
                }
                Spacer()
            }
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .foregroundStyle(Color.cardBackground)
                .shadow(color: Color.primary.opacity(0.08), radius: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}
