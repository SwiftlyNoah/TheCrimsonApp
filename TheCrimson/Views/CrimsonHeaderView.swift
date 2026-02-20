//
//  CrimsonHeaderView.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI

struct CrimsonHeaderView: View {
    @Environment(\.props) var props

    let showFullAnimation: Bool
    @Binding var animationFinished: Bool

    @State private var showCrimson = false
    @State private var showTheHarvard = false
    @State private var complete = false

    var body: some View {
        let scale = min(1, props.width / 500)
        Group {
            if showFullAnimation && !complete {
                VStack(spacing: 2) {
                    if showTheHarvard {
                        Text("The Harvard")
                            .font(.georgia(22 * scale))
                            .tracking(4)
                            .opacity(showTheHarvard ? 1 : 0)
                            .animation(.easeIn(duration: 0.5), value: showTheHarvard)
                    }

                    Text("CRIMSON")
                        .font(.georgia(65 * scale, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(Color.crimson)
                        .scaleEffect(showCrimson ? 1 : 1.5)
                        .opacity(showCrimson ? 1 : 0)
                        .animation(.interpolatingSpring(stiffness: 200, damping: 18), value: showCrimson)
                }
                .scaleEffect(animationFinished ? 0.55 : 1)
                .onAppear {
                    runAnimation()
                }
            } else {
                VStack(spacing: 0) {
                    Text("The Harvard")
                        .font(.georgia(22 * scale))
                        .tracking(4)

                    Text("CRIMSON")
                        .font(.georgia(65 * scale, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(Color.crimson)
                }
                .scaleEffect(animationFinished ? 0.55 : 1)
                .onAppear {
                    skipAnimation()
                }
            }
        }
    }

    private func runAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showCrimson = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showTheHarvard = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                animationFinished = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.9) {
            complete = true
        }
    }

    private func skipAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                animationFinished = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            complete = true
        }
    }
}
