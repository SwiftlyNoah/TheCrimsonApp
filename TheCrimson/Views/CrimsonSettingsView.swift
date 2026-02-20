//
//  CrimsonSettingsView.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI

struct CrimsonSettingsView: View {
    @Environment(\.props) var props
    var viewModel: CrimsonViewModel

    var body: some View {
        VStack(spacing: 20) {
            // Dark mode toggle
            HStack {
                Text(viewModel.darkTheme ? "Dark Theme" : "Light Theme")
                    .font(.georgia(18, weight: .bold))

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        viewModel.darkTheme.toggle()
                    }
                }) {
                    Image(systemName: viewModel.darkTheme ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.crimson)
                }
            }

            // Animation toggle
            HStack {
                Text("Startup Animation: \(viewModel.showFullAnimation ? "On" : "Off")")
                    .font(.georgia(18, weight: .bold))

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        viewModel.showFullAnimation.toggle()
                    }
                }) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.crimson)
                }
            }

            Divider()

            // About section
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(.georgia(18, weight: .bold))

                Text("The Harvard Crimson is the daily student newspaper of Harvard University. This app presents articles from thecrimson.com in a reader-friendly format.")
                    .font(.crimsonBody)
                    .foregroundStyle(Color.secondaryText)

                Text("\(viewModel.articles.count) articles loaded")
                    .font(.crimsonCaption)
                    .foregroundStyle(Color.secondaryText)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Text("Made by Noah Brauner")
                .font(.georgia(14, weight: .bold))
                .foregroundStyle(Color.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .foregroundStyle(Color.cardBackground)
                .shadow(color: Color.primary.opacity(0.08), radius: 4)
        )
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, props.safeAreaBottom + 10)
        .background(Color.pageBackground)
    }
}
