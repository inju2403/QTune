//
//  RootNav.swift
//  Presentation
//
//  Created by 이승주 on 10/4/25.
//

import SwiftUI
import Domain

// Simple navigation coordinator that wraps content with NavigationStack
public struct RootNavigationView<Content: View>: View {
    @State private var path = NavigationPath()
    let content: (Binding<NavigationPath>) -> Content
    let editorViewModelFactory: () -> QTEditorViewModel

    public init(
        editorViewModelFactory: @escaping () -> QTEditorViewModel,
        @ViewBuilder content: @escaping (Binding<NavigationPath>) -> Content
    ) {
        self.editorViewModelFactory = editorViewModelFactory
        self.content = content
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Full screen background covering entire device screen including notch/status bar
                Color(.systemBackground)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea(.all, edges: .all)

                // Navigation Stack
                NavigationStack(path: $path) {
                    content($path)
                        .background(Color(.systemBackground))
                        .navigationDestination(for: QuietTime.self) { qt in
                            QTEditorView(
                                draft: qt,
                                viewModel: editorViewModelFactory()
                            )
                            .background(Color(.systemBackground))
                        }
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea(.all))
    }
}

