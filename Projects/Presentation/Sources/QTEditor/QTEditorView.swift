//
//  QTEditorView.swift
//  Presentation
//
//  Created by 이승주 on 10/4/25.
//

import SwiftUI
import Domain

public struct QTEditorView: View {
    public let draft: QuietTime
    public init(draft: QuietTime) { self.draft = draft }

    @State private var memo: String = ""

    public var body: some View {
        Form {
            Section(draft.verse.id) {
                Text(draft.verse.text).font(.body)
            }
            Section("묵상 메모") {
                TextEditor(text: $memo).frame(minHeight: 160)
            }
        }
        .navigationTitle("QT 작성")
        .navigationBarTitleDisplayMode(.inline)
    }
}
