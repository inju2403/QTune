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
    public init(draft: QuietTime) {
        self.draft = draft
        // 사용자 메모는 빈 문자열로 시작 (draft.memo는 rationale용)
        _userMemo = State(initialValue: "")
    }

    @State private var userMemo: String = ""
    @State private var showSaveAlert = false
    @Environment(\.dismiss) private var dismiss

    // draft.memo를 rationale로 사용
    private var rationale: String {
        draft.memo
    }

    public var body: some View {
        Form {
            // 말씀 섹션
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(draft.verse.id)
                        .font(.headline)
                        .foregroundColor(.blue)

                    Text(draft.verse.text)
                        .font(.body)
                        .padding(.vertical, 8)
                }
            } header: {
                Text("오늘의 말씀")
            }

            // 추천 이유 섹션 (있는 경우)
            if !rationale.isEmpty {
                Section {
                    Text(rationale)
                        .font(.body)
                        .foregroundColor(.secondary)
                } header: {
                    Text("추천 이유")
                }
            }

            // 나의 기록 섹션
            Section {
                TextEditor(text: $userMemo)
                    .frame(minHeight: 200)
            } header: {
                Text("나의 기록")
            } footer: {
                Text("오늘 말씀을 묵상하며 떠오른 생각이나 감사한 일, 기도 제목 등을 자유롭게 기록해보세요.")
                    .font(.caption)
            }

            // 저장 버튼
            Section {
                Button(action: {
                    showSaveAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("저장하기")
                            .bold()
                        Spacer()
                    }
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("QT 작성")
        .navigationBarTitleDisplayMode(.inline)
        .alert("준비 중", isPresented: $showSaveAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("저장 기능은 다음 단계에서 연결 예정입니다.\n지금은 입력한 내용을 확인하고 뒤로 가기를 눌러주세요.")
        }
    }
}
