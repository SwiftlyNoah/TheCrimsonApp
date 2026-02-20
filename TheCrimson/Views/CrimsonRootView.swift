//
//  CrimsonRootView.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI

struct CrimsonRootView: View {
    @Environment(\.props) var props

    @State var viewModel = CrimsonViewModel()
    @State var animationFinished = false
    @State var revealUI = false

    var body: some View {
        ZStack {
            Color.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    Button(action: { viewModel.back() }) {
                        CrimsonHeaderView(
                            showFullAnimation: viewModel.showFullAnimation,
                            animationFinished: $animationFinished
                        )
                        .frame(height: animationFinished ? 36 : nil)
                        .frame(maxWidth: animationFinished ? nil : .infinity, alignment: .center)
                        .foregroundStyle(.primary)
                        .disabled(!animationFinished)
                    }

                    if animationFinished {
                        navigationBar
                            .opacity(revealUI ? 1 : 0)
                            .animation(.easeIn(duration: 0.4), value: revealUI)
                            .padding(.horizontal)
                    }
                }

                // Content
                if animationFinished {
                    ZStack {
                        CrimsonHomeView(viewModel: viewModel)
                            .opacity(viewModel.viewState == .home ? 1 : 0)
                            .zIndex(0)

                        if viewModel.viewState == .article {
                            CrimsonArticleView(viewModel: viewModel)
                                .transition(.move(edge: .trailing))
                                .zIndex(1)
                        }

                        if viewModel.viewState == .search {
                            CrimsonSearchView(viewModel: viewModel)
                                .transition(.opacity)
                                .zIndex(2)
                        }

                        if viewModel.viewState == .settings {
                            CrimsonSettingsView(viewModel: viewModel)
                                .transition(.opacity)
                                .zIndex(2)
                        }
                    }
                    .opacity(revealUI ? 1 : 0)
                    .animation(.easeIn(duration: 0.4), value: revealUI)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .preferredColorScheme(viewModel.darkTheme ? .dark : .light)
        .edgesIgnoringSafeArea(.bottom)
        .onChange(of: animationFinished) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                revealUI = true
                if viewModel.isFirstOpen {
                    viewModel.isFirstOpen = false
                    viewModel.showFullAnimation = false
                }
            }
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 6) {
            // Back button
            Button(action: viewModel.back) {
                Image(systemName: "arrowshape.turn.up.backward.fill")
                    .font(.system(size: 16, weight: .bold))
            }
            .disabled(!viewModel.showBackButton)
            .opacity(viewModel.showBackButton ? 1 : 0)

            Spacer()

            // Paginator (article view only)
            HStack(spacing: 2) {
                Button(action: {
                    viewModel.articleIndex -= 1
                }) {
                    Image(systemName: "arrowtriangle.left.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                .opacity(viewModel.articleIndex == 0 ? 0.4 : 1)
                .disabled(viewModel.articleIndex == 0)

                Text("\(viewModel.articleIndex + 1) of \(viewModel.articleCountString)")
                    .font(.georgia(16, weight: .bold))
                    .kerning(0.8)

                Button(action: {
                    viewModel.articleIndex += 1
                }) {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                .opacity(viewModel.articleIndex == viewModel.articles.count - 1 ? 0.4 : 1)
                .disabled(viewModel.articleIndex == viewModel.articles.count - 1)
            }
            .disabled(!viewModel.showPaginator)
            .opacity(viewModel.showPaginator ? 1 : 0)

            Spacer()

            // Search & Settings
            HStack(spacing: 16) {
                Button(action: viewModel.showSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .bold))
                }

                Button(action: viewModel.showSettings) {
                    Image(systemName: viewModel.viewState == .settings ? "xmark" : "gearshape.fill")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .opacity(viewModel.viewState == .article ? 0 : 1)
            .disabled(viewModel.viewState == .article)
        }
        .foregroundStyle(.primary)
        .frame(height: 30)
    }
}
