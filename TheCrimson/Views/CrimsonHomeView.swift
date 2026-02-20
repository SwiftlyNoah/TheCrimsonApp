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
            LazyVStack(spacing: 16) {
                ForEach(viewModel.articles.indices, id: \.self) { articleIdx in
                    let article = viewModel.articles[articleIdx]
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
                    .onTapGesture {
                        viewModel.articleSelected(articleIdx)
                    }
                    .onAppear {
                        viewModel.homeArticleAppeared(articleIdx)
                    }
                }

                if viewModel.isPaginating {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, props.safeAreaBottom + 30)
        }
        .background(Color.pageBackground)
        .edgesIgnoringSafeArea(.bottom)
    }
}
