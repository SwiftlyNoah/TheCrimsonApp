//
//  ModelPages.swift
//  Pages
//
//  Created by Nacho Navarro on 01/11/2019.
//  Copyright © 2019 nachonavarro. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import SwiftUI
import UIKit

/// A paging view that generates pages dynamically based on some user-defined data.
public struct ModelPages<Data, Content>: View where Data: RandomAccessCollection, Content: View {

    @Binding var currentPage: Int
    var items: [Data.Element]

    private var template: (Int, Data.Element) -> Content

    public init(
        _ items: Data,
        currentPage: Binding<Int>,
        template: @escaping (Int, Data.Element) -> Content
    ) {
        self._currentPage = currentPage
        self.items = items.map { $0 }
        self.template = template
    }

    public var body: some View {
        PageViewController(
            currentPage: $currentPage,
            controllers: (0..<items.count).map { i in
                let h = UIHostingController(rootView: template(i, items[i]))
                h.view.backgroundColor = .clear
                return h
            }
        )
    }
}

struct PageViewController: UIViewControllerRepresentable {

    @Binding var currentPage: Int

    var controllers: [UIViewController]

    func makeCoordinator() -> PagesCoordinator {
        PagesCoordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        pageViewController.view.backgroundColor = .clear

        for view in pageViewController.view.subviews {
            if let scrollView = view as? UIScrollView {
                scrollView.delegate = context.coordinator
                break
            }
        }

        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        let previousPage = context.coordinator.parent.currentPage
        context.coordinator.parent = self

        pageViewController.setViewControllers(
            [controllers[currentPage]],
            direction: currentPage - previousPage > 0 ? .forward : .reverse,
            animated: false
        )
    }
}

class PagesCoordinator: NSObject, UIPageViewControllerDataSource,
                             UIPageViewControllerDelegate {
    var parent: PageViewController

    init(_ pageViewController: PageViewController) {
        self.parent = pageViewController
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = parent.controllers.firstIndex(of: viewController) else {
            return nil
        }
        return index == 0 ? nil : parent.controllers[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = parent.controllers.firstIndex(of: viewController) else {
            return nil
        }
        return index == parent.controllers.count - 1 ? nil : parent.controllers[index + 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if completed,
        let visibleViewController = pageViewController.viewControllers?.first,
        let index = parent.controllers.firstIndex(of: visibleViewController) {
            parent.currentPage = index
        }
    }
}

extension PagesCoordinator: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewDidScroll(scrollView)
    }
}
