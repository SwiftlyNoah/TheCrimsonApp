//
//  CrimsonSearchView.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI

struct CrimsonSearchView: View {
    @Environment(\.props) var props
    var viewModel: CrimsonViewModel

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.secondaryText)

                TextField("Search articles...", text: Binding(
                    get: { viewModel.searchQuery },
                    set: { newValue in
                        viewModel.searchQuery = newValue
                        viewModel.performSearch()
                    }
                ))
                .font(.crimsonBody)
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                        viewModel.searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.secondaryText)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .foregroundStyle(Color.cardBackground)
            )
            .padding(.horizontal)
            .padding(.top, 10)

            // Results
            if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.secondaryText)
                    Text("No articles found")
                        .font(.crimsonBody)
                        .foregroundStyle(Color.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { article in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(article.title)
                                    .font(.georgia(16, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)

                                if let dateString = article.dateString {
                                    Text(dateString)
                                        .font(.crimsonCaption)
                                        .foregroundStyle(Color.secondaryText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .onTapGesture {
                                viewModel.searchResultSelected(article)
                            }

                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                    .padding(.bottom, props.safeAreaBottom + 30)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.pageBackground)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            isSearchFocused = true
        }
    }
}
