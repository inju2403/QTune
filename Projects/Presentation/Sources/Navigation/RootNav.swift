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
    @Binding var path: NavigationPath
    let content: (Binding<NavigationPath>, @escaping () -> Void) -> Content
    let onNavigateToRecordTab: () -> Void

    public init(
        path: Binding<NavigationPath>,
        onNavigateToRecordTab: @escaping () -> Void,
        @ViewBuilder content: @escaping (Binding<NavigationPath>, @escaping () -> Void) -> Content
    ) {
        self._path = path
        self.onNavigateToRecordTab = onNavigateToRecordTab
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
                    content($path, onNavigateToRecordTab)
                        .background(Color(.systemBackground))
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea(.all))
    }
}

