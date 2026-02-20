//
//  CrimsonArticleView.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI

struct CrimsonArticleView: View {
    @Environment(\.props) var props
    var viewModel: CrimsonViewModel

    var body: some View {
        ModelPages(viewModel.articles, currentPage: Binding(
            get: { viewModel.articleIndex },
            set: { viewModel.articleIndex = $0 }
        )) { articleIndex, article in
            ScrollView {
                VStack(spacing: 16) {
                    // Title
                    Text(article.title)
                        .font(.crimsonTitle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)

                    // Authors
                    if !article.authors.isEmpty {
                        Text("By " + article.authors.map(\.name).joined(separator: ", "))
                            .font(.georgia(16, weight: .semibold))
                            .foregroundStyle(Color.secondaryText)
                    }

                    // Date
                    if let dateString = article.dateString {
                        Text(dateString)
                            .font(.crimsonCaption)
                            .foregroundStyle(Color.secondaryText)
                    }

                    if article.isFullyLoaded {
                        // Article content
                        Divider()
                            .padding(.vertical, 4)

                        ForEach(article.content) { contentItem in
                            contentItem.toView(props: props)
                        }
                    } else {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.crimson)
                            Text("Loading article...")
                                .font(.crimsonBody)
                                .foregroundStyle(Color.secondaryText)
                        }
                        .padding(.top, 40)
                    }
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, props.safeAreaBottom + 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.pageBackground)
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                viewModel.articleAppeared(articleIndex)
            }
        }
    }
}
