//
//  QTShareCardView.swift
//  Presentation
//
//  Created by 이승주 on 1/28/26.
//

import SwiftUI
import Domain

/// 이미지 공유 프리뷰 및 바텀시트
public struct QTShareCardView: View {
    let qt: QuietTime
    let onShare: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: Image?

    public init(
        qt: QuietTime,
        onShare: @escaping () -> Void
    ) {
        self.qt = qt
        self.onShare = onShare
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 핸들 바
            RoundedRectangle(cornerRadius: 3)
                .fill(DS.Color.textSecondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // 이미지 프리뷰 (9:16 비율로 화면 최대한 꽉 채우기)
            if let renderedImage {
                renderedImage
                    .resizable()
                    .aspectRatio(9/16, contentMode: .fit)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            } else {
                // 로딩 중
                RoundedRectangle(cornerRadius: 12)
                    .fill(DS.Color.background)
                    .aspectRatio(9/16, contentMode: .fit)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }

            // 공유하기 버튼 (작고 중앙 정렬)
            Button {
                Haptics.tap()
                onShare()
            } label: {
                Text("공유하기")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(DS.Color.textPrimary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            .padding(.bottom, 20)
            .disabled(renderedImage == nil)
            .opacity(renderedImage == nil ? 0.6 : 1)

            Spacer()
        }
        .background(DS.Color.canvas)
        .task {
            await renderImage()
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: qt.date)
    }

    @MainActor
    private func renderImage() async {
        let shareCard = QTShareCard(qt: qt)

        // iOS 16+ ImageRenderer 사용
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: shareCard)
            renderer.scale = UIScreen.main.scale

            if let uiImage = renderer.uiImage {
                renderedImage = Image(uiImage: uiImage)
            }
        }
    }
}
